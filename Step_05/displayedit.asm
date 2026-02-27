/*
 * displayedit.asm
 *
 *  Created: 04.02.2026 13:29:19
 *   Author: ar_user
 */ 


 DISPLAY_EDIT:
	push r16
	push r17
	push r18
	push r30
	push r31

	lds r16, edit_mode
	cpi R16, 8          ; Проверяем, что индекс меньше 8
    brsh Error2     ; Если R16 >= 8, уходим на обработку ошибки
	mov r18,r16
	rcall DIGIT_TO_SEGMENT    ; преобразуем цифру в код сегментов
	sts display_1, r18     ;  Сохраняем в буфер для левого (первого) индикатора
	rjmp DE1
Error2:
	clr r18					; обнуляем "мусор" переводим на режим по дефолту
	sts edit_mode, r18
	rjmp OUT_UD2
DE1:
	rcall Disp_2 ; анимация 2-ого идикатора
	;rjmp UPDATE_DISPLAY_2

	;Находим нужный байт времени
	ldi  XL, low(i2c_buffer)
    ldi  XH, high(i2c_buffer)
    dec  r16                ;делаю декримент для правильной работы мне надо чтобы индекс edit_mode начинался с нуля Делаем из 1..7 -> 0..6
    add  XL, r16
    clr  r16
    adc  XH, r16

    ld   r17, X             ; Загружаем в r17 значение нужного байта по адресу Х

	mov r18, r17
    swap r18
    andi r18, 0x0F        ; Десятки
	rcall DIGIT_TO_SEGMENT    ; преобразуем цифру в код сегментов
	sts display_3, r18     ;  Сохраняем в буфер для третьего индикатора
	    
    ; Индикатор 4: единицы
    mov r18, r17
    andi r18, 0x0F        ; Единицы
    rcall DIGIT_TO_SEGMENT ; преобразуем цифру в код сегментов
	sts display_4, r18

	rjmp UPDATE_DISPLAY_2


; анимация 2-ого идикатора
disp_2:

	sbrc rflags, rflag_dot ; проверяет состояние одного бита в регистре и пропускает следующую команду если этот бит очищен
	rjmp holo
	ldi  r18,seg_lo
	sbr rFlags, (1<<rFlag_dot)
	rjmp loho
holo:
	ldi  r18,seg_ho
	cbr rFlags, (1<<rFlag_dot)
loho:	
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