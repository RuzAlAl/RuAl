; Собственно код начинается отсюда
			;.CSEG
			.ORG 	0x0000			; Проц стартует с нуля, но дальше идут вектора 
			RJMP 	Reset			; прерываний, поэтому отсюда сразу же прыгаем на начало программы. На метку Reset
			.ORG	INT0addr		; External Interrupt Request 0 = 0x0001
			RJMP 	INT0_ISR		; Вектор INT0 (DS3231)
			.ORG	INT1addr		; External Interrupt Request 1 = 0x0002
			RETI
			.ORG	OC2addr			; Timer/Counter2 Compare Match = 0x0003
			RETI	
			.ORG	OVF2addr		; Timer/Counter2 Overflow	= 0x0004
			RETI
			.ORG	ICP1addr		; Timer/Counter1 Capture Event = 0x0005
			RETI
			.ORG	OC1Aaddr		; Timer/Counter1 Compare Match A = 0x0006
			RETI
			.ORG	OC1Baddr		; Timer/Counter1 Compare Match B = 0x0007
			RETI
			.ORG	OVF1addr		; Timer/Counter1 Overflow = 0x0008
			RETI
			.ORG	OVF0addr		; Timer/Counter0 Overflow = 0x0009
			;RJMP	TIMER0_OVF		; Jump to Timer0 overflow ISR
			.ORG	SPIaddr			; Serial Transfer Complete = 0x000a
			RETI
			.ORG	URXCaddr		; USART, Rx Complete = 0x000b
			RETI	
			.ORG	UDREaddr		; USART Data Register Empty = 0x000c
			RETI
			.ORG	UTXCaddr		; USART, Tx Complete = 0x000d
			RETI
			.ORG	ADCCaddr		; ADC Conversion Complete = 0x000e
			RETI
			.ORG	ERDYaddr		; EEPROM Ready = 0x000f
			RETI
			.ORG	ACIaddr			; Analog Comparator = 0x0010
			RETI
			.ORG	TWIaddr			; 2-wire Serial Interface = 0x0011
			RETI
			.ORG	SPMRaddr		; Store Program Memory Ready = 0x0012
			RETI
