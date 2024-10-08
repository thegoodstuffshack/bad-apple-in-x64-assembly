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
	; make/find frame buffer
	; edit frame buffer
	; swap buffers
	; repeat

	call PIT.init
	call PIT.wait

	; cli
	; hlt

; temporarily load the entire video into memory in order to test the buffer and pit,
; then implement a driver to read the files off a drive

frame_loop:
	call printFrame
	inc dword [frameCounter]
	cmp dword [frameCounter], 6562
	je .end
	; ; call Buffer.update
	; ; call Buffer.swap
	; ; jmp $
	call PIT.wait
	jmp frame_loop

; .test_VRAM:
; 	mov rsi, [rbx + SIS_VRAM]
; 	mov ecx, [rbx + SIS_ScreenWidth]
; 	mov eax, [rbx + SIS_ScreenHeight]
; 	mul ecx
; 	mov ecx, eax

; .loop:
; 	mov r12d, [BLUE]
; 	mov dword [rsi], r12d
; 	add rsi, 4
; 	loop .loop

; 	add byte [BLUE], 1
; 	add byte [RED], 1
; 	add byte [GREEN], 1

; .wait:
; 	call PIT.wait
; 	jmp .test_VRAM

.end:
	cli
	hlt

; BLUE  db 0
; GREEN db 0
; RED   db 0
; reserved db 0

; SystemInfoStruct dq 0
frameCounter dd 0

%include "src/pit.asm"
%include "src/frame.asm"
; %include "src/buffer.asm"
