/*
 * button.asm
 *
 *  Created: 20.01.2026 20:48:56
 *   Author: ar_user
 */ 
 TIMER0_ISR:
	;sbi PORTB, 0        ; ПОДНЯТЬ PB0 (Начало импульса)  для осцилла

	in r0, SREG         ; Быстро сохраняем статус в R0 (1 такт)
    push r16

 

End_ISR:
	
    pop r16
    out SREG, r0

	;cbi PORTB, 0        ; ОПУСТИТЬ PB0 (Конец импульса) для осцилла
    
	reti
 
 PROCESS_BUTTONS:
 nop
 ret