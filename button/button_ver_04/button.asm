/*
 * button.asm
 *
 *  Created: 20.01.2026 20:48:56
 *   Author: ar_user
 */ 
 TIMER0_ISR:
	sbi PORTB, 0        ; ПОДНЯТЬ PB0 (Начало импульса)  для осцилла

	in r0, SREG         ; Быстро сохраняем статус в R0 (1 такт)
    push r16

 ;DETERMINING_PRESSED_BUTTON:
	; 1. Перезапуск таймера (Т0 требует ручной дозагрузки)
    ;ldi r16, 246
	ldi r16, 236
    out TCNT0, r16

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
    ;rjmp End_ISR
	; !!! НОВОЕ УСЛОВИЕ: ОСТАНОВИТЬ ТАЙМЕР ЗДЕСЬ !!!
    ;rjmp StopTimer0_AfterPress  

;Buttons_Off:
    ; сбрасываем состояние и останавливаем таймер
	ldi rBtn_now, 0xF0
    mov rBtn_Last, rBtn_now ; Запишем 0xF0
    clr rDebounce
    
    ldi r16, 0
    out TCCR0, r16       ; ВЫКЛЮЧАЕМ ТАЙМЕР 0 (экономим такты МК)

	; Чистим флаг INT1 (дребезг при отпускании)
	; 1. Сначала сбрасываем флаг INT1 (записью единицы!)
    ldi r16, (1<<INTF1)
    out GIFR, r16    ; Запись '1' в флаг прерывания очищает его    
    
	; 2. Теперь безопасно включаем INT1
    in r16, GICR
    ori r16, (1<<INT1)
    out GICR, r16        ; Снова включаем ожидание нажатия (INT1)

End_ISR:
	
    pop r16
    out SREG, r0

	cbi PORTB, 0        ; ОПУСТИТЬ PB0 (Конец импульса) для осцилла
    
	reti
 
 /*StopTimer0_AfterPress:
    ; Если мы здесь, значит стабильное нажатие зафиксировано, таймер больше не нужен.
    ; Логика выхода такая же, как в Buttons_Off, но без ожидания отпускания 
    ; и без включения INT1 (это произойдет, когда кнопка отпустится)
    
    clr rDebounce
    ldi r16, 0
    out TCCR0, r16      ; ВЫКЛЮЧАЕМ ТАЙМЕР 0

    ; Здесь мы не трогаем INT1/GIFR, т.к. физическая кнопка еще нажата.
    
	pop r16
    out SREG, r0

    ;cbi PORTB, 0        ; ОПУСТИТЬ PB0 для осцилла

    reti                ; Выход из прерывания*/


 ACTIV_BUTTON:

	; КН1 (бит 4) - переключение режимов отображения
    ;sbrc rBtn_stat, 4
	sbrs rBtn_stat, 4
    rcall BUTTON_1
    
    ; КН2 (бит 5) - выбор разряда/вход в редактирование
    ;sbrc rBtn_stat, 5
	sbrs rBtn_stat, 5
    rcall BUTTON_2
    
    ; КН3 (бит 6) - увеличение значения/яркости
    ;sbrc rBtn_stat, 6
	sbrs rBtn_stat, 6
    rcall BUTTON_3
    
    ; КН4 (бит 7) - уменьшение значения/яркости
    ;sbrc rBtn_stat, 7
	sbrs rBtn_stat, 7
    rcall BUTTON_4
;	ldi debounce,3		; Нужно 3 стабильных считывания (30 мс) для следующей обработки
	;sbi PINB, PB2
	;com rBtn_stat
	;out PORTB, rBtn_stat
	;clr rBtn_stat
	/*lds r16, flag_wr_time
	sbr r16, (1<<wr_time)
	sts flag_wr_time, r16*/
	ldi r16, 0xF0 
	mov rBtn_stat,r16
ret

Button_1:
	in r16, PORTB      ; Считать текущее состояние PORTB в регистр r16
    ldi r17, (1<<PB2)  ; Загрузить маску (00000100) в r17
    eor r16, r17       ; Исключающее ИЛИ: если был 0 — станет 1, если 1 — станет 0
    out PORTB, r16     ; Записать измененное значение обратно в PORTB
	/*ldi r23, 0xF0
	mov rbtn_stat, r23*/
	ret
Button_2:
	in r16, PORTB      ; Считать текущее состояние PORTB в регистр r16
    ldi r17, (1<<PB3)  ; Загрузить маску (00001000) в r17
    eor r16, r17       ; Исключающее ИЛИ: если был 0 — станет 1, если 1 — станет 0
    out PORTB, r16     ; Записать измененное значение обратно в PORTB
	inc r8
	ret
Button_3:
	in r16, PORTB      ; Считать текущее состояние PORTB в регистр r16
    ldi r17, (1<<PB4)  ; Загрузить маску (00010000) в r17
    eor r16, r17       ; Исключающее ИЛИ: если был 0 — станет 1, если 1 — станет 0
    out PORTB, r16     ; Записать измененное значение обратно в PORTB
	ret
Button_4:
	in r16, PORTB      ; Считать текущее состояние PORTB в регистр r16
    ldi r17, (1<<PB5)  ; Загрузить маску (00100000) в r17
    eor r16, r17       ; Исключающее ИЛИ: если был 0 — станет 1, если 1 — станет 0
    out PORTB, r16     ; Записать измененное значение обратно в PORTB
	ret