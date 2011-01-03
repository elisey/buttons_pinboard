			.include "m16def.inc"   ; Используем ATMega16
			.include "macro.asm"
			.include "kernel_macro.asm"
			.include "LCD4_macro.inc"
		
; RAM ========================================================
		.DSEG
				.equ 	TaskQueueSize = 11	; Размер очереди событий
TaskQueue: 		.byte 	TaskQueueSize 		; Адрес очереди сотытий в SRAM
				.equ 	TimersPoolSize = 5	; Количество таймеров
TimersPool:		.byte 	TimersPoolSize*3	; Адреса информации о таймерах

KeyFlag:		.byte	1					; тут хранится номер последней нажатой кнопки в течении 200 мс. для устранения дребезга

PushCount:		.byte	1

KeyFlagLong:	.byte	1

CurrentPos:		.byte	1

				.equ	LCD_MEM_WIDTH = 32	; размер Видеопамяти
LCDMemory:		.byte	LCD_MEM_WIDTH

; FLASH ======================================================
			.include "vectors.asm"

; Interrupts ==============================================

OutComp2Int:	TimerService	; Служба таймера OS 
				RETI		; выходим из прерывания


; End Interrupts ==========================================
			
			.include 	"init.asm"
			.include	"keyb_scan_init.asm"
			
; Run ==========================================================
Background:		RCALL	SysLedOn
				RCALL	KeyScan
				RCALL	LCD_Reflesh
; End Run ======================================================


; Main =========================================================
Main:		SEI				; Разрешаем прерывания.
			wdr				; Reset Watch DOG 
			rcall 	ProcessTaskQueue	; Обработка очереди процессов
			rcall 	Idle			; Простой Ядра
			rjmp 	Main			; Основной цикл микроядра РТОС

	
; End Main =====================================================


Idle:		RET
;-----------------------------------------------------------------------------
SysLedOn:		SetTimerTask TS_SysLedOff,500
				SBI		PORTD,5
				RET
;-----------------------------------------------------------------------------
SysLedOff:		SetTimerTask TS_SysLedOn,500
				CBI		PORTD,5
				RET
;-----------------------------------------------------------------------------
KeyScan:		SetTimerTask	TS_KeyScan,50
				
				RCALL	btn_start		; сканируем клавиатуру. результат приходит в регистрах R16 и R17

				SET						; ставим флаг T в регистре SREG. Он будет означать, что мы обрабатываем первый принятный с клавиатуры байт

				LDI		ZL,low(Code_Table*2)	; берем адрес первой таблицы с переходами (для кнопок 1-8)
				LDI		ZH,high(Code_Table*2)

KS_loop:		CPI		R16,0xFF				; если байт равен 0xFF, то нажатия небыло, 
				BREQ	KS_loop_exit			; переходим на обработку следующего байта с клавиатуры

				LDS		R18,KeyFlag				; берем последнее зарегестрированное нажатие
				CP		R16,R18					; сравниваем с текущим
				BREQ	KS_loop_exit			; если одинаковы, переходим на обработку следующего байта с клавиатуры
				STS		KeyFlag,R16				; иначе сохраняем в RAM текущее нажатие как последнее зарегестрированное

				PUSH	R16
				PUSH	R17
				SetTimerTask	TS_ClearFlag,200	; ставим на запуск через 200 мс функцию очистки последнего зарегестрированного нажатия
				POP		R17							; данная функция использует R16 и R17, поэтому сохраняем их в стеке
				POP		R16

				RJMP	KS_got_smth					; если мы дошли до этого места, то у нас есть нажатие, которое нужно обработать. идем на обработку



KS_loop_exit:	BRTC	KS_exit					; проверяем флаг T в регистре SREG. Если он не сброшен, а значит мы считали только один байт с клавиатуры, то идем дальше, иначе выходим
				
				CLT								; сбрасываем флаг T.Это означает что мы считали первый байт с клавиатуры, и готовы ко второму.
				
				LDI		ZL,low(Code_Table2*2)	; берем адрес второй таблицы с переходами (для кнопок 9-16)
				LDI		ZH,high(Code_Table2*2)	
				MOV		R16,R17					; второй принятый байт перекидываем в R16
				RJMP	KS_loop					; и возвращаемся в цикл



; тут мы оказываемся, когда нам нужно обработать нажатие.
; 
KS_got_smth:	CLR		R18						; R18 будет счетчиком. Нужно сравнить 8 возможных состояний пришедшего байта, поэтому будем считать до 8	
				LDI		R19,0b11111110			; первоначальная маска для сравнения ее с пришедшим битом, и дальнейшего сдвигания влево

KS_loop2:		CP		R16,R19					; сравниваем маску с пришедшим байтом
				BREQ	KS_equal				; если равны, то переходим на действие

				INC		R18						; иначе увеличиваем счетчик
				CPI		R18,8					; сравниваем его с восьмеркой
				BREQ	KS_exit					; если досчитали до 8, то выходим

				SEC								; тут двигаем нашу маску влево. так как младшие байты нам нужно заполнять единицами, а функция ROL устанавливаем эту единицу только при наличии флага C, то устанавливаем его
				ROL		R19						; двигаем маску
				RJMP	KS_loop2				; и переходим опять на цикл

