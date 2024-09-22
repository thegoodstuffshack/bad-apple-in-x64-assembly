[bits 64]
[default rel]
jmp start

signature: db 'BadApple'

; pointer to struct given in rbx -- need to update struct as needed
; SystemInfoStruct {
;	UINT64	Size
;	VOID*	SystemTable
;	VOID*	GOP_Interface	EFI_GRAPHICS_OUTPUT_PROTCOL
;	VOID*	VRAM
;	UINT32	ScreenWidth
;	UINT32	ScreenHeight
;	VOID*	DriveRoot		EFI_FILE_PROTOCOL
;	...
; }

SIS_Size 			equ 0
SIS_SystemTable 	equ 8
SIS_GOP_Interface 	equ 16
SIS_VRAM 			equ 24
SIS_ScreenWidth 	equ 32
SIS_ScreenHeight 	equ 36
SIS_DriveRoot		equ 40


start:
	; make/find frame buffer
	; edit frame buffer
	; swap buffers
	; repeat

	call PIT.init
	call PIT.wait

frame_loop:
	; call Frame.get
	; call Buffer.update
	; call Buffer.swap
	; call PIT.wait
	; jmp frame_loop

.test_VRAM:
	mov rsi, [rbx + SIS_VRAM]
	mov ecx, [rbx + SIS_ScreenWidth]
	mov eax, [rbx + SIS_ScreenHeight]
	mul ecx
	mov ecx, eax

.loop:
	mov r12d, [BLUE]
	mov dword [rsi], r12d
	add rsi, 4
	loop .loop

	add byte [BLUE], 1
	add byte [RED], 1
	add byte [GREEN], 1

.wait:
	call PIT.wait
	jmp .test_VRAM

	cli
	hlt

BLUE  db 255
GREEN db 255
RED   db 255
reserved db 0

SystemInfoStruct dq 0

%include "src/pit.asm"
%include "src/frame.asm"
%include "src/buffer.asm"
