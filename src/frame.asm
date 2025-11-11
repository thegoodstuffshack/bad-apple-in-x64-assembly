pixelScale equ 2
width equ 640
height equ 400
pixelOnColour equ 0x00FFFFFF ; white
pixelOffColour equ 0x00000000 ; black

; Frame:
; .get:
; 	push rbx

; ; https://wiki.osdev.org/ATA_PIO_Mode
; ; https://en.wikipedia.org/wiki/Design_of_the_FAT_file_system 

; 	pop rbx
; ret
; .updateFileName:

; ; IN rdi: *buffer
; printFrame: ; for now, the frame is uncompressed
; 	; mov rdi, [rbx + SIS_VRAM]
; 	mov rsi, [rbx + SIS_FrameData]
; 	mov rax, [frameCounter]
; 	mov rdx, width * height / 8
; 	mul rdx
; 	add rsi, rax
; 	mov r9w, width / 16
; 	mov r10w, height

; .word_loop:
; 	mov ax, [rsi]
; 	mov cl, 15
; 	mov r11w, ax

; .bit_loop:
; 	shr ax, cl
; 	and ax, 1
; 	mov ax, r11w
; 	mov r8d, pixelOffColour
; 	jz .off
; .on:
; 	mov r8d, pixelOnColour
; .off:
; 	mov ch, pixelScale
; .applyPixelWidthScale:
; 	mov [rdi], r8d
; 	add rdi, 4
; 	sub ch, 1
; 	jnz .applyPixelWidthScale

; 	dec cl
; 	cmp cl, -1
; 	jne .bit_loop
    
; 	add rsi, 2
; 	sub r9w, 1
; 	jnz .word_loop

; .height_change:
; 	push rsi
; 	mov r9w, width / 16
; 	mov r8b, pixelScale
; 	xor rax, rax
; 	mov eax, dword [rbx + SIS_ScreenWidth]
; 	shl rax, 2
; .applyPixelHeightScale:
; 	sub r8b, 1
; 	jz .skip
; 	mov rcx, width * pixelScale * 4
; 	sub rdi, rcx
; 	mov rsi, rdi
; 	mov rdx, rsi
; 	add rdi, rax

; 	rep movsb ; copy vram down a row
; 	mov rsi, rdx
; 	jmp .applyPixelHeightScale

; .skip:
; 	sub rdi, width * pixelScale * 4
; 	add rdi, rax

; 	pop rsi
; 	sub r10w, 1
; 	jnz .word_loop

; .end:
; 	ret

; IN rdi: *buffer
printCompressedFrame:
    xor r9d, r9d
    xor rcx, rcx
    mov rsi, [rbx + SIS_FrameData]
    mov r11, [.currentFramePtrOff]
    xor r12, r12
    mov r12d, [rbx + SIS_ScreenWidth]
    shl r12d, 2
    sub r12d, width * pixelScale * 4

.loop_off:
    mov r8d, pixelOffColour
.loop_on:
    cmp rcx, width*height
    jae .end

; assuming first word block is always off, on and off word blocks alternate
    movzx rax, word [rsi + r11]
    add r11, 2

    or rax, rax
    jz .next

    add rcx, rax

.wordBlockLoop:
    mov r13w, pixelScale
.width_scaling:
    mov [rdi], r8d
    add rdi, 4
    sub r13w, 1
    jnz .width_scaling
    inc r9d
    cmp r9d, width
    jne .skip

    xor r9d, r9d
    mov r13w, pixelScale
    push rsi
    push rcx
    mov rsi, rdi
    sub rsi, width * pixelScale * 4
.height_scaling:
    add rdi, r12
    sub r13w, 1
    jz .finished_scaling
    mov rcx, width * pixelScale * 4
    rep movsb
    add rsi, r12
    jmp .height_scaling

.finished_scaling:
    pop rcx
    pop rsi
.skip:
    sub rax, 1
    jnz .wordBlockLoop

.next:
    cmp r8d, pixelOffColour
    jne .loop_off
    mov r8d, pixelOnColour
    jmp .loop_on

.end:
    mov [.currentFramePtrOff], r11
    ret

.currentFramePtrOff dq 0
