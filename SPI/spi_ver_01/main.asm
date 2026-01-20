;
; i2c_ver_01.asm
;
; Created: 05.01.2026 17:19:26
; Author : ar_user
;
.include "m8def.inc"
.list
.include "define.inc"	; Наши все определения переменных тут

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

	;Запись времени для ТЕСТа
	;rcall WRITE_DATETIME

	; Инициализация SPI
	rcall INIT_SPI
	 
	; ДЛя теста записи времени
	lds r16, flag_wr_time	;считываем
	sbr r16, (1<<wr_hours)| (1<<wr_min)| (1<<wr_day)| (1<<wr_mouth)| (1<<wr_year)
	sts flag_wr_time, r16	; записываем

		
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
    rjmp NEED_RECORD_TIME
	cbr Flags, (1<<flag_bnt) ; СРАЗУ сбрасываем флаг
	rcall ACTIV_BUTTON

	;Необходимость записи времени
NEED_RECORD_TIME:
	lds r16, flag_wr_time	;считываем
	tst r16					; проверка на нулевое значение
	breq SLEEP_ALL			; если равно 0
	rcall WRITE_SPECIFIC_TIME

SLEEP_ALL:	
	; Режим сна
	 sleep                 ; Перевести МК в режим энергосбережения
   
  	rjmp MAIN_LOOP

 ;=========== Прерывание от DS3231 (INT0) ===========
INT0_DS3231:
    push r16
    in r16, SREG
    push r16
	
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
	;ldi r16, 0
    sts display_mode, r16
	;clr r16
    sts edit_mode, r16

	; Флаги
     clr flags
	 sts flag_dot, r16
	 sts flag_wr_time, r16

    ; Для теста установки времени
	ldi r16,0x33
	rcall BCD_TO_BIN
	sts bin_sec, r16
	ldi r16,0x36
	rcall BCD_TO_BIN
	sts bin_min, r16
	ldi r16,0x14
	rcall BCD_TO_BIN
	sts bin_hours, r16
	ldi r16,0x07
	rcall BCD_TO_BIN
	sts bin_weekday, r16
	ldi r16,0x07
	rcall BCD_TO_BIN
	sts bin_day, r16
	ldi r16,0x01
	rcall BCD_TO_BIN
	sts bin_mouth, r16
	ldi r16,0x26
	rcall BCD_TO_BIN
	sts bin_year, r16
      
    ret

; =========== Инициализация портов ===========
INIT_PORTS:
    
	; SPI порты (MOSI, SCK, SS, OE, MR как выходы)
    ldi r16, (1<<DATA)|(1<<SCK)|(1<<LATCH)|(1<<OE)|(1<<MR)
    out SPI_DDR, r16
    
    ; OE (яркость) - низкий уровень по умолчанию (максимальная яркость)
    cbi SPI_PORT, OE
	; MR (reset регистров 74HC595) - высокий уровень по умолчанию
	sbi SPI_PORT, MR
     
	    
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
;===================================================
/*UPDATE_DISPLAY:
	sbi SPI_PIN, PB0

	

	ret*/

ACTIV_BUTTON:
	sbi SPI_PIN, PB1

	/*lds r16, flag_wr_time
	sbr r16, (1<<wr_time)
	sts flag_wr_time, r16*/

.include "i2c.asm"
.include "spi_1.asm"
	ret
