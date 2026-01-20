;
; button_ver_02.asm
;
; Created: 14.01.2026 23:13:47
; Author : ar_user
;
.include "m8def.inc"
.list
.include "define.inc"	; Наши все определения переменных тут

.cseg
; =========== Векторы прерывания ===========
	.ORG 	0x0000			; Проц стартует с нуля, но дальше идут вектора 
	RJMP 	Reset			; прерываний, поэтому отсюда сразу же прыгаем на начало программы. На метку Reset
	/*.ORG	0x0001			; External Interrupt Request 0 = 0x0001
	RJMP 	INT0_DS3231		; Вектор INT0 (DS3231)*/
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

		
	; Разрешение прерываний
	sei
MAIN_LOOP:
	rcall Button_Check
		
	; Обработка нажатой кнопки
BUTTON:
	sbrs rFlags, flag_bnt ;Пропустить следующую команду если бит в регистре стоит
    rjmp SLEEP_ALL		;убрал на время проверки NEED_RECORD_TIME
	cbr rFlags, (1<<flag_bnt) ; СРАЗУ сбрасываем флаг
	rcall ACTIV_BUTTON

	
SLEEP_ALL:	
	; Режим сна
	 sleep                 ; Перевести МК в режим энергосбережения
   
  	rjmp MAIN_LOOP

 

; =========== Инициализация переменных ===========
INIT_VARIABLES:
	clr r1 ; R1: Всегда 0x00 (ускоряет очистку регистров и портов)
    clr rbtn_now
	clr rbtn_stat

		; Флаги
     clr rflags
	 
	 ; Нужно 3 стабильных считывания (30 мс)
	 ldi r16, 3
	 mov rDebounce, r16

	 ldi r16, 0xF0
	 mov rbtn_last, r16		; Считаем, что изначально кнопки отпущены (т.е. входы подтянуты внешними резисторами)
	 ret

; =========== Инициализация портов ===========
INIT_PORTS:

	; Порты подключенных кнопок как входы, без подтяжки (внешние резисторы на 5в)
    ldi r16, (0<<BTN1)|(0<<BTN2)|(0<<BTN3)|(0<<BTN4); BTN1 это PD7, BTN2 это PD6, BTN3 это PD5, BTN4 это PD4
    out BTN_DDR, r16
    
    ret


; =========== Инициализация прерываний ===========

;===================================================
/*UPDATE_DISPLAY:
	sbi SPI_PIN, PB0

	

	ret*/

ACTIV_BUTTON:
;	ldi debounce,3		; Нужно 3 стабильных считывания (30 мс) для следующей обработки
	sbi SPI_PIN, PB1

	/*lds r16, flag_wr_time
	sbr r16, (1<<wr_time)
	sts flag_wr_time, r16*/
ret

Button_Check:
	in r0, SREG         ; Быстро сохраняем статус в R0 (1 такт)
    push r16
    
	/*; 1. Перезапуск таймера (Т0 требует ручной дозагрузки)
    ldi r16, 246
    out TCNT0, r16*/

	; 2. Чтение кнопок
    in rbtn_now, PIND  ; Считываем весь порт D
    andi rbtn_now, 0xF0 ; Оставляем только PD4-PD7

	/*; 3. Проверка: все ли кнопки отпущены?
    cpi rBtn_now, 0xF0
    breq Buttons_Off    ; Если 0xF0 (все в 1), значит ничего не нажато*/

	; 4. Антидребезг
    cp rBtn_now, rBtn_last ; Сравниваем с предыдущим опросом
    breq State_Stable		; Если состояние не изменилось, идем к счетчику

   ; Состояние изменилось (дребезг или смена кнопки)
    mov rBtn_last, rBtn_now
    ldi r16, 3
    mov rDebounce, r16   ; Сброс счетчика  (3 * 10мс = 30мс)
    rjmp End_ISR

	    

State_Stable:
	cpse rDebounce, r1   ; Сравниваем счетчик с нулем (R1 у нас всегда 0)
    dec rDebounce        ; Если не 0, уменьшаем
    
    ; Если счетчик только что стал 0 (после dec), фиксируем нажатие
    brne End_ISR         ; Если всё еще не 0, выходим

	; --- Здесь debounce стал равен 0 ---
    ; --- Кнопка стабильна 30 мс ---
    ; Здесь мы не просто ставим флаг, а можем передать само состояние кнопок
    ; По условию - ставим флаг для Main
    sbr rFlags, (1 << flag_bnt)
    ; Можно сохранить rBtn_now в спец. регистр, чтобы Main знал, КАКАЯ кнопка
    mov rBtn_stat, rBtn_now      ; Сохраняем "образ" нажатых кнопок в R4
    rjmp End_ISR

Buttons_Off:
    ; Если кнопки отпущены, сбрасываем состояние и останавливаем таймер
    mov rBtn_Last, rBtn_now ; Запишем 0xF0
    clr rDebounce
    
    /*ldi r16, 0
    out TCCR0, r16       ; ВЫКЛЮЧАЕМ ТАЙМЕР 0 (экономим такты МК)

    ldi r16, (1<<INTF1)
    out GIFR, r16        ; Чистим флаг INT1 (дребезг при отпускании)
    
    in r16, GICR
    ori r16, (1<<INT1)
    out GICR, r16        ; Снова включаем ожидание нажатия (INT1)*/


End_ISR:
    pop r16
    out SREG, r0
    ;reti


	ret