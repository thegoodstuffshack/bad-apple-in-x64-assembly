[bits 64]
[default rel]
jmp start

signature: db 'BadApple'

start:
	; make/find frame buffer
	; edit frame buffer
	; swap buffers
	; repeat

	mov rax, -1
	mov rbx, -1
	mov rcx, -1
	mov rdx, -1




	cli
	hlt


