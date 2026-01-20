;
; Clock_I2C_2.asm
;
; Created: 31.12.2025 15:49:52
; Author : ar_user
;Обмен по I2C с DS3231, с прерыванием INT0 от секундных импульсов DS3231

.include "m8def.inc"
.list
	
; =========== Константы  ===========
.equ F_CPU = 1000000

; SPI для 74HC595
.equ SPI_PORT    = PORTB
.equ SPI_DDR     = DDRB		; направление 1 -выход, 0 -вход
.equ SPI_PIN     = PINB		; информация только читается
.equ SCK         = PB5     ; CLOCK
.equ MISO        = PB4     ; не используется
.equ DATA        = PB3     ; DATA (SER)
.equ LATCH       = PB2     ; LATCH (CS)
.equ OE          = PB1     ; ШИМ для яркости (Output Enable, активный низкий)
.equ MR          = PB0	   ; reset для регистров 74HC595


; Кнопки на PD7-PD4 с внешней подтяжкой
.equ BTN_PORT    = PORTD
.equ BTN_DDR     = DDRD
.equ BTN_PIN     = PIND
.equ BTN_MASK    = 0xF0    ; PD7-PD4
.equ BTN1        = PD7
.equ BTN2        = PD6
.equ BTN3        = PD5
.equ BTN4        = PD4

; DS3231 (на INT0)
.equ DS3231_INT   = PD2     ; INT0

; I2C для DS3231
.equ SDA          = PC4
.equ SCL          = PC5

; Сегменты цифр
.equ SEG_0 = 0b00111111
.equ SEG_1 = 0b00110000
.equ SEG_2 = 0b01101101
.equ SEG_3 = 0b01111001
.equ SEG_4 = 0b01110010
.equ SEG_5 = 0b01011011
.equ SEG_6 = 0b01011111
.equ SEG_7 = 0b00110001
.equ SEG_8 = 0b01111111
.equ SEG_9 = 0b01111011
.equ SEG_OFF = 0b00000000
.equ SEG_DP = 0b10000000

; =========== Сегмент данных ===========
.dseg
.org SRAM_START

; Режимы дисплея
display_mode: .byte 1
.equ MODE_HM     = 0      ; Часы-минуты
.equ MODE_MS     = 1      ; Минуты-секунды
.equ MODE_DM     = 2      ; Число-месяц
.equ MODE_DAY    = 3      ; День недели
.equ MODE_YEAR   = 4      ; Год (2 последние цифры)
.equ MODE_COUNT  = 5

edit_mode:    .byte 1

/*; Флаги
flags:        .byte 1
.equ FLAG_UPDATE_DISP    = 0   ; нулевой бит*/

; Буферы
display_buf:  .byte 4

i2c_buffer:   .byte 7      ; Буфер для I2C (секунды, минуты, часы, день, дата, месяц, год)
.equ i2c_sec		= i2c_buffer     ; байт секунд в формате BCD 
.equ i2c_min		= i2c_buffer+1   ; байт минут в формате BCD
.equ i2c_hours		= i2c_buffer+2   ; байт часов в формате BCD 
.equ i2c_weekday	= i2c_buffer+3   ; байт дня недели в формате BCD 
.equ i2c_day		= i2c_buffer+4   ; байт дня месяца в формате BCD 
.equ i2c_month		= i2c_buffer+5   ; байт месяца в формате BCD 
.equ i2c_year		= i2c_buffer+6   ; байт года в формате BCD 

