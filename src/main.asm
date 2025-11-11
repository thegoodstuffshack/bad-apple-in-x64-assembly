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
;	VOID*	FrameBuffer
;	...
; }

SIS dq 0

SIS_Size 			equ 0
SIS_SystemTable 	equ 8
SIS_VRAM 			equ 16
SIS_ScreenWidth 	equ 24
SIS_ScreenHeight 	equ 28
SIS_FrameData 		equ 32
SIS_FrameDataSize 	equ 40
SIS_FrameBuffer		equ 48


start:
    cli

    mov [SIS], rbx

    call setup_gdt
    call remap_pic
    call setup_idt

    mov al, PIT_CHANNEL_0 | PIT_ACCESS_LOHI | PIT_OPMODE_2 | PIT_DIGIT_BIT
    mov bx, 0x9B84 ; 29.97 Hz
    call program_pit

    sti

.halt:
    hlt
    jmp .halt

    ; temporarily load the entire video into memory in order to test the buffer and pit,
    ; then implement a driver to read the files off a drive

frame_loop:
    call Buffer.update
    call Buffer.swap

    sub qword [frameCounter], 1
    jz .end

    ret

.end:
    cli
    hlt

frameCounter dq 6562

%include "src/frame.asm"
%include "src/buffer.asm"
%include "src/gdt.asm"
%include "src/pic.asm"
%include "src/idt.asm"
%include "src/pit.asm"
