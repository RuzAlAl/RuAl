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

	rcall READ_DATETIME_FULL
	;rcall READ_DATETIME

    ret

; Подстраиваем глубину опроса времени.
; В режимах показа часов-минут, минут-секунд читаем только первые 3 байта (Сек, Мин, Час)
; В режимах день недели, день-месяц, год читаем 7 байт
RTC_ADAPTIVE:
	lds r16, display_mode
    cpi r16, MODE_DM          ; Если режим Дата, День или Год
    brsh READ_FULL            ; Переход если больше или равно (Читаем все 7 байт)

    ; Иначе (HM или MS) — читаем только первые 3 байта (Сек, Мин, Час)
    ;ldi r17, 3
    rcall READ_DATETIME
    rjmp OUT_RTC

READ_FULL:
    ;ldi r17, 7
    rcall READ_DATETIME_FULL
OUT_RTC:
	ret

;============== Чтение времени из DS3231 ==================================

READ_DATETIME:
    push r16
	 cbr rFlags, (1<<rFlag_int0)       
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

;============== Запись определенных параметров времени в DS3231 ====================
	WRITE_SPECIFIC_TIME:
	push r16

	rcall I2C_START
    ldi r16, 0xD0
    rcall I2C_WRITE

	lds r16, edit_mode
;запись секунд
	cpi r16,1		;
	BRNE M_Wr		;Перейти если не равно
	ldi r16, 0x00	; адрес регистра секенд
	rcall I2C_WRITE
	lds r16, i2c_sec
    rjmp WR_T
;запись минут
M_Wr:
	cpi r16,2		;
	BRNE H_Wr		;Перейти если не равно
	ldi r16, 0x01	; адрес регистра минут
	rcall I2C_WRITE
	lds r16, i2c_min
    rjmp WR_T
;запись часов
H_Wr:
	cpi r16,3		;
	BRNE WD_Wr		;Перейти если не равно
	ldi r16, 0x02	; адрес регистра часов
	rcall I2C_WRITE
	lds r16, i2c_hours
    rjmp WR_T
;запись дня недели
WD_Wr:
	cpi r16,4		;
	BRNE D_Wr		;Перейти если не равно
	ldi r16, 0x03	; адрес регистра дня недели
	rcall I2C_WRITE
	lds r16, i2c_weekday
	rjmp WR_T
;запись дня месяца
D_Wr:
	cpi r16,5		;
	BRNE MO_Wr		;Перейти если не равно
	ldi r16, 0x04	; адрес регистра дня месяца
	rcall I2C_WRITE
	lds r16, i2c_day
    rjmp WR_T
;запись месяца
MO_Wr:
	cpi r16,6		;
	BRNE Y_Wr		;Перейти если не равно
	ldi r16, 0x05	; адрес регистра месяца
	rcall I2C_WRITE
	lds r16, i2c_month
	rjmp WR_T
;запись года
Y_Wr:
	cpi r16,7		;
	BRNE St_Wr		;Перейти если не равно
	ldi r16, 0x06	; адрес регистра года
	rcall I2C_WRITE
	lds r16, i2c_year
    rjmp WR_T

WR_T:	
	rcall I2C_WRITE
    rcall I2C_STOP
St_Wr:
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