bin_time_buffer:	.byte 7      ; Буфер для времени в формате BIN (секунды, минуты, часы, день, дата, месяц, год)
.equ bin_sec		= bin_time_buffer     ; байт секунд в формате BIN
.equ bin_min		= bin_time_buffer+1   ; байт минут в формате BIN
.equ bin_hours		= bin_time_buffer+2   ; байт часов в формате BIN
.equ bin_weekday	= bin_time_buffer+3   ; байт дня недели в формате BIN
.equ bin_day		= bin_time_buffer+4   ; байт дня месяца в формате BIN
.equ bin_mouth		= bin_time_buffer+5   ; байт месяца в формате BIN
.equ bin_year		= bin_time_buffer+6   ; байт года в формате BIN
; =========== Сегмент кода ===========
.cseg
; =========== Векторы прерывания ===========
	.ORG 	0x0000			; Проц стартует с нуля, но дальше идут вектора 
	RJMP 	Reset			; прерываний, поэтому отсюда сразу же прыгаем на начало программы. На метку Reset
	.ORG	0x0001			; External Interrupt Request 0 = 0x0001
	RJMP 	INT0_DS3231		; Вектор INT0 (DS3231)
.org 0x0020

; =========== Таблицы ===========
SEG_TABLE:
    .db SEG_0, SEG_1, SEG_2, SEG_3, SEG_4, SEG_5, SEG_6, SEG_7, SEG_8, SEG_9

.def Flags = r23    ; R23 регистр флагов
.equ flag_time = 0       ; Бит 0: событие 1 секунда (от INT0)
.equ flag_disp = 1	     ; Бит 1: 
.equ flag_bnt   = 2      ; Бит 2: нажата кнопка (от Timer1)

Reset:
    ; Инициализация стека
    ldi r16, high(RAMEND)
    out SPH, r16
    ldi r16, low(RAMEND)
    out SPL, r16

	; Инициализация портов
    rcall INIT_PORTS

	; Инициализация переменных
	rcall INIT_VARIABLES

	; Инициализация прерываний
	rcall INIT_INTERRUPTS

	; Инициализация DS3231
	rcall INIT_DS3231
		
	;sbi SPI_PIN, PB0
	; Для теста
	;rcall WRITE_DATETIME
	;rcall WRITE_HOURS
	; Разрешение прерываний
	sei

MAIN_LOOP:
	
	; Обновление времени по флагу
    sbrs Flags, flag_time ;Пропустить следующую команду если бит в регистре стоит
    rjmp DISPLAY
	cbr Flags, (1<<flag_time) ; СРАЗУ сбрасываем флаг
	rcall READ_DATETIME

	; Обновление дисплея по флагу
DISPLAY:	
	sbrs Flags, flag_disp ;Пропустить следующую команду если бит в регистре стоит
    rjmp BUTTON
	cbr Flags, (1<<flag_disp) ; СРАЗУ сбрасываем флаг
	rcall UPDATE_DISPLAY

	; Обработка нажатой кнопки
BUTTON:
	sbrs Flags, flag_bnt ;Пропустить следующую команду если бит в регистре стоит
    rjmp SLEEP_ALL
	cbr Flags, (1<<flag_bnt) ; СРАЗУ сбрасываем флаг
	rcall ACTIV_BUTTON

SLEEP_ALL:	
	; Режим сна
	 sleep                 ; Перевести МК в режим энергосбережения
   
  	rjmp MAIN_LOOP

 ;=========== Прерывание от DS3231 (INT0) ===========
INT0_DS3231:
    push r16
    in r16, SREG
    push r16
	
	;sbi SPI_PIN, PB3
	;rcall READ_DATETIME

	; Установка флага считывания времени
	sbr Flags, (1<<flag_time)|(1<<flag_disp)
	
			
	pop r16
    out SREG, r16
    pop r16
	
    reti

; =========== Инициализация переменных ===========
INIT_VARIABLES:
    clr r16
	; Время
    sts bin_hours, r16
    sts bin_min, r16
    sts bin_sec, r16
    sts bin_day, r16
    sts bin_mouth, r16
    sts bin_year, r16
    sts bin_weekday, r16
    
    ; Режимы
    sts display_mode, r16
    sts edit_mode, r16

	; Флаги
    clr flags

    ; Для теста. Установка флага обновления дисплея
	;lds r16, flags
    ;sbr r16, (1<<FLAG_UPDATE_DISP) ; установка бита в 1
    ;sts flags, r16
	; Для теста установки времени
	ldi r16,0x33
	rcall BCD_TO_BIN
	sts bin_sec, r16
	ldi r16,0x22
	rcall BCD_TO_BIN
	sts bin_min, r16
	ldi r16,0x11
	rcall BCD_TO_BIN
	sts bin_hours, r16
      

    ret

