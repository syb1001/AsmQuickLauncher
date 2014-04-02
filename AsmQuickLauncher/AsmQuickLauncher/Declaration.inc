;----------include-----------------
include		windows.inc
include		gdi32.inc
include		user32.inc
include		kernel32.inc

includelib	gdi32.lib
includelib	user32.lib
includelib	kernel32.lib

include shell32.inc			; ShellExecute
includelib shell32.lib
;----------------------------------

;----------struct------------------
ACTION STRUCT
	len dd 0
	trackSeq dd 100 DUP(0)
	path db 1024 DUP(0)
ACTION ENDS 
;----------------------------------

;----------procedure---------------
;==========Recognize.asm===========
CalTan PROTO,
	X : SDWORD,
	Y : SDWORD

GetDirection PROTO,
	x0: SDWORD,
	x1: SDWORD,
	y0: SDWORD,
	y1: SDWORD

RecognizeTrack PROTO

InitializeTrack PROTO

;==========Graphics.asm============
DrawLine PROTO,
	_hDc: DWORD

;==========UI.asm==================
ProcessMenuEvents PROTO,
	evt: DWORD
;----------------------------------

;---------variable-----------------
externdef trackPoint: PTR POINT 
externdef trackLength: DWORD
externdef trackSeq: DWORD
externdef seqLength: DWORD
;----------------------------------

;---------handler------------------
externdef	hInstance:	DWORD
externdef	hWinMain:	DWORD
externdef	hMenu:		DWORD ; handler of main menu
;----------------------------------

;---------macro--------------------
MAX_MOUSE_TRACK_LENGTH EQU 1024
MAX_DIRECTIONS_PER_DWORD EQU 9
;----------------------------------

;---------resource symbol----------
;=========menu resources===========
IDR_MainMenu		equ		101
ID_MenuExit			equ		40001
ID_MenuEnable		equ		40002
ID_MenuEdit			equ		40003