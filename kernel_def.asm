		.def	ZERO		= R3					; Регистр нуля - он всегда ноль
		.def 	ACC		 	= r16					; Аккамулятор. Один из рабочих регистров. Его содержимое имеет смысл только в конкретный момент
		.def 	OSRG 		= R17					; Основной рабочий регистр ОС. Его содержимео имеет смысл только в конкретный момент.
		.def 	Counter		= r18					; Регистр обычно работающий счетчиком
		.def 	tmp2 		= r19					; Временынй регистр
		.def 	tmp3 		= r20					; Некоторые переменные общего назначения


		.def 	RND 		= r10					; Random X(i-1) - Число генерируемое датчиком случаных чисел
		.def 	CNT 		= r11					; 

		
		.equ TS_Idle 			= 0	; 
		.equ TS_SysLedOn		= 1	; 
		.equ TS_SysLedOff		= 2	; 
		.equ TS_KeyScan			= 3	; 
		.equ TS_ClearFlag		= 4	; 
		.equ TS_Reset_KeyFlagLong		= 5	; 
		.equ TS_LCD_Reflesh		= 6	; 
		.equ TS_Task7			= 7	; 
		.equ TS_Task8			= 8	; 
		.equ TS_Task9			= 9	; 
;========================================================================================
; Install RTOS
;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
; Воткнуть в ОЗУ!!!
;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
/*

			.dseg				
			.equ TaskQueueSize 		= 11				; Размер очереди сотытий
TaskQueue: 	.byte					TaskQueueSize 		; Адрес очереди сотытий в SRAM
			
			.equ TimersPoolSize 	= 5					; Количество таймеров
TimersPool:	.byte 					TimersPoolSize*3	; Адреса информации о таймерах

*/


;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
; Воткнуть в конец главной программы
;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
/*
;=============================================================================
; Прикладные задачи (подпрограммы)
;=============================================================================


Task1:		RET
;-----------------------------------------------------------------------------
Task2:		RET
;-----------------------------------------------------------------------------
Task3:		RET
;-----------------------------------------------------------------------------
Task4:		RET
;-----------------------------------------------------------------------------
Task5:		RET
;-----------------------------------------------------------------------------
Task6:		RET
;-----------------------------------------------------------------------------
Task7:		RET
;-----------------------------------------------------------------------------
Task8:		RET
;-----------------------------------------------------------------------------
Task9:		RET

;=============================================================================
; RTOS Here
;=============================================================================
			.include "kerneldef.asm"	; Подключаем настройки ядра
			.include "kernel.asm"		; Подклчюаем ядро ОС

; Таблица переходов
TaskProcs: 	.dw Idle					; [00] 
			.dw Task1					; [01] 
			.dw Task2					; [02] 
			.dw Task3					; [03] 
			.dw Task4					; [04] 
			.dw Task5					; [05] 
			.dw Task6					; [06] 
			.dw Task7					; [07] 
			.dw Task8				 	; [08]
			.dw	Task9					; [09]
;==============================================================================
*/

;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
; Воткнуть в раздел инициализации МК
;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
/*
;==================================================================================
; Init RTOS
;==================================================================================
			INIT_RTOS

*/
;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
; Воткнуть в обработчик прерывания OutputCompare2 по таймеру2 
;(для другого таймера придется править код)
;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

/*
;=============================================================================
; Interrupts procs
;=============================================================================
; Output Compare 1A interrupt 
; Main Timer Service - Служба Таймеров Ядра РТОС - Обработчик прерывания
OutComp2Int:
			TimerService				; Служба таймера RTOS 
			reti						; выходим из прерывания

*/
