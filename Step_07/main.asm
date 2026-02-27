;
; Step_03.asm
;
; Created: 20.02.2026 13:30:00
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

TABLSHORT:
	rjmp MINUS		    ; Индекс 0
	rjmp PLUS	        ; Индекс 1
	rjmp CHANGE_ED      ; Индекс 2
	rjmp CHANGE_MO      ; Индекс 3

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
	; 1. Событие INT0 (RTC секунда прошла)
    sbrc rFlags, rFlag_int0 ; Пропустить следующую команду если бит в регистре очищен
	rcall SELECT_DISP

	; 2. Кнопки
	sbrc rFlags, rFlag_short ; Пропустить следующую команду если бит в регистре очищен
	rcall Press_Short
	
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
	lds r18, edit_mode
    tst r18
    breq DiWo       ; Переход если равно т.е.если 0 — работаем как обычно
	rcall DISPLAY_EDIT	;переход в показ режима редактирования
	;rcall TEST_C
	rjmp OUT_SeDi
DiWo:
	rcall DISPLAY_WORK ;переход в показ времени
OUT_SeDi:
	ret

TimeOut:
	push r16
	push r18
	; --- Логика таймаута ---
    lds r18, timeout_cnt
    dec r18             ; Уменьшаем каждую секунду
    sts timeout_cnt, r18
    brne Out_TO  ; Если еще не ноль, продолжаем (Проверяется флаг нулевого значения (Z) регистра статуса, сдесь реагирует на dec r19)

    clr r16             ; Если ноль — сброс режима
	cbr rFlags, (1<<rFlag_TimeOut) ; сброс флага
    sts edit_mode, r16	
	sts display_mode, r16

Out_TO:
	pop r18
	pop r16
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

INT1_ISR:
	in r6, SREG
    push r16

	; ВЫКЛЮЧИТЬ INT1, чтобы не частил (сбросить бит INT1, сохранив INT0)
	/*in  r16, GICR			; Читаем текущее состояние прерываний
	andi r16, ~(1<<INT1)	; Сбрасываем только бит INT1 (это способ создать маску для инвертирования нужного бита в регистре микроконтроллера)
	out GICR, r16			; Выключаем INT1*/

	in r16, GICR
    cbr r16, (1<<INT1)
    out GICR, r16

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

	
	; Чистим флаг INT1 (дребезг при отпускании)
	; 1. Сначала сбрасываем флаг INT1 (записью единицы!)
    ldi r16, (1<<INTF1)
    out GIFR, r16    ; Запись '1' в флаг прерывания очищает его    
    
	; 2. Теперь безопасно включаем INT1
    in r16, GICR
    ori r16, (1<<INT1)
    out GICR, r16        ; Снова включаем ожидание нажатия (INT1)

	pop r16
    out SREG, r6

	.include "button.asm"

	.exit