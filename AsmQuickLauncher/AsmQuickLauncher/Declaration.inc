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
;----------------------------------

;---------variable-----------------
externdef trackPoint: PTR POINT 
externdef trackLength: DWORD
externdef trackSeq: DWORD
externdef seqLength: DWORD
;----------------------------------

;---------macro--------------------
MAX_MOUSE_TRACK_LENGTH EQU 1024
 MAX_DIRECTIONS_PER_DWORD EQU 9
;----------------------------------