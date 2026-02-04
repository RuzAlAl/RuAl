/*
 * displayedit.asm
 *
 *  Created: 04.02.2026 13:29:19
 *   Author: ar_user
 */ 

ED_SEC:
	ldi  r18,SEG_1
	sts display_1, r18
	rcall Disp_2 ; анимация 2-ого идикатора

    lds  r17, i2c_sec
	mov r18, r17
    swap r18
    andi r18, 0x0F        ; Десятки
	rcall DIGIT_TO_SEGMENT    ; преобразуем цифру в код сегментов
	sts display_3, r18     ;  Сохраняем в буфер для левого (первого) индикатора
	    
    ; Индикатор 4: единицы
    mov r18, r17
    andi r18, 0x0F        ; Единицы
    rcall DIGIT_TO_SEGMENT ; преобразуем цифру в код сегментов
	sts display_4, r18
    rjmp UPDATE_DISPLAY_2

ED_MIN:
	ldi  r18,SEG_2
	sts display_1, r18
	rcall Disp_2 ; анимация 2-ого идикатора

	lds  r17, i2c_min
	mov r18, r17
    swap r18
    andi r18, 0x0F        ; Десятки
	rcall DIGIT_TO_SEGMENT    ; преобразуем цифру в код сегментов
	sts display_3, r18     ;  Сохраняем в буфер для индикатора
	   
    ; Индикатор 4: единицы
    mov r18, r17
    andi r18, 0x0F        ; Единицы
    rcall DIGIT_TO_SEGMENT ; преобразуем цифру в код сегментов
	sts display_4, r18
    rjmp UPDATE_DISPLAY_2

ED_HOURS:
	ldi  r18,SEG_3
	sts display_1, r18
	rcall Disp_2 ; анимация 2-ого идикатора

	lds  r17, i2c_hours
	mov r18, r17
    swap r18
    andi r18, 0x0F        ; Десятки
	rcall DIGIT_TO_SEGMENT    ; преобразуем цифру в код сегментов
	sts display_3, r18     ;  Сохраняем в буфер для индикатора
	    
    ; Индикатор 4: единицы
    mov r18, r17
    andi r18, 0x0F        ; Единицы
    rcall DIGIT_TO_SEGMENT ; преобразуем цифру в код сегментов
	sts display_4, r18
    rjmp UPDATE_DISPLAY_2

ED_WEEKDAY:
	ldi  r18,SEG_4
	sts display_1, r18
	rcall Disp_2 ; анимация 2-ого идикатора

	lds  r17, i2c_weekday
	mov r18, r17
    andi r18, 0x0F        ; дни (1-7)
    rcall DIGIT_TO_SEGMENT
    sts display_4, r18   ; Сохраняем в буфер для индикатора 
    rjmp UPDATE_DISPLAY_2

ED_DAY:
	ldi  r18,SEG_5
	sts display_1, r18
	rcall Disp_2 ; анимация 2-ого идикатора

	lds  r17, i2c_day
	mov r18, r17
    swap r18
    andi r18, 0x0F        ; Десятки
	rcall DIGIT_TO_SEGMENT    ; преобразуем цифру в код сегментов
	sts display_3, r18     ;  Сохраняем в буфер для индикатора
	    
    ; Индикатор 4: единицы
    mov r18, r17
    andi r18, 0x0F        ; Единицы
    rcall DIGIT_TO_SEGMENT ; преобразуем цифру в код сегментов
	sts display_4, r18
    rjmp UPDATE_DISPLAY_2

ED_MONTH:
	ldi  r18,SEG_6
	sts display_1, r18
	rcall Disp_2 ; анимация 2-ого идикатора

	lds  r17, i2c_month
	mov r18, r17
    swap r18
    andi r18, 0x0F        ; Десятки
	rcall DIGIT_TO_SEGMENT    ; преобразуем цифру в код сегментов
	sts display_3, r18     ;  Сохраняем в буфер для индикатора
	    
    ; Индикатор 4: единицы
    mov r18, r17
    andi r18, 0x0F        ; Единицы
    rcall DIGIT_TO_SEGMENT ; преобразуем цифру в код сегментов
	sts display_4, r18
    rjmp UPDATE_DISPLAY_2

ED_YEAR:
	ldi  r18,SEG_7
	sts display_1, r18
	rcall Disp_2 ; анимация 2-ого идикатора

	lds  r17, i2c_year
	mov r18, r17
    swap r18
    andi r18, 0x0F        ; Десятки
	rcall DIGIT_TO_SEGMENT    ; преобразуем цифру в код сегментов
	sts display_3, r18     ;  Сохраняем в буфер для индикатора
	    
    ; Индикатор 4: единицы
    mov r18, r17
    andi r18, 0x0F        ; Единицы часов (0-9)
    rcall DIGIT_TO_SEGMENT ; преобразуем цифру в код сегментов
	sts display_4, r18
    rjmp UPDATE_DISPLAY_2

 DISPLAY_EDIT:
	push r16
	push r17
	push r18
	push r30
	push r31

	lds r16, edit_mode
	cpi R16, 8          ; Проверяем, что индекс меньше 8
    brsh Error2     ; Если R16 >= 8, уходим на обработку ошибки
	dec r16 ; делаю декримент для правильной работы табличных переходов мне надо чтобы индекс edit_mode начинался с нуля Делаем из 1..7 -> 0..6
	ldi  ZL, low(TABLEDIT) 
    ldi  ZH, high(TABLEDIT)
    ; Прибавляем индекс к адресу (Z = Z + r16)
    add  ZL, r16
    clr  r17
    adc  ZH, r17              ; Учитываем перенос

    ijmp                      ; ПРЫЖОК в обработчики табличных переходов по адресу в Z 

Error2:
	clr r16					; обнуляем "мусор" переводим на режим по дефолту
	sts edit_mode, r16
	rjmp OUT_UD2

; анимация 2-ого идикатора
Disp_2:

	SBRS rFlags, rFlag_blink	 ;пропускает следующую команду если этот бит установлен
	rjmp HoLo
	ldi  r18,SEG_lo
	rjmp LoHo
HoLo:
	ldi  r18,SEG_ho
LoHo:	
	sts display_2, r18

	ret

	

UPDATE_DISPLAY_2:	 
	    
	lds r16,display_4
	rcall spi_send
	lds r16,display_3
	rcall spi_send
	lds r16,display_2
	rcall spi_send
	lds r16,display_1
	rcall spi_send

	    
    ; Защелкиваем данные (импульс на SS/CS)
	sbi SPI_PORT, LATCH
	nop
	cbi SPI_PORT, LATCH 
OUT_UD2:
	pop r31
	pop r30
	pop r18
	pop r17
	pop r16
	ret