; =========== Инициализация портов ===========
INIT_PORTS:
    ; SPI порты (MOSI, SCK, SS, OE, MR как выходы)
    ldi r16, (1<<DATA)|(1<<SCK)|(1<<LATCH)|(1<<OE)|(1<<MR)
    out SPI_DDR, r16
    
    ; OE (яркость) - низкий уровень по умолчанию (максимальная яркость)
    cbi SPI_PORT, OE
	; MR (reset регистров 74HC595) - низкий уровень по умолчанию
	cbi SPI_PORT, MR
     
	    
    ; Порт для DS3231 (INT0)
    cbi DDRD, DS3231_INT      ; Вход
    sbi PORTD, DS3231_INT     ; Подтяжка
    
    ; Порты для I2C
    cbi DDRC, SDA             ; SDA - вход
    cbi DDRC, SCL             ; SCL - вход
    sbi PORTC, SDA            ; Подтяжка
    sbi PORTC, SCL            ; Подтяжка
    
    ret


; =========== Инициализация прерываний ===========
INIT_INTERRUPTS:
    ; INT0 - От DS3231 восходящий фронт генерирует запрос прерывания
    ldi r16, (1<<ISC01)|(1<<ISC00)
    out MCUCR, r16
    ldi r16, (1<<INT0)
    out GICR, r16
    
    ret


; =========== Инициализация DS3231 ===========
INIT_DS3231:
    rcall I2C_INIT
    
    rcall I2C_START
    ldi r16, 0xD0		;адрес DS3231
    rcall I2C_WRITE
    
    ldi r16, 0x0E		; адресс Control Register (0Eh) DS3231 
    rcall I2C_WRITE
    
    ldi r16, 0x00		; запись в Control Register (0Eh) DS3231 Установка SQW на 1 Гц
    rcall I2C_WRITE
    
    rcall I2C_STOP

    ret

UPDATE_DISPLAY:
	sbi SPI_PIN, PB0
	ret

ACTIV_BUTTON:
	sbi SPI_PIN, PB1
	ret

;============== Чтение времени из DS3231 ==================================

READ_DATETIME:
    push r16
	        
    ;rcall I2C_INIT
    
    rcall I2C_START
    ; Адрес DS3231 для записи
    ldi r16, 0xD0
    rcall I2C_WRITE
    
    ; Регистр 0x00 (секунды)
    ldi r16, 0x00
    rcall I2C_WRITE
    
	rcall I2C_START
    ; Повторный START для чтения
    ldi r16, 0xD1
    rcall I2C_WRITE
		
	rcall I2C_READ_ACK
	in r16, TWDR
	sts i2c_sec,r16
	
	rcall I2C_READ_ACK
	in r16, TWDR
	sts i2c_min,r16
	
	rcall I2C_READ_NACK
	in r16, TWDR
	sts i2c_hours,r16
		
	rcall I2C_STOP
	
	pop r16
   ret

; =========== Запись времени в DS3231 ===========
WRITE_DATETIME:
    push r16
    
    ;rcall I2C_INIT
    
	rcall I2C_START
    ldi r16, 0xD0
    rcall I2C_WRITE
    
    ldi r16, 0x00
    rcall I2C_WRITE
    
    lds r16, bin_sec
    rcall BIN_TO_BCD
    rcall I2C_WRITE
    
    lds r16, bin_min
    rcall BIN_TO_BCD
    rcall I2C_WRITE
    
    lds r16, bin_hours
    rcall BIN_TO_BCD
    rcall I2C_WRITE
    
    rcall I2C_STOP

    pop r16
    ret

