;
; Step_03.asm
;
; Created: 17.02.2026 21:36:00
; Author : ar_user
;

.include "m8def.inc"
.list
.include "define.inc"	; Наши все определения переменных тут

.cseg
; =========== Векторы прерывания ===========
.include "vectors.inc"

.org 0x0020

; =========== Таблицы ===========
SEG_TABLE:
    .db SEG_0, SEG_1, SEG_2, SEG_3, SEG_4, SEG_5, SEG_6, SEG_7, SEG_8, SEG_9

TABLDISP:
rjmp SHOW_HM      ; Индекс 0
rjmp SHOW_MS      ; Индекс 1
rjmp SHOW_DM      ; Индекс 2
rjmp SHOW_DAY     ; Индекс 3
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
	 
	inc r3 ; смотрю ресеты

	; Разрешение прерываний
	sei



MAIN_LOOP:
	; 1. Событие INT0 (RTC секунда прошла)
    sbrc rFlags, rFlag_int0 ; Пропустить следующую команду если бит в регистре очищен
	rcall SELECT_DISP
	
SLEEP_ALL:	
	; Режим сна
	 sleep                 ; Перевести МК в режим энергосбережения

	rjmp MAIN_LOOP

.include "initialization.asm"

SELECT_DISP:
	sbrc rFlags, rFlag_TimeOut ; Пропустить следующую команду если бит в регистре очищен
	rcall TimeOut
	cbr rFlags, (1<<rFlag_int0) ; сброс флага
	;rcall TEST_A
	;проверка на режим редактирования
	lds r19, edit_mode
    tst r19
    breq DiWo       ; Переход если равно т.е.если 0 — работаем как обычно
	rcall DISPLAY_EDIT	;переход в показ режима редактирования
	rcall TEST_C
	rjmp OUT_SeDi
DiWo:
	rcall DISPLAY_WORK ;переход в показ времени
OUT_SeDi:
	ret

TimeOut:
	; --- Логика таймаута ---
    lds r19, timeout_cnt
    dec r19             ; Уменьшаем каждую секунду
    sts timeout_cnt, r19
    brne Out_TO  ; Если еще не ноль, продолжаем (Проверяется флаг нулевого значения (Z) регистра статуса, сдесь реагирует на dec r19)

    clr r16             ; Если ноль — сброс режима
	cbr rFlags, (1<<rFlag_TimeOut) ; сброс флага
    sts edit_mode, r16	
	sts display_mode, r16

Out_TO:
 ret

/* DISPLAY_EDIT:
 rcall TEST_A
 ret*/

TEST_A:
	;cbr rFlags, (1<<rFlag_int0)
	;rcall READ_DATETIME
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

; Делаю пятисекундное изменение режима дисплея от 0 до 4
TEST_B:
	push r19
	lds r19, timeout_cnt
    dec r19             ; Уменьшаем каждую секунду
    sts timeout_cnt, r19
    brne Out_TB2  ; Если еще не ноль, продолжаем 
	ldi r19,5		;вот они 5 секунд
	sts timeout_cnt, r19
	lds r19, display_mode
	inc r19
	cpi r19,5	;5 это уже перебор
    brsh Out_TB1    ; Если R19 >= 5
	sts display_mode, r19
	rjmp Out_TB2
Out_TB1:
	cbr rFlags, (1<<rFlag_dot) ; сброс флага
	clr r19
	sts display_mode, r19	
Out_TB2:
	pop r19
ret

; Делаю пятисекундное изменение режима редактирования от 1 до 7
TEST_C:
	push r19
	lds r19, timeout_cnt
    dec r19             ; Уменьшаем каждую секунду
    sts timeout_cnt, r19
    brne Out_TC2  ; Если еще не ноль, продолжаем 
	ldi r19,5		;вот они 5 секунд
	sts timeout_cnt, r19
	lds r19, edit_mode
	inc r19
	cpi r19,8	;8 это уже перебор
    brsh Out_TC1    ; Если R19 >= 5
	sts edit_mode, r19
	rjmp Out_TB2
Out_TC1:
	;cbr rFlags, (1<<rFlag_dot) ; сброс флага
	rcall READ_DATETIME_FULL
	ldi r19,1
	sts edit_mode, r19	
Out_TC2:
	pop r19
ret

.include "displaywork.asm"
.include "displayedit.asm"
.include "i2c.asm"	
.include "spi.asm"
 ;=========== Прерывание от DS3231 (INT0) ===========
INT0_ISR:

    in r5, SREG
    push r16
	
	sbr rFlags, (1<<rFlag_int0) ; устанавливаем флаг
   	
	pop r16
    out SREG, r5
	
    reti



	.exit