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

.equ BEEPER_PIN  = PB0	   ; Выход для бипера

; Кнопки на PD7-PD4 с внешней подтяжкой
.equ BTN_PORT    = PORTD
.equ BTN_DDR     = DDRD
.equ BTN_PIN     = PIND
.equ BTN_MASK    = 0xF0		; PD7-PD4
.equ BTN1        = 7		;PD7 Минус
.equ BTN2        = 6		;PD6 Плюс
.equ BTN3        = 5		;PD5 Вход в настройку (Edit)
.equ BTN4        = 4		;PD4 Режимы дисплея/ Запись времени

.equ BEEP_LEN   = 5     ; Длительность работы БИППЕРА (3 * 10мс = 30мс)
.def rBeepTimer = r9     ; Счетчик длительности звука (в младших регистрах)

.equ T_SHORT	= 5        ; 50 мс : Дребезг 5 проходов по 10 мс
.equ Sec_TimeOut     = 50	   ; 50 сек : Время для перехода в режим отображения по умолчанию

.def rDebounce	 = r8     ; Счетчик антидребезга
.def rBtn_now    = r20    ; Текущее чтение PIND
.def rBtn_Index  = r21	  ; Индекс нажатой кнопки

; Кнопки через диоды (на INT1)
.equ BTN_INT   = PD3     ; INT1

; DS3231 (на INT0)
.equ DS3231_INT   = PD2     ; INT0

; I2C для DS3231
.equ SDA          = PC4
.equ SCL          = PC5

; Флаги
.def rFlags = r23		  ; R23 регистр флагов
.equ rFlag_int0   = 0	  ; Бит 0: Событие INT0 (от DS3231)
.equ rFlag_dot  = 1		 ; Бит 1: Фаза мигания точки
.equ rFlag_short  = 2     ; Бит 2: Короткое нажатие
.equ rFlag_TimeOut = 3	  ; Бит 3: TimeOut режимов 
.equ rFlag_beep   = 4     ; Бит 4: Активность бипера (1 - звучит)
.equ rFlag_Reg10h   = 5     ; Бит 5: Выполнено чтение регистра 10H DS3231



; Сегменты цифр 0b dp,g,f,e,d,c,b,a
			
.equ SEG_0 = 0b00111111
.equ SEG_1 = 0b00000110
.equ SEG_2 = 0b01011011
.equ SEG_3 = 0b01001111
.equ SEG_4 = 0b01100110
.equ SEG_5 = 0b01101101
.equ SEG_6 = 0b01111101
.equ SEG_7 = 0b00000111
.equ SEG_8 = 0b01111111
.equ SEG_9 = 0b01101111
.equ SEG_C = 0b00111001
.equ SEG_E = 0b01111001
.equ SEG_ho = 0b01100011
.equ SEG_lo = 0b01011100
.equ SEG_OFF  = 0b00000000


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


edit_mode:    .byte 1
.equ edit_off		= 0      ; редактирование отключено
.equ edit_sec		= 1      ; секунды
.equ edit_min		= 2      ; минуты
.equ edit_hours     = 3      ; часы
.equ edit_weekday   = 4      ; день недели
.equ edit_day		= 5      ; день месяца
.equ edit_mouth		= 6      ; месяц
.equ edit_year		= 7      ; год
.equ edit_crystal	= 8      ; смещение старения кварцевого резонатора


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

i2c_crystal: .byte 1    ; байт с регистра смещения старения кварцевого резонатора

adc_date:	.byte 1    ; байт регистра ADCH ацп, информация о освещенности

rBtn_Save:   .byte 1    ; состояние нажатой кнопки

timeout_cnt:  .byte 1    ; счетчик сброса режимов
