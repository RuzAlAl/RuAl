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

Buffer_disp:
	push r18
    		    
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

    ; Добавляем мигающую точку (между часами и минутами) работает только в режиме НМ
	
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
    
UPDATE_DISPLAY:	 
	;push r16      
    ; ВАЖНО: передаем данные в обратном порядке!
    ; Первым выводим правый разряд (последний в цепочке 74HC595)
    
	lds r22,display_4
	rcall spi_send
	lds r22,display_3
	rcall spi_send
	lds r22,display_2
	rcall spi_send
	lds r22,display_1
	rcall spi_send

	    
    ; Защелкиваем данные (импульс на SS/CS)
	sbi SPI_PORT, LATCH
	nop
	cbi SPI_PORT, LATCH 

	pop r18
    ret
	;rjmp MAIN_LOOP


	
;=================== SPI_SEND (ОТПРАВКА БАЙТА ЧЕРЕЗ SPI)===================

SPI_SEND:
    ; Вход: r22 = данные для отправки
    ; Выход: данные отправлены через аппаратный SPI
    
    out SPDR, r22          ; Записываем данные в регистр SPI

SPI_WAIT:
    in r22, SPSR           ; Читаем статус SPI
    sbrs r22, SPIF         ; Проверяем флаг завершения передачи
	rjmp SPI_WAIT          ; Ждем завершения
    
    ret

DIGIT_TO_SEGMENT:
    ; Вход: r18 = цифра (0-9)
    ; Выход: r18 = код сегментов для этой цифры
    ; Использует: Z, r17

    push ZL
    push ZH
    push r17
   
    ldi ZL, low(SEG_TABLE*2)
    ldi ZH, high(SEG_TABLE*2)
    add ZL, r18
    clr r17
    adc ZH, r17
    lpm r18, Z

    pop r17
    pop ZH
    pop ZL
    ret

