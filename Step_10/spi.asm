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
    ;ldi r16, (0<<SPI2X); этот бит в нуль для полного спокойствия
	ldi r16, (1<<SPI2X); Бит удвоения скорости SPI
    out SPSR, r16
    ret


;=================== SPI_SEND (ОТПРАВКА БАЙТА ЧЕРЕЗ SPI)===================

SPI_SEND:
    ; Вход: r16 = данные для отправки
    ; Выход: данные отправлены через аппаратный SPI
    
    out SPDR, r16          ; Записываем данные в регистр SPI

SPI_WAIT:
    in r16, SPSR           ; Читаем статус SPI
    sbrs r16, SPIF         ; Пропустить следующую команду если бит в регистре установлен. Проверяем флаг завершения передачи
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

