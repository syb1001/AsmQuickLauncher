IFNDEF DECLARACTION_INC
DECLARACTION_INC equ <1>

;============include===============
include		windows.inc
include		gdi32.inc
include		user32.inc
include		kernel32.inc
include		masm32.inc
include		shell32.inc ; ShellExecute
include		Comdlg32.inc
include		advapi32.inc

includelib	gdi32.lib
includelib	user32.lib
includelib	kernel32.lib
includelib	masm32.lib
includelib	shell32.lib
includelib	Comdlg32.lib
includelib	MSVCRT.LIB
includelib	advapi32.lib
;==================================

;=============struct===============
ACTION STRUCT
	len dd 0
	seq dd 32 DUP(0)
	path db 1024 DUP(0)
	tip db 1024 DUP(0)
	pathType dd 0
ACTION ENDS
;==================================

;============procedure=============
;-------Track & Recognition--------
CalTan PROTO,
	X : DWORD,
	Y : DWORD

GetDirection PROTO,
	x0: DWORD,
	x1: DWORD,
	y0: DWORD,
	y1: DWORD

RecognizeTrack PROTO

InitializeTrack PROTO

Match PROTO,
	dir: DWORD

;--------------Util----------------
GetArrowSeq PROTO,
	p: PTR DWORD,
	len: DWORD,
	dest: PTR BYTE

ExecuteMatch PROTO,
	index: DWORD

CopyAction PROTO,
	dest: PTR ACTION,
	src: PTR ACTION

;-------------Action---------------
AddNewAction PROTO,
	seq: PTR DWORD,
	len: DWORD,
	path: PTR BYTE,
	tip: PTR BYTE, 
	pathType: DWORD
	
GetTipOfBestMatch PROTO
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

ToTray PROTO
IconRightButtonDown PROTO

LeftButtonDownProc PROTO,
	lParam:DWORD

;---------------UI-----------------
ProcessMenuEvents PROTO,
	evt: DWORD

initializeMenu PROTO

;---------------file---------------
ImportAcitons PROTO
ExportActions PROTO

;-----------dialog proc------------
_ProcEditDlgMain PROTO,
	hWnd: DWORD,
	wMsg: DWORD,
	wParam: DWORD,
	lParam: DWORD

_ProcNewDlgMain PROTO,
	hWnd: DWORD,
	wMsg: DWORD,
	wParam: DWORD,
	lParam: DWORD

_ProcInputBoxMain PROTO,
	hWnd: DWORD,
	wMsg: DWORD,
	wParam: DWORD,
	lParam: DWORD

_ProcDirBoxMain PROTO,
	hWnd: DWORD,
	wMsg: DWORD,
	wParam: DWORD,
	lParam: DWORD

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
externdef	drawPoint:		PTR POINT
externdef	drawLength:		DWORD
externdef	lastDirection:	SDWORD
externdef	lastPoint:		PTR POINT
;----------------------------------
externdef	train:			DWORD
externdef	isLButtonDown:	BYTE

; ---------action map-------------
externdef actionMap: PTR ACTION
externdef actionLen: DWORD 

;---------- recognize ------------
externdef bestMatch: SDWORD

;---------- arrow ----------------
externdef upArrow: BYTE
externdef downArrow: BYTE
externdef leftArrow: BYTE
externdef rightArrow: BYTE
;-------------handler--------------
externdef	hInstance:	DWORD
externdef	hWinMain:	DWORD
externdef	hMenu:		DWORD ; handler of main menu
externdef	hIconMenu:	DWORD

;--------------dialog--------------
externdef	actionAddressInputBox:	DWORD
externdef	actionAddressDirBox:	DWORD
;-----------functional-------------
externdef	functionEnabled:	BYTE
externdef	capturingNew:		BYTE

;-------------windows-------------
externdef	WINDOW_WIDTH:	DWORD
externdef	WINDOW_HEIGHT:	DWORD
externdef	nid:			NOTIFYICONDATA
;----------------------------------

;==================================

;=============macro================
;------------struct---------------
MAX_SEQ_LEN EQU 32
MAX_PATH_LEN EQU 1024
MAX_MAP_SIZE EQU 64
;------------track-----------------
MAX_MOUSE_TRACK_LENGTH EQU 1024
MAX_DIRECTIONS_PER_DWORD EQU 16
;------------file------------------
MAX_BUF_SIZE EQU 1024
SETTINGS_FILE EQU 'settings.ini',0
;----------------------------------
;==================================

;=========resource symbol==========
;---------menu resources-----------
IDR_MainMenu		equ		101
ID_MenuExit			equ		40001
ID_MenuEnable		equ		40002
ID_MenuEdit			equ		40003
ID_MenuNewGesture	equ		40004
ID_MenuFront		equ		40005
ID_MenuWindowFront	equ		40006
ID_MenuAutoRun		equ		40007

IDR_IconMenu	equ		107
ID_SHOW			equ		40012
ID_EXIT			equ		40013
;----------edit dialog-------------
IDD_EditDialog		equ		102
IDC_GestureList		equ		1001
IDC_GestureHint		equ		1004
IDC_GesturePath		equ		1008
IDC_ChooseFile		equ		1009
IDC_ChooseDirectory	equ		1010
IDC_EnterPath		equ		1012
IDC_EditGesture		equ		1011
IDC_GestureSequence	equ		1013
;-----------new dialog-------------
IDD_NewDialog		equ		105
;-----------input box--------------
IDD_InputBox		equ		103
IDC_InputPath		equ		1014
;------------dir box---------------
IDD_DirBox			equ		104
IDC_Up				equ		1015
IDC_Down			equ		1016
IDC_Left			equ		1017
IDC_Right			equ		1018
IDC_Clear			equ		1019
IDC_DirBox			equ		1020
;------------bitmaps---------------
IDB_LEFT			equ		201
IDB_RIGHT			equ		202
IDB_UP				equ		203
IDB_DOWN			equ		204
IDB_BOTTOMLEFT		equ		205
IDB_BOTTOMRIGHT		equ		206
IDB_BOTTOMUP		equ		207
IDB_BOTTOMDOWN		equ		208
;-------------icons----------------
IDI_TRAY			equ		106

;---------bmp attribute-------------
BMP_BOTTOM_SIZE			equ		25
BMP_CENTER_SIZE			equ		50


;---------window attribute-----------
;WINDOW_WIDTH	equ 600
;WINDOW_HEIGHT	equ 400

;------------------------------------
RECOGNIZE_DISTANCE	equ 20
;----------------------------------
;==================================

ELSE
	echo ------------------------------------------
	echo WARNING duplicate include Declaration.inc
	echo ------------------------------------------
ENDIF