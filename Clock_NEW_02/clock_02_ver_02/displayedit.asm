/*
 * displayedit.asm
 *
 *  Created: 04.02.2026 13:29:19
 *   Author: ar_user
 */ 
 DISPLAY_EDIT:
	LSL r5
	mov r16,r5
	sts display_1, r16
	sts display_2, r16
	sts display_3, r16     
	sts display_4, r16
	tst r16
	BRNE UDE
	LDI r16,1
	mov r5,r16
UDE:
	rcall UPDATE_DISPLAY_EDIT
	ret

UPDATE_DISPLAY_EDIT:	 
	    
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
	nop
	cbi SPI_PORT, LATCH 
	ret