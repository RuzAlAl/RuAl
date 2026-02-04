;
; clock_01_ver_01.asm
;
; Created: 01.02.2026 17:19:26
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
	RJMP 	INT0_ISR		; Вектор INT0 (DS3231)
	.ORG	0x0002			; External Interrupt Request 1 = 0x0001
	RJMP 	INT1_ISR		; Вектор INT1
	.ORG	0x0009			; Timer/Counter0 Overflow
	;RJMP 	TIMER0_ISR		; Вектор  TIMER0 OVF
.org 0x0020

; =========== Таблицы ===========
SEG_TABLE:
    .db SEG_0, SEG_1, SEG_2, SEG_3, SEG_4, SEG_5, SEG_6, SEG_7, SEG_8, SEG_9

TABLDISP:
rjmp SHOW_HM      ; Индекс 0
rjmp SHOW_MS      ; Индекс 1
rjmp SHOW_DAY     ; Индекс 2
rjmp SHOW_DM      ; Индекс 3
rjmp SHOW_YEAR    ; Индекс 4



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

	; Инициализация SPI
	rcall INIT_SPI
	 
	
	; Разрешение прерываний
	sei

MAIN_LOOP:
	;sbr rFlags, (1<<rFlag_int0)
	; 1. Событие INT0 (RTC секунда прошла)
    sbrc rFlags, rFlag_int0 ; Пропустить следующую команду если бит в регистре очищен
    rcall PROCESS_DISPLAY_RTC

    ; 2. Событие от Кнопок
    sbrc rFlags, rFlag_bnt
    ;rcall PROCESS_BUTTONS
	

SLEEP_ALL:	
	; Режим сна
	 sleep                 ; Перевести МК в режим энергосбережения

	rjmp MAIN_LOOP

 .include "work.asm"

 
 ;=========== Прерывание от DS3231 (INT0) ===========
INT0_ISR:
    push r16
    in r16, SREG
    push r16

	sbr rFlags, (1<<rFlag_int0)
    ldi r16, 0b00000100
    eor rFlags, r16        ; Инвертируем бит мигания rFlag_blink (для F_BLINK)
	
	
	pop r16
    out SREG, r16
    pop r16
	
    reti

;==================== Прерывание от кнопок (INT1) ===============================

INT1_ISR:
	push r16             ; Сохраняем рабочий регистр
	in r16, SREG         ; Сохраняем статус
	push r16

	; ВЫКЛЮЧИТЬ INT1, чтобы не частил (сбросить бит INT1, сохранив INT0)
	in  r16, GICR			; Читаем текущее состояние прерываний
	andi r16, ~(1<<INT1)	; Сбрасываем только бит INT1 (это способ создать маску для инвертирования нужного бита в регистре микроконтроллера)
	out GICR, r16			; Выключаем INT1

	; Запуск Таймера 0
	/*; Устанавливаем предделитель (для 10мс)
	Частота МК: 1 000 000 Гц.
	Максимальный предделитель: 1024.
	Частота таймера: 1000000/1024=976,5 Гц.
	Период одного тика: =1,024 мс.
	Количество тиков для 10 мс: 10/1,024=9,76.
	10 мс — это почти ровно 10 тиков таймера при предделителе 1024.
	Это дает погрешность около 2.4% (реально будет 10.24 мс), что для кнопок абсолютно не критично.
	Чтобы таймер срабатывал каждые 10 тиков, мы будем использовать прерывание по переполнению (OVF) и при каждом входе догружать в счетчик значение, чтобы он быстрее добегал до 256.
 	Расчет: 256-10=246  (0xF6).*/
	;ldi r16, 246        ; Заряжаем на 10 тиков до переполнения
	ldi r16, 246
    out TCNT0, r16
    ldi r16, (1<<CS02)|(0<<CS01)|(1<<CS00) ; Предделитель 1024 (Запуск)
    out TCCR0, r16

	pop r16
	out SREG, r16        ; Восстанавливаем статус
	pop r16

	reti

; =========== Инициализация переменных ===========
INIT_VARIABLES:
	clr r1 ; R1: Всегда 0x00 (ускоряет очистку регистров и портов)
    clr r16
	
	; Флаги
     clr rflags
	     
    ; Режимы
	sts edit_mode, r16
	ldi r16, 2
	sts display_mode, r16
	

	; Нужно 3 стабильных считывания (30 мс)
	 ldi r16, 3
	 mov rDebounce, r16

	 ldi r16, 0xF0
	 mov rbtn_last, r16		; Считаем, что изначально кнопки отпущены (т.е. входы подтянуты внешними резисторами)
	 mov rbtn_now, r16
	 mov rbtn_stat, r16

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

	; Порты подключенных кнопок как входы и PD3 для INT1, без подтяжки (внешние резисторы на 5в)
    ldi r16, (0<<BTN1)|(0<<BTN2)|(0<<BTN3)|(0<<BTN4)|(0<<BTN_INT); BTN1 это PD7, BTN2 это PD6, BTN3 это PD5, BTN4 это PD4, BTN_INT это PD3
    out BTN_DDR, r16
    
    ret


; =========== Инициализация прерываний ===========
INIT_INTERRUPTS:
    ; INT0 - От DS3231 восходящий фронт генерирует запрос прерывания
    ldi r16, (1<<ISC01)|(1<<ISC00)
    out MCUCR, r16
    ldi r16, (1<<INT0)
    out GICR, r16

	; INT1 - прерывание от кнопок по нажатию 
    ; (нажатие = 1->0 на INT1, отпускание = 0->1)
    ldi r16, (1<<ISC11)|(0<<ISC10)  ; нажатие = 1->0
    out MCUCR, r16
	; ВКЛЮЧИТЬ INT1 (установить бит INT1, сохранив INT0)
	in  r16, GICR        ; Читаем текущее состояние
	ori r16, (1<<INT1)   ; Устанавливаем только бит INT1 (Разрешение INT1)
	out GICR, r16        ; Записываем обратно, включаем INT1

	; Разрешаем прерывание по переполнению Таймера 0
    in r16, TIMSK
    ori r16, (1 << TOIE0)
    out TIMSK, r16
    
    ret


.include "i2c.asm"
.include "spi.asm"

;.include "button.asm"


	.exit
