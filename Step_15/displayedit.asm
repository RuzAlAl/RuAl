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
	;cpi R16, 8          ; Проверяем, что индекс меньше 8
	cpi R16, 9          ; Проверяем, что индекс меньше 9
    brsh Error2     ; Если R16 >= 8, уходим на обработку ошибки
	cpi R16, 8		; Проверяем, что индекс равен 8
	breq Cryst		;Перейти если равно
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
	/*ldi r18,0b01001001
	sts display_2, r18*/
	ret

Cryst:
	rcall Crystall
	


	/*rjmp UPDATE_DISPLAY_2
ret*/

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

Crystall:
	push r16
	push r17
	push r18
	push r19
	push r20
	sbrs rFlags, rFlag_Reg10h ; Пропустить следующую команду если бит в регистре в 1
	rcall READ_REGISTER_10H
	lds r16, i2c_crystal
	; Преобразование знакового байта в модуль и разряды
	; Вход: r16 = исходное значение
	; Выход: r17 = 0 если положительное, 1 если отрицательное
	; r18 = сотни (0-1), r19 = десятки (0-9), r20 = единицы (0-9)
	clr   r17               ; предполагаем положительное
	; Проверяем знак
    sbrs  r16, 7            ; пропустить, если бит 7 сброшен (положительное)
    rjmp  conv_pos
    ; Отрицательное: преобразуем в положительное (инвертировать +1)
    com   r16                ; инвертируем все биты
    inc   r16                ; +1
    ldi   r17, 1             ; признак отрицательного
conv_pos:
	; Теперь в r16 модуль числа (0..127)
    ; Разбиваем на сотни, десятки, единицы
    ; Для 0..127: сотни = 0 или 1
    ldi   r18, 0
    ldi   r19, 0
    ldi   r20, 0

	; Вычитаем сотни (100)
    cpi   r16, 100
    brlo  conv_no100
    subi  r16, 100
    ldi   r18, 1	;сотни
conv_no100:
	; Теперь десятки (0..9)
    ldi   r21, 0            ; счётчик десятков
conv_dec_loop:
    cpi   r16, 10
    brlo  conv_dec_done
    subi  r16, 10
    inc   r21
    rjmp  conv_dec_loop
conv_dec_done:
	mov   r19, r21		;десятки
    mov   r20, r16          ; остаток = единицы

	rcall DIGIT_TO_SEGMENT    ; преобразуем цифру в код сегментов
	;ori r18, (1<<7) ; устанавливаем 7 бит (это точка) без изменения остальных
	sts display_2, r18
	mov r18,r19
	rcall DIGIT_TO_SEGMENT    ; преобразуем цифру в код сегментов
	;ori r18, (1<<7) ; устанавливаем 7 бит (это точка) без изменения остальных
	sts display_3, r18
	mov r18,r20
	rcall DIGIT_TO_SEGMENT    ; преобразуем цифру в код сегментов
	;ori r18, (1<<7) ; устанавливаем 7 бит (это точка) без изменения остальных
	sts display_4, r18

	cpi   r17, 1
	breq negativ		;переход если равно, подставляем знак минус
	ldi r17, SEG_OFF
	rjmp DISP_1
NEGATIV:
	ldi r17, 0b01000000 ; Знак минус
DISP_1:
	sts display_1, r17

	pop r20
	pop r19
	pop r18
	pop r17
	pop r16
ret