[bits 64]
[default rel]
jmp start

signature: db 'BadApple'

; pointer to struct given in rbx -- need to update struct as needed
; SystemInfoStruct {
;	UINT64	Size
;	VOID*	SystemTable
;	VOID*	GOP_Interface
;	VOID*	VRAM
;	UINT32	ScreenWidth
;	UINT32	ScreenHeight
;	...
; }

SIS_Size 			equ 0
SIS_SystemTable 	equ 8
SIS_GOP_Interface 	equ 16
SIS_VRAM 			equ 24
SIS_ScreenWidth 	equ 32
SIS_ScreenHeight 	equ 36


start:
	; make/find frame buffer
	; edit frame buffer
	; swap buffers
	; repeat


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
	
	xor eax, eax
.wait:
	inc eax
	cmp eax, 0x1000000
	jne .wait

	jmp .test_VRAM

	cli
	hlt

BLUE  db 255
GREEN db 255
RED   db 255
reserved db 0

SystemInfoStruct dq 0
