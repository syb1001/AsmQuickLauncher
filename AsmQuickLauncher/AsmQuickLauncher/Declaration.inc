IFNDEF DECLARACTION_INC
DECLARACTION_INC equ <1>

;============include===============
include		windows.inc
include		gdi32.inc
include		user32.inc
include		kernel32.inc
include		masm32.inc
include		shell32.inc ; ShellExecute

includelib	gdi32.lib
includelib	user32.lib
includelib	kernel32.lib
includelib	masm32.lib
includelib	shell32.lib
includelib MSVCRT.LIB
;==================================

;=============struct===============
ACTION STRUCT
	len dd 0
	seq dd 32 DUP(0)
	path db 1024 DUP(0)
ACTION ENDS 
;==================================

;============procedure=============
;-------Track & Recognition--------
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

Match PROTO

;-------------Action---------------
AddNewAction PROTO,
	seq: PTR DWORD,
	len: DWORD,
	path: PTR BYTE

;-------------DEBUG----------------
MessageBoxDwordArr PROTO,
	pArr: PTR DWORD,
	len: DWORD,
	path: PTR BYTE
	
TestProc PROTO

;------------Graphics--------------
DrawLine PROTO,
	_hDc: DWORD

CreateBitMap PROTO, 
	_hDc: DWORD

;---------------UI-----------------
ProcessMenuEvents PROTO,
	evt: DWORD

;---------------file---------------
ImportAcitons PROTO
ExportActions PROTO
ConvertDword2Str PROTO,
	num: DWORD,
	s: PTR BYTE 
;----------------------------------



;==================================

;============variable==============
;----------Mouse track-------------
externdef	trackPoint:		PTR POINT 
externdef	trackLength:	DWORD
externdef	trackSeq:		DWORD
externdef	seqLength:		DWORD
externdef	trainSeq:		DWORD
externdef	trainLength:	DWORD
;----------------------------------
externdef train: DWORD

; ---------action map-------------
externdef actionMap: PTR ACTION
externdef actionLen: DWORD 

;-------------handler--------------
externdef	hInstance:	DWORD
externdef	hWinMain:	DWORD
externdef	hMenu:		DWORD ; handler of main menu
;----------------------------------
;==================================

;=============macro================
;------------struct---------------
MAX_SEQ_LEN EQU 32
;------------track-----------------
MAX_MOUSE_TRACK_LENGTH EQU 1024
MAX_DIRECTIONS_PER_DWORD EQU 16
;------------file------------------
MAX_BUF_SIZE EQU 8192
SETTINGS_FILE EQU 'settings.ini',0
;----------------------------------
;==================================

;=========resource symbol==========
;---------menu resources-----------
IDR_MainMenu		equ		101
ID_MenuExit			equ		40001
ID_MenuEnable		equ		40002
ID_MenuEdit			equ		40003

;---------window attribute-----------
WINDOW_WIDTH	equ 600
WINDOW_HEIGHT	equ 400
;----------------------------------
;==================================

ELSE
	echo ------------------------------------------
	echo WARNING duplicate include Declaration.inc
	echo ------------------------------------------
ENDIF