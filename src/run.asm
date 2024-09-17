[bits 64]
[default rel]
jmp start

signature: db 'BadApple'

; pointer to struct in rbx -- need to update as needed
; SystemInfoStruct {
;	UINT64	Size
;	VOID*	SystemTable
;	VOID*	GOP_Interface
;	VOID*	VRAM
;	UINT32	ScreenWidth
;	UINT32	ScreenHeight
;	...
; }


start:
	; make/find frame buffer
	; edit frame buffer
	; swap buffers
	; repeat

.test_VRAM:
	mov rsi, [rbx + 3*8]
	mov ecx, [rbx + 4*8]
	shl ecx, 7
.loop:
	mov dword [rsi], 0x0000FF00
	add rsi, 4
	loop .loop

	cli
	hlt

SystemInfoStruct dq 0
