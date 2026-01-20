/*
 * spi_1.asm
 *
 *  Created: 07.01.2026 22:45:59
 *   Author: ar_user
 */ 
 INIT_SPI:
; Включение SPI, режим Master, частота F_CPU/16
    ldi r16, (1<<SPE)|(1<<MSTR)|(0<<SPR1)|(1<<SPR0)
    out SPCR, r16
    ldi r16, (0<<SPI2X); этот бит в нуль для полного спокойствия
    out SPSR, r16
    ret

UPDATE_DISPLAY:
	push r16
	in r16, SREG
    push r16
	push r17
	push r18
		
	/*; Загружаем часы и минуты
    lds r16, i2c_hours   ; Часы (0-23)
	lds r17, i2c_min ; Минуты (0-59)*/

	; Загружаем минуты и секунды
    lds r16, i2c_min   ; Часы (0-23)
	lds r17, i2c_sec ; Минуты (0-59)

	/*; Загружаем день и месяц
    lds r16, i2c_day   ; Часы (0-23)
	lds r17, i2c_month ; Минуты (0-59)*/

	    
    ; Формируем 4 цифры:
    ; Индикатор 1 (левый): десятки часов
    mov r18, r16
    swap r18
    andi r18, 0x0F        ; Десятки часов (0-2)
    rcall DIGIT_TO_SEGMENT    ; преобразуем цифру в код сегментов
    sts display_1, r18     ;  Сохраняем в буфер для левого индикатора
    
    ; Индикатор 2: единицы часов + точка
    mov r18, r16
    andi r18, 0x0F        ; Единицы часов (0-9)
    rcall DIGIT_TO_SEGMENT ; преобразуем цифру в код сегментов

    /*; Добавляем точку (между часами и минутами)
	
	lds r19,flag_dot
	sbrs r19, flag_dot_2 ;Пропустить следующую команду если бит в регистре стоит
	rjmp Dot
	cbr r18, (1<<7)
	cbr r19, (1<<flag_dot_2) ;сбросить флаг
	sts flag_dot, r19
	rjmp Disp2
Dot:
	ori r18, (1<<7)         ; устанавливаем 7 бит без изменения остальных
	sbr r19, (1<<flag_dot_2) ;установить флаг
	sts flag_dot, r19
Disp2:*/

	sts display_2, r18     ; второй индикатор

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
    
	       
   ; ВАЖНО: передаем данные в обратном порядке!
    ; Первым выводим правый разряд (последний в цепочке 74HC595)
    
	lds r16,display_4
	rcall SPI_SEND
	lds r16,display_3
	rcall SPI_SEND
	lds r16,display_2
	rcall SPI_SEND
	lds r16,display_1
	rcall SPI_SEND
    
    ; Защелкиваем данные (импульс на SS/CS)
	sbi SPI_PORT, LATCH
    cbi SPI_PORT, LATCH 
        
	; Восстанавливаем регистры и возвращаемся
    pop r18
    pop r17
    pop r16
	out SREG, r16
	pop r16
    ret

;=================== SPI_SEND (ОТПРАВКА БАЙТА ЧЕРЕЗ SPI)===================

SPI_SEND:
    ; Вход: r16 = данные для отправки
    ; Выход: данные отправлены через аппаратный SPI
    
    out SPDR, r16          ; Записываем данные в регистр SPI
    
SPI_WAIT:
    in r16, SPSR           ; Читаем статус SPI
    sbrs r16, SPIF         ; Проверяем флаг завершения передачи
	rjmp SPI_WAIT          ; Ждем завершения
    
    ; Можно прочитать принятые данные (если нужно)
    ; in r16, SPDR
    
    ret

DIGIT_TO_SEGMENT:
    ; Вход: r18 = цифра (0-9)
    ; Выход: r18 = код сегментов для этой цифры
    ; Использует: Z, r16

    push ZL
    push ZH
    push r16
   
    ldi ZL, low(SEG_TABLE*2)
    ldi ZH, high(SEG_TABLE*2)
    add ZL, r18
    clr r16
    adc ZH, r16
    lpm r18, Z

    pop r16
    pop ZH
    pop ZL
    ret