; =========== Запись часов в DS3231 ===========
WRITE_HOURS:
    push r16
    
    ;rcall I2C_INIT
    
	rcall I2C_START
    ldi r16, 0xD0
    rcall I2C_WRITE
    
    ldi r16, 0x02	; адрес регистра часов
    rcall I2C_WRITE
    
    lds r16, bin_hours
    rcall BIN_TO_BCD
    rcall I2C_WRITE
    
    rcall I2C_STOP

    pop r16
    ret

; =========== I2C процедуры ===========
I2C_INIT:
    ldi r16, 11
    out TWBR, r16 ; TWI Bit Rate Register  коэффициент деления для генератора скорости передачи данных
    ldi r16, (0<<TWPS1)|(0<<TWPS0) ; биты предварительного делителя в регистр TWSR (PrescalerValue = 1)
    out TWSR, r16
    ret

	; TWINT  устанавливается аппаратно, когда TWI завершил свою текущую работу и ожидает ответа 
	; TWEN разрешает работу TWI и активирует интерфейс TWI
	; TWSTA генерирует условие START
I2C_START:
    ldi r16, (1<<TWINT)|(1<<TWEN)|(1<<TWSTA)
    out TWCR, r16

I2C_WAIT:
    in r16, TWCR
    sbrs r16, TWINT ;  проверяет состояние 7 бита TWINT в регистре и, если этот бит установлен, пропускает следующую команду
    rjmp I2C_WAIT
    ret

I2C_WRITE:
    out TWDR, r16
    ldi r16, (1<<TWINT)|(1<<TWEN)
    out TWCR, r16
    rjmp I2C_WAIT

	; TWEA: TWI Enable Acknowledge Bit 
I2C_READ_ACK:
    ldi r16, (1<<TWINT)|(1<<TWEN)|(1<<TWEA)
    out TWCR, r16
    rjmp I2C_WAIT

I2C_READ_NACK:
    ldi r16, (1<<TWINT)|(1<<TWEN)
    out TWCR, r16
    rjmp I2C_WAIT

	; TWSTO: TWI STOP Condition Bit 
I2C_STOP:
    ldi r16, (1<<TWINT)|(1<<TWEN)|(1<<TWSTO)
    out TWCR, r16
    ret
;================ Вывод на дисплей =======================

/*UPDATE_DISPLAY_FLAG:
    push r16
    
    ; Сброс флага
    lds r16, flags
    cbr r16, (1<<FLAG_UPDATE_DISP) ; установка бита в 0
    sts flags, r16
    
    rcall UPDATE_DISPLAY
    
    pop r16
    ret

UPDATE_DISPLAY:

sbi SPI_PIN, PB1

ret*/


; =========== BCD в BIN ===========
BCD_TO_BIN:
	; Вход: r16
    push r17
    push r18
    mov  r17, r16       ; Копируем BCD
    andi r17, 0x0F      ; R17 = Единицы (младшая тетрада)
    swap r16            ; Меняем тетрады местами
    andi r16, 0x0F      ; R16 = Десятки (бывшая старшая тетрада)
    
    ; Умножение на 10: (X * 8) + (X * 2)
    mov  r18, r16       ; R18 = X
    lsl  r16            ; X * 2
    lsl  r16            ; X * 4
    lsl  r16            ; X * 8
    add  r16, r18       ; + X = X * 9
    add  r16, r18       ; + X = X * 10
    
    add  r16, r17       ; Прибавляем единицы
    pop  r18
    pop  r17
    ret

; =========== BIN в BCD ===========
BIN_TO_BCD:
	; Вход: r16
    push r17
    ldi  r17, 0         ; Счетчик десятков
BIN_loop:
    cpi  r16, 10        ; Сравниваем с 10
    brlo BIN_done       ; Если меньше 10, выходим
    subi r16, 10        ; Вычитаем 10
    inc  r17            ; Увеличиваем счетчик десятков
    rjmp BIN_loop
BIN_done:
    swap r17            ; Перемещаем десятки в старшую тетраду
    or   r16, r17       ; Объединяем с единицами (BCD упакованный)
    pop  r17
    ret

.exit