Buffer:
.update:
    mov rbx, [SIS]
    mov rdi, [rbx + SIS_FrameBuffer]
    call printCompressedFrame
    ret

.swap:
    mov rbx, [SIS]
    mov rdi, [rbx + SIS_VRAM]
    mov rsi, [rbx + SIS_FrameBuffer]
    mov r8w, height * pixelScale 
    mov eax, [rbx + SIS_ScreenWidth]
    shl rax, 2
    sub rax, width * pixelScale * 4
    
    .loop:
    mov ecx, width * pixelScale * 4
    rep movsb

    add rsi, rax
    add rdi, rax

    sub r8w, 1
    jnz .loop
    ret
