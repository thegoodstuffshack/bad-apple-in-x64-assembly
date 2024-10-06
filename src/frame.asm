
FRAME_BYTE_SIZE equ 1280 * 800 / 4

Frame:
.get:
	push rbx

; https://wiki.osdev.org/ATA_PIO_Mode
; https://en.wikipedia.org/wiki/Design_of_the_FAT_file_system 

	pop rbx
ret
.updateFileName:


getFrame:
	mov rdi, [rbx + SIS_FrameData]
	

	mov rcx, [rdi + rsi]



ret


SIS_FrameData 		equ 32
SIS_FrameDataSize 	equ 40




FrameFileProtocol dq 0
FrameFileName dw __utf16__ `Bad_Apple_Frame 00000\0`
FrameByteSize dq FRAME_BYTE_SIZE

FrameBuffer:
; resb FRAME_BYTE_SIZE