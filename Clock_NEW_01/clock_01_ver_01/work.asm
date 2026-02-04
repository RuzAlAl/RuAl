/*
 * work.asm
 *
 *  Created: 01.02.2026 17:10:05
 *   Author: ar_user
 */ 


 PROCESS_DISPLAY_RTC:
	/*push r16
    in r16, SREG
    push r16*/

	lds r16, edit_mode
    tst r16
    breq NORMAL_VIEW       ; Переход если равно Если 0 — работаем как обычно

;здесь код для редактирования

	NORMAL_VIEW:
	cbr rFlags, (1<<rFlag_int0)
	;rjmp READ_DATETIME
    lds r16, display_mode
	cpi R16, 5          ; Проверяем, что индекс меньше 5
    brsh Show_Error     ; Если R16 >= 5, уходим на обработку ошибки
    ; Загружаем базовый адрес таблицы
    ldi  ZL, low(TABLDISP) 
    ldi  ZH, high(TABLDISP)

    ; Прибавляем индекс к адресу (Z = Z + r16)
    add  ZL, r16
    clr  r17
    adc  ZH, r17              ; Учитываем перенос

    ijmp                      ; ПРЫЖОК по адресу в Z


	; --- Обработчики ---
SHOW_HM:
    lds  r16, i2c_hours
    lds  r17, i2c_min
    rjmp Buffer_disp

SHOW_MS:
    lds  r16, i2c_min
    lds  r17, i2c_sec
    rjmp Buffer_disp

SHOW_DAY:
	lds  r16, i2c_min
    lds  r17, i2c_sec
    rjmp Buffer_disp

SHOW_DM:
	lds  r16, i2c_min
    lds  r17, i2c_sec
    rjmp Buffer_disp

SHOW_YEAR:
	lds  r16, i2c_min
    lds  r17, i2c_sec
    rjmp Buffer_disp

Show_Error:
	ldi r16, 0				; переводим на режим по дефолту
	sts display_mode, r16
	rjmp NORMAL_VIEW

OUT_A:
	/*pop r16
    out SREG, r16
    pop r16*/
	ret


