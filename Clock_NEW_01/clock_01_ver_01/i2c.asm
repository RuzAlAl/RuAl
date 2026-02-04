/*
 * i2c.asm
*/ 
; =========== Инициализация DS3231 ===========
INIT_DS3231:
    rcall I2C_INIT
    
    rcall I2C_START
    ldi r16, 0xD0		;адрес DS3231
    rcall I2C_WRITE
    
    ldi r16, 0x0E		; адресс Control Register (0Eh) DS3231 
    rcall I2C_WRITE
    
    ldi r16, 0x00		; запись в Control Register (0Eh) DS3231 Установка SQW на 1 Гц
    rcall I2C_WRITE
    
    rcall I2C_STOP

	;rcall READ_DATETIME_FULL
	rcall READ_DATETIME

    ret

;============== Чтение времени из DS3231 ==================================

READ_DATETIME:
    push r16
	        
    ;rcall I2C_INIT
    
    rcall I2C_START
    ; Адрес DS3231 для записи
    ldi r16, 0xD0
    rcall I2C_WRITE
    
    ; Регистр 0x00 (секунды)
    ldi r16, 0x00
    rcall I2C_WRITE
    
	rcall I2C_START
    ; Повторный START для чтения
    ldi r16, 0xD1
    rcall I2C_WRITE
		
	rcall I2C_READ_ACK
	in r16, TWDR
	sts i2c_sec,r16
	
	rcall I2C_READ_ACK
	in r16, TWDR
	sts i2c_min,r16
	
	rcall I2C_READ_NACK
	in r16, TWDR
	sts i2c_hours,r16
		
	rcall I2C_STOP
	
	pop r16
   ret

;============== Чтение времени из DS3231 ==================================

READ_DATETIME_FULL:
    push r16
	        
        
    rcall I2C_START
    ; Адрес DS3231 для записи
    ldi r16, 0xD0
    rcall I2C_WRITE
    
    ; Регистр 0x00 (секунды)
    ldi r16, 0x00
    rcall I2C_WRITE
    
	rcall I2C_START
    ; Повторный START для чтения
    ldi r16, 0xD1
    rcall I2C_WRITE
		
	rcall I2C_READ_ACK
	in r16, TWDR
	sts i2c_sec,r16
	
	rcall I2C_READ_ACK
	in r16, TWDR
	sts i2c_min,r16

	rcall I2C_READ_ACK
	in r16, TWDR
	sts i2c_hours,r16

	rcall I2C_READ_ACK
	in r16, TWDR
	sts i2c_weekday,r16

	rcall I2C_READ_ACK
	in r16, TWDR
	sts i2c_day,r16

	rcall I2C_READ_ACK
	in r16, TWDR
	sts i2c_month,r16
	
	rcall I2C_READ_NACK
	in r16, TWDR
	sts i2c_year,r16
		
	rcall I2C_STOP
	
	pop r16
   ret


; =========== Запись времени в DS3231 ===========
WRITE_DATETIME:
    push r16
    
    ;rcall I2C_INIT
    
	rcall I2C_START
    ldi r16, 0xD0
    rcall I2C_WRITE
    
    ldi r16, 0x00
    rcall I2C_WRITE
    
    lds r16, i2c_sec
    rcall I2C_WRITE
    
    lds r16, i2c_min
    rcall I2C_WRITE
    
    lds r16, i2c_hours
    rcall I2C_WRITE
    
    rcall I2C_STOP

    pop r16
    ret


; =========== I2C процедуры ===========
I2C_INIT:
    ldi r16, 11
    out TWBR, r16 ; TWI Bit Rate Register  коэффициент деления для генератора скорости передачи данных
    ldi r16, (0<<TWPS1)|(0<<TWPS0) ; биты предварительного делителя в регистр TWSR (PrescalerValue = 1)
    out TWSR, r16
    ret

	; TWINT  устанавливается аппаратно, когда TWI завершил свою текущую работу и ожидает ответа 
	; TWEN разрешает работу TWI и активирует интерфейс TWI
	; TWSTA генерирует условие START
I2C_START:
    ldi r16, (1<<TWINT)|(1<<TWEN)|(1<<TWSTA)
    out TWCR, r16

I2C_WAIT:
    in r16, TWCR
    sbrs r16, TWINT ;  проверяет состояние 7 бита TWINT в регистре и, если этот бит установлен, пропускает следующую команду
    rjmp I2C_WAIT
    ret

I2C_WRITE:
    out TWDR, r16
    ldi r16, (1<<TWINT)|(1<<TWEN)
    out TWCR, r16
    rjmp I2C_WAIT

	; TWEA: TWI Enable Acknowledge Bit 
I2C_READ_ACK:
    ldi r16, (1<<TWINT)|(1<<TWEN)|(1<<TWEA)
    out TWCR, r16
    rjmp I2C_WAIT

I2C_READ_NACK:
    ldi r16, (1<<TWINT)|(1<<TWEN)
    out TWCR, r16
    rjmp I2C_WAIT

	; TWSTO: TWI STOP Condition Bit 
I2C_STOP:
    ldi r16, (1<<TWINT)|(1<<TWEN)|(1<<TWSTO)
    out TWCR, r16
    ret

