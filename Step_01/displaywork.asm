/*
 * displayrtc.asm
 *
 *  Created: 02.02.2026 16:20:48
 *   Author: ar_user
 */ 
 ; --- Обработчики табличных переходов ---
/*SHOW_HM:
    lds  r16, i2c_hours
    lds  r17, i2c_min
    rjmp Buffer_disp

SHOW_MS:
    lds  r16, i2c_min
    lds  r17, i2c_sec
    rjmp Buffer_disp

SHOW_DAY:
	;ldi  r16, 0x00
    ;lds  r17, i2c_weekday
    rjmp Buffer_disp

SHOW_DM:
	lds  r16, i2c_day
    lds  r17, i2c_month
    rjmp Buffer_disp

SHOW_YEAR:
	ldi  r16, 0x20
    lds  r17, i2c_year
    rjmp Buffer_disp*/


DISPLAY_WORK:
	push r16
	push r17
	push r18
	;push r30
	;push r31

NORMAL_VIEW:
	;cbr rFlags, (1<<rFlag_int0)
	;rcall RTC_ADAPTIVE
	rcall READ_DATETIME
	;cbr rFlags, (1<<rFlag_int0) 
    /*lds r16, display_mode
	cpi R16, 5          ; Проверяем, что индекс меньше 5
    brsh Error1     ; Если R16 >= 5, уходим на обработку ошибки

    ; Используем табличный переход
	; Загружаем базовый адрес таблицы
    ldi  ZL, low(TABLDISP) 
    ldi  ZH, high(TABLDISP)
    ; Прибавляем индекс к адресу (Z = Z + r16)
    add  ZL, r16
    clr  r17
    adc  ZH, r17              ; Учитываем перенос

    ijmp                      ; ПРЫЖОК в обработчики табличных переходов по адресу в Z 

Error1:
	clr r16					; обнуляем "мусор" переводим на режим по дефолту
	sts display_mode, r16
	rjmp NORMAL_VIEW*/
	lds  r16, i2c_hours
    lds  r17, i2c_min
	
Buffer_disp:
		
	/*; Переход для формирования дня недели
    lds r18, display_mode
	cpi r18, MODE_DAY
	BREQ MD3*/
	
			    
    ; Формируем 4 цифры:
    ; Индикатор 1 (левый): десятки часов
	mov r18, r16
    swap r18
    andi r18, 0x0F        ; Десятки часов (0-2)
	rcall DIGIT_TO_SEGMENT    ; преобразуем цифру в код сегментов
	sts display_1, r18     ;  Сохраняем в буфер для левого (первого) индикатора
	    
    ; Индикатор 2: единицы часов + точка
    mov r18, r16
    andi r18, 0x0F        ; Единицы часов (0-9)
    rcall DIGIT_TO_SEGMENT ; преобразуем цифру в код сегментов

    ; Добавляем мигающую точку (между часами и минутами) работает только в режиме НМ
	/*lds r16, display_mode
	cpi R16, MODE_HM
	brne OUT_DI2 ; Перейти если не равно
	;SBRC rFlags, rFlag_blink ; проверяет состояние одного бита в регистре и пропускает следующую команду если этот бит очищен
	SBRS rFlags, rFlag_blink ; проверяет состояние одного бита в регистре и пропускает следующую команду если этот бит установлен
	ori r18, (1<<7) ; устанавливаем 7 бит (это точка на 2-ом индикаторе) без изменения остальных
OUT_DI2:*/
	sts display_2, r18     ; Сохраняем в буфер для второго индикатора


    ; Индикатор 3: Десятки минут
    mov r18, r17
    swap r18
    andi r18, 0x0F        ; Десятки минут (0-5)
    rcall DIGIT_TO_SEGMENT
    sts display_3, r18     ; третий индикатор
    
    ; 4. Единицы минут
    mov r18, r17
    andi r18, 0x0F        ; Единицы минут (0-9)
    rcall DIGIT_TO_SEGMENT
    sts display_4, r18     ; четвертый индикатор
	
	;rjmp UPDATE_DISPLAY

/*MD3:; формирование дня недели
	ldi r16, 0b01000000
	sts display_1, r16
	sts display_2, r16
	sts display_4, r16	 ; четвертый индикатор
	lds  r17, i2c_weekday
	mov r18, r17
    andi r18, 0x0F        ; дни (1-7)
    rcall DIGIT_TO_SEGMENT
    sts display_3, r18   ; третий индикатор  */
	
	
UPDATE_DISPLAY:	 
	    
    ; ВАЖНО: передаем данные в обратном порядке!
    ; Первым выводим правый разряд (последний в цепочке 74HC595)
    
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
	;nop
	cbi SPI_PORT, LATCH 

	;pop r31
	;pop r30
	pop r18
	pop r17
	pop r16

    ret
	


