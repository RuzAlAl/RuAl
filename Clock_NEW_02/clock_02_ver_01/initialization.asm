/*
 * initialization.asm
 *
 *  Created: 02.02.2026 16:11:17
 *   Author: ar_user
 */ 
 ; =========== Инициализация переменных ===========
INIT_VARIABLES:
	clr r1 ; R1: Всегда 0x00 (ускоряет очистку регистров и портов)
    clr r16
	
	; Флаги
     clr rflags
	     
    ; Режимы
	;sts edit_mode, r16
	ldi r16,0
	sts edit_mode, r16

	ldi r16,0
	sts display_mode, r16
	

	; Нужно 3 стабильных считывания (30 мс)
	 ldi r16, 3
	 mov rDebounce, r16

	 ldi r16, 0xF0
	 mov rbtn_last, r16		; Считаем, что изначально кнопки отпущены (т.е. входы подтянуты внешними резисторами)
	 mov rbtn_now, r16
	 mov rbtn_stat, r16

	 ; Для теста
	 ldi r16, 0b00000001
	 mov r5, r16

    ret

; =========== Инициализация портов ===========
INIT_PORTS:
    
	; SPI порты (MOSI, SCK, SS, OE, MR как выходы)
    ldi r16, (1<<DATA)|(1<<SCK)|(1<<LATCH)|(1<<OE)|(1<<MR)
    out SPI_DDR, r16
    
    ; OE (яркость) - низкий уровень по умолчанию (максимальная яркость)
    cbi SPI_PORT, OE
	; MR (reset регистров 74HC595) - высокий уровень по умолчанию
	sbi SPI_PORT, MR
     
	    
    ; Порт для DS3231 (INT0)
    cbi DDRD, DS3231_INT      ; Вход
    sbi PORTD, DS3231_INT     ; Подтяжка
    
    ; Порты для I2C
    cbi DDRC, SDA             ; SDA - вход
    cbi DDRC, SCL             ; SCL - вход
    sbi PORTC, SDA            ; Подтяжка
    sbi PORTC, SCL            ; Подтяжка

	; Порты подключенных кнопок как входы и PD3 для INT1, без подтяжки (внешние резисторы на 5в)
    ldi r16, (0<<BTN1)|(0<<BTN2)|(0<<BTN3)|(0<<BTN4)|(0<<BTN_INT); BTN1 это PD7, BTN2 это PD6, BTN3 это PD5, BTN4 это PD4, BTN_INT это PD3
    out BTN_DDR, r16
    
    ret


; =========== Инициализация прерываний ===========
INIT_INTERRUPTS:
    ; INT0 - От DS3231 восходящий фронт генерирует запрос прерывания
    ldi r16, (1<<ISC01)|(1<<ISC00)
    out MCUCR, r16
    ldi r16, (1<<INT0)
    out GICR, r16

	; INT1 - прерывание от кнопок по нажатию 
    ; (нажатие = 1->0 на INT1, отпускание = 0->1)
    ldi r16, (1<<ISC11)|(0<<ISC10)  ; нажатие = 1->0
    out MCUCR, r16
	; ВКЛЮЧИТЬ INT1 (установить бит INT1, сохранив INT0)
	in  r16, GICR        ; Читаем текущее состояние
	ori r16, (1<<INT1)   ; Устанавливаем только бит INT1 (Разрешение INT1)
	out GICR, r16        ; Записываем обратно, включаем INT1

	; Разрешаем прерывание по переполнению Таймера 0
    in r16, TIMSK
    ori r16, (1 << TOIE0)
    out TIMSK, r16
    
    ret