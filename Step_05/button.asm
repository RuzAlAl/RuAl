/*
 * button.asm
 *
 *  Created: 09.02.2026 20:48:56
 *   Author: ar_user
 */ 
 TIMER0_ISR:
	sbi PORTB, PB0        ; ПОДНЯТЬ PB0 (Начало импульса)  для осцилла

	in r7, SREG         ; Быстро сохраняем статус в R7 (1 такт)
    push r16
	push r20
	
	; 1. Перезапуск таймера (Т0 требует ручной дозагрузки)
    ldi r16, 246
    out TCNT0, r16

	; 1. Читаем и инвертируем
    in   rBtn_now, BTN_PIN	; Считываем весь порт D
    com  rBtn_now			; Инвертируем (нажатая кнопка теперь "1")
    andi rBtn_now, BTN_MASK	; Оставляем только PD4-PD7 (BTN_MASK=0xF0)

    ; 2. Если ничего не нажато — сброс счетчика и выход (или выключение)
    tst  rBtn_now
    breq BTN_RESET_CNT		; Перейти если равно 0 — кнопка отпущена

    ; 3. Кнопка нажата — увеличиваем счетчик
    inc  rDebounce
	ldi r16, T_SHORT 
    cp  rDebounce, r16
    brlo TIM0_EXIT          ; Если еще не накопили 3 такта — просто выходим

    ; --- Кнопка подтверждена (нажата стабильно ~45-50 мс) ---
    sbr  rFlags, (1<<rFlag_short)
    
    ; Перевод в индекс (0-3)
    swap rBtn_now
    ldi  rBtn_Index, 0
FIND_IDX:
    sbrc rBtn_now, 3
    rjmp BTN_SAVE
    inc  rBtn_Index
    lsl  rBtn_now
    rjmp FIND_IDX

BTN_SAVE:
    sts  rBtn_Save, rBtn_Index
    ; Теперь выключаем таймер, чтобы не частил
    ;rjmp STOP_TIMER

BTN_RESET_CNT:
    clr  rDebounce
    ; Если кнопка пропала сразу (помеха), выключаем таймер
    ; Если хотим ловить длинные нажатия — логика меняется

STOP_TIMER:
    ldi  r16, 0
    out  TCCR0, r16 ; ВЫКЛЮЧАЕМ ТАЙМЕР 0 
    ; Чистим флаг INT1 (дребезг при отпускании)
	; 1. Сначала сбрасываем флаг INT1 (записью единицы!)
    ldi r16, (1<<INTF1)
    out GIFR, r16    ; Запись '1' в флаг прерывания очищает его    
    
	; 2. Теперь безопасно включаем INT1
    in r16, GICR
    ori r16, (1<<INT1)
    out GICR, r16        ; Снова включаем ожидание нажатия (INT1)

TIM0_EXIT:
   
	pop r20
    pop r16
    out SREG, r7

	cbi PORTB, PB0        ; ОПУСТИТЬ PB0 (Конец импульса) для осцилла
reti


Press_Short:
	push r16
	rcall Progra_Short
	cbr rFlags, (1<<rFlag_Short)
	sbr rFlags, (1<<rFlag_TimeOut) ; установка флага
	ldi r16,10		;вот они 5 секунд для TimeOut
	sts timeout_cnt, r16
	clr r16
	sts rBtn_Save, r16
	pop r16
	ret

 
 Progra_Short:
	lds r16, rBtn_Save
	;mov r16, rBtn_index
	; Используем табличный переход
	; Загружаем базовый адрес таблицы
    ldi  ZL, low(TABLSHORT) 
    ldi  ZH, high(TABLSHORT)
    ; Прибавляем индекс к адресу (Z = Z + r16)
    add  ZL, r16
    clr  r17
    adc  ZH, r17              ; Учитываем перенос

    ijmp                      ; ПРЫЖОК в обработчики табличных переходов по адресу в Z 

 ret


CHANGE_MO:
	lds r16, edit_mode
    tst r16
    breq MODE_NEXT		   ; Перейти если равно 0, т.е. мы не в режиме редактирования
    rcall SAVE_TO_RTC      ; Если были в редактировании времени - сохраняем
    ret
MODE_NEXT:
    lds r16, display_mode
    inc r16
    cpi r16, 6
    brlo MO_ST			; Перейти если меньше
    clr r16
MO_ST:
    sts display_mode, r16
 ret

CHANGE_ED:
	lds r16, edit_mode
    inc r16
    cpi r16, 8             ; 7 параметров + 1 выход
    brlo ED_ST
    clr r16
ED_ST:
    sts edit_mode, r16
	sts display_mode, r16
    
ret

PLUS:
	lds  r16, edit_mode
    tst  r16
    breq Pl_DONE           ; Если не в режиме настройки — Плюс ничего не делает
    rcall VALUE_UP         ; Вызываем наш универсальный инкремент через X
Pl_DONE:
    
ret

MINUS:
	lds  r16, edit_mode
    tst  r16
    breq Mi_DONE           ; Если не в режиме настройки — Плюс ничего не делает
    rcall VALUE_DOWN         ; Вызываем наш универсальный инкремент через X
Mi_DONE:
    
ret

 
 SAVE_TO_RTC:
	lds r16, edit_mode
	clr r16
	sts edit_mode, r16
	sts display_mode, r16
 ret

 VALUE_UP:
	
	inc r14
 ret

 VALUE_DOWN:
	
	dec r14
 ret