KS_equal:		LSL		R18						; R18 хранится число, до которого мы успели досчитать, пока ждали совпадения байта с клавиатуры с маской.В нем по сути находится номер нажатой кнопки. умножаем его на 2, так как в талице переходов адреса хранятся по 2 байта
				ADD		ZL,R18					; складываем смещение с заранее сохраненным адресом таблицы переходов
				ADC		ZH,R0					; в R0 я всегда храню ноль

				LPM		R16,Z+					;загружаю необходимый адрес из таблицы
				LPM		R17,Z

				MOV		ZL,R16					; перекидываем его в адресный регистр Z
				MOV		ZH,R17

				ICALL							; и вызываем функцию по этому адресу
												; ВНИМАНИЕ! так как мы используем именно вызов функции по адресу Z, в стеке у нас сохраняется адрес возврата. Из вызванной функции обязательно выходить командой RET. Иначе будет переполнение стека адресами возврата.
KS_exit:		RET
;-----------------------------------------------------------------------------
;Функция отчищает флаг последнего зарегестрированного нажатия.
;Используется для ликвидации случайных повторов при нажатии клавиши
ClearFlag:		SER		R16
				STS		KeyFlag,R16
				RET
;-----------------------------------------------------------------------------
Reset_KeyFlagLong:	
;Функция отчищает флаг последнего нажатия.
;Используется для реулизации возможности ввода одной клавишей нескольких символов,
;путем последовательного нажатия одной кнопки. (как на телефоне)  
				CLR		R16
				STS		KeyFlagLong,R16
				RET
;-----------------------------------------------------------------------------
;Функция отрисовки дисплея из видеопамяти. В цикле берет значения из RAM LCDMemory и записываем в LCD

LCD_Reflesh:	SetTimerTask	TS_LCD_Reflesh,100	; запускаем обновление дисплея каждый 100 мс

				LDI		ZL,low(LCDMemory*2)		; грузим в Z адрес таблицы памяти LCD
				LDI		ZH,high(LCDMemory*2)
				LCD_COORD	0,0					; устанавливаем текуюю координату курсора в LCD в самое начало
				LDI		R18,LCD_MEM_WIDTH		; грузим в R18 длину памяти LCD. это будет нас счетчик

lcd_loop:		LD		R17,Z+					; цикл. тут мы берем из памяти LCD один символ в регистр R17			
				
				RCALL	DATA_WR					; и записываем его в LCD.
				
				DEC		R18						; уменьшаем счетчик
				
				BREQ	lcd_exit				; если достигли конца LCD памяти - выходим

				CPI		R18,LCD_MEM_WIDTH/2		; если достигли конца первой строки
				brne	lcd_next
				
				LCD_COORD	0,1					; устанавливаем текущую координату курсора в LCD на вторую строчку

lcd_next:		RJMP	lcd_loop				; и продолжаем цикл
lcd_exit:		RET
;-----------------------------------------------------------------------------
Task7:		RET
;-----------------------------------------------------------------------------
Task8:		RET
;-----------------------------------------------------------------------------
Task9:		RET
 
; А после секции задач вставляем шаблонную таблицу переходов и код ядра
		.include "kernel_def.asm"	; Подключаем настройки ядра
		.include "kernel.asm"		; Подклчюаем ядро ОС
 		.include "keyb_scan.asm"
		.include "functions.asm"
		.include "ansi2lcd.asm"
		.include "LCD4.asm"

TaskProcs: 	.dw Idle				; [00] 
			.dw SysLedOn			; [01] 
			.dw SysLedOff			; [02] 
			.dw KeyScan				; [03] 
			.dw ClearFlag 			; [04] 
			.dw Reset_KeyFlagLong	; [05] 
			.dw LCD_Reflesh			; [06] 
			.dw Task7				; [07] 
			.dw Task8				; [08]
			.dw Task9				; [09]

Code_Table:		.dw		Key1,	Key2,	Key3,	Key4,	Key5,	Key6,	Key7,	Key8
Code_Table2:	.dw		Key9,	Key10,	Key11,	Key12,	Key13,	Key14,	Key15,	Key16

Letter_K_Table1:	.db	0x2E,0x2C,0x3F,0x21,0, 0			;""., ",", "?", "!"

Letter_K_Table2:	.db	0xE0,0xE1,0xE2,0xE3,0, 0			;а, б, в, г

Letter_K_Table3:	.db	0xE4,0xE5,0xE6,0xE7,0, 0			;д, е, ж, з

Letter_K_Table4:	.db	0xE8,0xE9,0xEA,0xEB,0, 0			;и, й, к, л

Letter_K_Table5:	.db	0xEC,0xED,0xEE,0xEF,0, 0			;м, н, о, п

Letter_K_Table6:	.db	0xf0,0xf1,0xf2,0xf3,0, 0			;р, с, т, у

Letter_K_Table7:	.db	0xf4,0xf5,0xf6,0xf7,0, 0			;ф, х, ц, ч

Letter_K_Table8:	.db	0xf8,0xf9,0xfa,0xfb,0, 0			;ш, щ, ъ, ы

Letter_K_Table9:	.db	0xfc,0xfd,0xfe,0xff,0, 0			;ь, э, ю, я

; EEPROM =====================================================
			.ESEG				; Сегмент EEPROM
