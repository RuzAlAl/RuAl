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
    
    lds r16, bin_sec
    rcall BIN_TO_BCD
    rcall I2C_WRITE
    
    lds r16, bin_min
    rcall BIN_TO_BCD
    rcall I2C_WRITE
    
    lds r16, bin_hours
    rcall BIN_TO_BCD
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
;запись секунд
	lds r16, flag_wr_time	;считываем
	sbrs r16, wr_sec		;Пропустить следующую команду если бит в регистре установлен
	rjmp M_Wr
	cbr r16, (1<<wr_sec)	; СРАЗУ сбрасываем флаг
	sts flag_wr_time, r16	; записываем
	ldi r16, 0x00	; адрес регистра секенд
	rcall I2C_WRITE
	lds r16, bin_sec
    rcall BIN_TO_BCD
	rjmp WR_T
;запись минут
M_Wr:
	sbrs r16, wr_min
	rjmp H_Wr
	cbr r16, (1<<wr_min)	; СРАЗУ сбрасываем флаг
	sts flag_wr_time, r16	; записываем
	ldi r16, 0x01	; адрес регистра минут
	rcall I2C_WRITE
	lds r16, bin_min
    rcall BIN_TO_BCD
	rjmp WR_T
;запись часов
H_Wr:
	sbrs r16, wr_hours
	rjmp WD_Wr
	cbr r16, (1<<wr_hours)	; СРАЗУ сбрасываем флаг
	sts flag_wr_time, r16	; записываем
	ldi r16, 0x02	; адрес регистра часов
	rcall I2C_WRITE
	lds r16, bin_hours
    rcall BIN_TO_BCD
	rjmp WR_T
;запись дня недели
WD_Wr:
	sbrs r16, wr_weekday
	rjmp D_Wr
	cbr r16, (1<<wr_weekday)	; СРАЗУ сбрасываем флаг
	sts flag_wr_time, r16	; записываем
	ldi r16, 0x03	; адрес регистра дня недели
	rcall I2C_WRITE
	lds r16, bin_weekday
    rcall BIN_TO_BCD
	rjmp WR_T
;запись дня месяца
D_Wr:
	sbrs r16, wr_day
	rjmp MO_Wr
	cbr r16, (1<<wr_day)	; СРАЗУ сбрасываем флаг
	sts flag_wr_time, r16	; записываем
	ldi r16, 0x04	; адрес регистра дня месяца
	rcall I2C_WRITE
	lds r16, bin_day
    rcall BIN_TO_BCD
	rjmp WR_T
;запись месяца
MO_Wr:
	sbrs r16, wr_mouth
	rjmp Y_Wr
	cbr r16, (1<<wr_mouth)	; СРАЗУ сбрасываем флаг
	sts flag_wr_time, r16	; записываем
	ldi r16, 0x05	; адрес регистра месяца
	rcall I2C_WRITE
	lds r16, bin_mouth
    rcall BIN_TO_BCD
	rjmp WR_T
;запись года
Y_Wr:
	sbrs r16, wr_year
	rjmp St_Wr
	cbr r16, (1<<wr_year)	; СРАЗУ сбрасываем флаг
	sts flag_wr_time, r16	; записываем
	ldi r16, 0x06	; адрес регистра года
	rcall I2C_WRITE
	lds r16, bin_year
    rcall BIN_TO_BCD
	rjmp WR_T

WR_T:	
	rcall I2C_WRITE
    rcall I2C_STOP
St_Wr:
	pop r16
    ret
; =========== Запись часов в DS3231 ===========
WRITE_HOURS:
    push r16
    
    ;rcall I2C_INIT
    
	rcall I2C_START
    ldi r16, 0xD0
    rcall I2C_WRITE
    
    ldi r16, 0x02	; адрес регистра часов
    rcall I2C_WRITE
    
    lds r16, bin_hours
    rcall BIN_TO_BCD
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

; =========== BCD в BIN ===========
BCD_TO_BIN:
	; Вход: r16
    push r17
    push r18
    mov  r17, r16       ; Копируем BCD
    andi r17, 0x0F      ; R17 = Единицы (младшая тетрада)
    swap r16            ; Меняем тетрады местами
    andi r16, 0x0F      ; R16 = Десятки (бывшая старшая тетрада)
    
    ; Умножение на 10: (X * 8) + (X * 2)
    mov  r18, r16       ; R18 = X
    lsl  r16            ; X * 2
    lsl  r16            ; X * 4
    lsl  r16            ; X * 8
    add  r16, r18       ; + X = X * 9
    add  r16, r18       ; + X = X * 10
    
    add  r16, r17       ; Прибавляем единицы
    pop  r18
    pop  r17
    ret

; =========== BIN в BCD ===========
BIN_TO_BCD:
	; Вход: r16
    push r17
    ldi  r17, 0         ; Счетчик десятков
BIN_loop:
    cpi  r16, 10        ; Сравниваем с 10
    brlo BIN_done       ; Если меньше 10, выходим
    subi r16, 10        ; Вычитаем 10
    inc  r17            ; Увеличиваем счетчик десятков
    rjmp BIN_loop
BIN_done:
    swap r17            ; Перемещаем десятки в старшую тетраду
    or   r16, r17       ; Объединяем с единицами (BCD упакованный)
    pop  r17
    ret

