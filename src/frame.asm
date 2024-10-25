pixelScale equ 6
width equ 80 ; max value 4096-16 -- needs to be divisible by 16
height equ 40; max value 4096-16
FRAME_BYTE_SIZE equ width * height / 8
pixelOnColour equ 0x00FF00FF ; white
pixelOffColour equ 0x0000FF00 ; black

Frame:
.get:
	push rbx

; https://wiki.osdev.org/ATA_PIO_Mode
; https://en.wikipedia.org/wiki/Design_of_the_FAT_file_system 

	pop rbx
ret
.updateFileName:

; IN rdi: *buffer
printFrame: ; for now, the frame is uncompressed
	; mov rdi, [rbx + SIS_VRAM]
	mov rsi, [rbx + SIS_FrameData]
	mov eax, [frameCounter]
	mov edx, FRAME_BYTE_SIZE
	mul edx
	add rsi, rax
	mov r9w, width / 16
	mov r10w, height

.word_loop:
	mov ax, [rsi]
	mov cl, 15
	mov r11w, ax

.bit_loop:
	shr ax, cl
	and ax, 1
	mov ax, r11w
	mov r8d, pixelOffColour
	jz .off
.on:
	mov r8d, pixelOnColour
.off:
	mov ch, pixelScale
.applyPixelWidthScale:
	mov [rdi], r8d
	add rdi, 4
	sub ch, 1
	jnz .applyPixelWidthScale

	dec cl
	cmp cl, -1
	jne .bit_loop
	
	add rsi, 2
	sub r9w, 1
	jnz .word_loop

.height_change:
	push rsi
	mov r9w, width / 16
	mov r8b, pixelScale
	movzx rax, word [rbx + SIS_ScreenWidth]
	shl rax, 2
.applyPixelHeightScale:
	sub r8b, 1
	jz .skip
	mov rcx, width * pixelScale * 4
	sub rdi, rcx
	mov rsi, rdi
	mov rdx, rsi
	add rdi, rax

	rep movsb ; copy vram down a row
	mov rsi, rdx
	jmp .applyPixelHeightScale

.skip:
	sub rdi, width * pixelScale * 4
	add rdi, rax

	pop rsi
	sub r10w, 1
	jnz .word_loop

.end:
	ret
