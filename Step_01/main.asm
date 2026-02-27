;
; Step_01.asm
;
; Created: 16.02.2026 12:36:58
; Author : ar_user
;

.include "m8def.inc"
.list
.include "define.inc"	; Наши все определения переменных тут

.cseg
; =========== Векторы прерывания ===========
	;.include "vectors.inc"
	.ORG 	0x0000			; Проц стартует с нуля, но дальше идут вектора 
	RJMP 	Reset			; прерываний, поэтому отсюда сразу же прыгаем на начало программы. На метку Reset
	.ORG	0x0001			; External Interrupt Request 0 = 0x0001
	RJMP 	INT0_ISR		; Вектор INT0 (DS3231)
.org 0x0020

; =========== Таблицы ===========
SEG_TABLE:
    .db SEG_0, SEG_1, SEG_2, SEG_3, SEG_4, SEG_5, SEG_6, SEG_7, SEG_8, SEG_9

/*TABLDISP:
rjmp SHOW_HM      ; Индекс 0
rjmp SHOW_MS      ; Индекс 1
rjmp SHOW_DM      ; Индекс 2
rjmp SHOW_DAY     ; Индекс 3
rjmp SHOW_YEAR    ; Индекс 4*/

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
	;rcall INIT_SPI
	 
	inc r3 ; смотрю ресеты

	; Разрешение прерываний
	sei



MAIN_LOOP:
	; 1. Событие INT0 (RTC секунда прошла)
    sbrc rFlags, rFlag_int0 ; Пропустить следующую команду если бит в регистре очищен
	;rcall DISPLAY_WORK
	;rcall TEST_A
	;rcall READ_DATETIME
	;sbrc rFlags, rFlag_blink 
	rcall TEST_A
	nop
SLEEP_ALL:	
	; Режим сна
	 ;sleep                 ; Перевести МК в режим энергосбережения

	rjmp MAIN_LOOP

.include "initialization.asm"

	
	;.include "displaywork.asm"


TEST_A:
	cbr rFlags, (1<<rFlag_int0)
	rcall READ_DATETIME
	in  r16, PORTB
	ldi r17,(1<<PB7)
	eor r16, r17  ; Исключающее ИЛИ: если был 0 — станет 1, если 1 — станет 0
	out PORTB,r16
	/*in  r16, PORTB
	andi r16,0b10000000 ; Оставляем только 7 бит
	cpi r16,0b10000000
	BRNE VVV			;Перейти если не равно
	cbi PORTB, PB7
	rjmp Out_Te
VVV:
	sbi PORTB, PB7*/
out_te:
ret	

.include "i2c.asm"	

 ;=========== Прерывание от DS3231 (INT0) ===========
INT0_ISR:

    in r5, SREG
    push r16
	/*push r16
    in r16, SREG
    push r16*/

	sbr rFlags, (1<<rFlag_int0) ; устанавливаем флаг
    ldi r16, (1<<rFlag_blink)
    eor rFlags, r16        ; Инвертируем бит мигания rFlag_blink (для F_BLINK)
	
	
	/*pop r16
    out SREG, r16
    pop r16*/
	pop r16
    out SREG, r5
	
    reti

;.include "spi.asm"

	.exit