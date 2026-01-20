/*
 * define.inc
 */ 

.equ F_CPU = 1000000

; SPI для 74HC595
.equ SPI_PORT    = PORTB
.equ SPI_DDR     = DDRB		; направление 1 -выход, 0 -вход
.equ SPI_PIN     = PINB		; информация только читается
.equ SCK         = PB5     ; CLOCK
.equ MISO        = PB4     ; не используется
.equ DATA        = PB3     ; DATA (SER)
.equ LATCH       = PB2     ; LATCH (CS)
.equ OE          = PB1     ; ШИМ для яркости (Output Enable, активный низкий)
.equ MR          = PB0	   ; reset для регистров 74HC595


; Кнопки на PD7-PD4 с внешней подтяжкой
.equ BTN_PORT    = PORTD
.equ BTN_DDR     = DDRD
.equ BTN_PIN     = PIND
.equ BTN_MASK    = 0xF0    ; PD7-PD4
.equ BTN1        = PD7
.equ BTN2        = PD6
.equ BTN3        = PD5
.equ BTN4        = PD4


.def rDebounce = r2     ; Счетчик антидребезга (теперь в младших регистрах)
.def rBtn_last  = r3    ; Предыдущее состояние для сравнения
.def rBtn_stat = r4     ; Итоговое стабильное состояние кнопок
.def rBtn_now  = r24   ; Текущее состояние кнопок


; DS3231 (на INT0)
.equ DS3231_INT   = PD2     ; INT0

; I2C для DS3231
.equ SDA          = PC4
.equ SCL          = PC5

; Флаги
.def rFlags = r25		 ; R25 регистр флагов
.equ flag_time = 0       ; Бит 0: событие 1 секунда (от INT0)
.equ flag_disp = 1	     ; Бит 1: Необходимость обновления дисплея
.equ flag_bnt   = 2      ; Бит 2: Есть нажатая кнопка (от Timer1)


; Сегменты цифр
.equ SEG_0 = 0b00111111
.equ SEG_1 = 0b00110000
.equ SEG_2 = 0b01101101
.equ SEG_3 = 0b01111001
.equ SEG_4 = 0b01110010
.equ SEG_5 = 0b01011011
.equ SEG_6 = 0b01011111
.equ SEG_7 = 0b00110001
.equ SEG_8 = 0b01111111
.equ SEG_9 = 0b01111011
.equ SEG_OFF = 0b00000000
.equ SEG_DP = 0b10000000


; =========== Сегмент данных ===========
.dseg
.org SRAM_START

; Режимы дисплея
display_mode: .byte 1
.equ MODE_HM     = 0      ; Часы-минуты
.equ MODE_MS     = 1      ; Минуты-секунды
.equ MODE_DM     = 2      ; Число-месяц
.equ MODE_DAY    = 3      ; День недели
.equ MODE_YEAR   = 4      ; Год (2 последние цифры)
.equ MODE_COUNT  = 5

edit_mode:    .byte 1

; Флаги
;Необходимость записи времени
flag_wr_time:        .byte 1
.equ wr_sec			= 0   ; нулевой бит, необходима запись секунд
.equ wr_min			= 1   ; необходима запись минут
.equ wr_hours		= 2   ; необходима запись часов
.equ wr_weekday		= 3   ; необходима запись дня недели
.equ wr_day			= 4   ; необходима запись дня месяца
.equ wr_mouth		= 5   ; необходима запись месяца
.equ wr_year		= 6   ; необходима запись года
.equ wr_time		= 7	  ; общий флаг необходимости записи времени

flag_dot:			.byte 1
.equ flag_dot_1			= 0   ; нулевой бит, точка первого индикатора
.equ flag_dot_2			= 1   ; первый бит, точка второго индикатора
.equ flag_dot_3			= 2   ; 
.equ flag_dot_4			= 3   ; 

; Буферы
display_buf:  .byte 4
.equ display_1		= display_buf       ; байт первого индикатора
.equ display_2		= display_buf+1     ; байт второго индикатора
.equ display_3		= display_buf+2     ; байт третьего индикатора
.equ display_4		= display_buf+3     ; байт четвертого индикатора

i2c_buffer:   .byte 7      ; Буфер для I2C (секунды, минуты, часы, день, дата, месяц, год)
.equ i2c_sec		= i2c_buffer     ; байт секунд в формате BCD 
.equ i2c_min		= i2c_buffer+1   ; байт минут в формате BCD
.equ i2c_hours		= i2c_buffer+2   ; байт часов в формате BCD 
.equ i2c_weekday	= i2c_buffer+3   ; байт дня недели в формате BCD 
.equ i2c_day		= i2c_buffer+4   ; байт дня месяца в формате BCD 
.equ i2c_month		= i2c_buffer+5   ; байт месяца в формате BCD 
.equ i2c_year		= i2c_buffer+6   ; байт года в формате BCD 

bin_time_buffer:	.byte 7      ; Буфер для времени в формате BIN (секунды, минуты, часы, день, дата, месяц, год)
.equ bin_sec		= bin_time_buffer     ; байт секунд в формате BIN
.equ bin_min		= bin_time_buffer+1   ; байт минут в формате BIN
.equ bin_hours		= bin_time_buffer+2   ; байт часов в формате BIN
.equ bin_weekday	= bin_time_buffer+3   ; байт дня недели в формате BIN
.equ bin_day		= bin_time_buffer+4   ; байт дня месяца в формате BIN
.equ bin_mouth		= bin_time_buffer+5   ; байт месяца в формате BIN
.equ bin_year		= bin_time_buffer+6   ; байт года в формате BIN


