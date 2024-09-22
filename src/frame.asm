
FRAME_BYTE_SIZE equ 0

Frame:
.get:
	push rbx

; https://wiki.osdev.org/ATA_PIO_Mode
; https://en.wikipedia.org/wiki/Design_of_the_FAT_file_system 

	pop rbx
ret

.updateFileName:


FrameFileProtocol dq 0
FrameFileName dw __utf16__ `Bad_Apple_Frame 00000\0`
FrameByteSize dq FRAME_BYTE_SIZE

Current_Frame:
resb FRAME_BYTE_SIZE