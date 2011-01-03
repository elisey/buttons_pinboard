Reset:   	LDI 	R16,Low(RAMEND)	; Инициализация стека
		    OUT 	SPL,R16			; Обязательно!!!

		 	LDI 	R16,High(RAMEND)
		 	OUT 	SPH,R16

RAM_Flush:	LDI		ZL,Low(SRAM_START)	; Адрес начала ОЗУ в индекс
			LDI		ZH,High(SRAM_START)
			CLR		R16					; Очищаем R16
Flush:		ST 		Z+,R16				; Сохраняем 0 в ячейку памяти
			CPI		ZH,High(RAMEND)		; Достигли конца оперативки?
			BRNE	Flush				; Нет? Крутимся дальше!
 
			CPI		ZL,Low(RAMEND)		; А младший байт достиг конца?
			BRNE	Flush
 
			LDI	ZL, 30		; Адрес самого старшего регистра	
			CLR	ZH		; А тут у нас будет ноль
			DEC	ZL		; Уменьшая адрес
			ST	Z, ZH		; Записываем в регистр 0
			BRNE	PC-2		; Пока не перебрали все не успокоились



; Internal Hardware Init  ======================================
			
			INIT_RTOS
			INIT_LCD
			
			RCALL	LCD_Clear	; отчищаем память дисплея		

			SBI		DDRD,5		; ногу 5 порта D ставим на выход. моргалка-индикатор работы РТОС

			sei
; End Internal Hardware Init ===================================



; External Hardware Init  ======================================


; End Internal Hardware Init ===================================
