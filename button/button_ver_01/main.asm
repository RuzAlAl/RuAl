;
; button_ver_01.asm
;
; Created: 12.01.2026 22:05:47
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
	sbrs Flags, flag_bnt ;Пропустить следующую команду если бит в регистре стоит
    rjmp SLEEP_ALL		;убрал на время проверки NEED_RECORD_TIME
	cbr Flags, (1<<flag_bnt) ; СРАЗУ сбрасываем флаг
	rcall ACTIV_BUTTON

	
SLEEP_ALL:	
	; Режим сна
	 sleep                 ; Перевести МК в режим энергосбережения
   
  	rjmp MAIN_LOOP

 

; =========== Инициализация переменных ===========
INIT_VARIABLES:
    clr r16
	clr btn_now
	clr btn_stat
		; Флаги
     clr flags
	 
	 ldi debounce,3		; Нужно 3 стабильных считывания (30 мс)
	 ldi btn_last, 0xF0		; Считаем, что изначально кнопки отпущены (т.е. входы подтянуты внешними резисторами)
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
	ldi debounce,3		; Нужно 3 стабильных считывания (30 мс) для следующей обработки
	sbi SPI_PIN, PB1

	/*lds r16, flag_wr_time
	sbr r16, (1<<wr_time)
	sts flag_wr_time, r16*/
ret

Button_Check:
    push r16
    in r16, SREG
    push r16

    in btn_now, PIND  ; Считываем весь порт D
    andi btn_now, 0xF0 ; Оставляем только PD4-PD7

    cp btn_now, btn_last ; Сравниваем с предыдущим опросом
    breq State_Stable    ; Если состояние не изменилось, идем к счетчику

    ; Состояние изменилось (дребезг или новое нажатие)
    mov btn_last, btn_now ; Запоминаем новое состояние
    ldi debounce, 3       ; Сбрасываем счетчик (3 * 10мс = 30мс)
    rjmp End_ISR

State_Stable:
    tst debounce          ; Проверяем, не обнулился ли счетчик уже
    breq End_ISR          ; Если 0, то кнопка уже обработана как стабильная
    
    dec debounce          ; Уменьшаем счетчик
    brne End_ISR          ; Если еще не 0, выходим

    ; --- Здесь debounce стал равен 0 ---
    ; Состояние стабильно 30 мс. Записываем в итоговый регистр
    mov btn_stat, btn_now 
    
    ; Логика: если (btn_stat & (1<<PD4)) == 0, значит кнопка нажата
    ; Здесь можно установить флаг для основного цикла
	sbr Flags, (1<<flag_bnt) ;  устанавливаю флаг
End_ISR:
    pop r16
    out SREG, r16
    pop r16
    ;reti


	ret