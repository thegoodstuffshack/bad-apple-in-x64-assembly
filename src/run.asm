[bits 64]
[default rel]
jmp start

signature: db 'BadApple'

; pointer to struct given in rbx -- need to update struct as needed
; SystemInfoStruct {
;	UINT64	Size
;	VOID*	SystemTable
;	VOID*	VRAM
;	UINT32	ScreenWidth
;	UINT32	ScreenHeight
;	VOID*	FrameData
;	UINT64	FrameDataSize
;	...
; }

; create space for struct here
; %include "src/SIstruct.asm"

SIS_Size 			equ 0
SIS_SystemTable 	equ 8
SIS_VRAM 			equ 16
SIS_ScreenWidth 	equ 24
SIS_ScreenHeight 	equ 28
SIS_FrameData 		equ 32
SIS_FrameDataSize 	equ 40


start:
	call PIT.init
	; requires a delay between the init and the wait for bare-metal
	mov ecx, 0x03FFFFFF
.delay:
	nop
	loop .delay

	call PIT.wait ; sync the first frame

; temporarily load the entire video into memory in order to test the buffer and pit,
; then implement a driver to read the files off a drive

frame_loop:
	call printFrame
	inc dword [frameCounter]
	cmp dword [frameCounter], 6562
	je .end

	call PIT.wait
	jmp frame_loop

.end:
	cli
	hlt

frameCounter dd 0

%include "src/pit.asm"
%include "src/frame.asm"
