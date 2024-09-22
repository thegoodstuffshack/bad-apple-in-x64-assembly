
FRAME_BYTE_SIZE equ 0

Frame: ; use uefi file protocol, assume folder contains valid frame files (correct size, etc.)
.get:
	push rbx

	; EFI_FILE_PROTOCOL.Open()
	lea rcx, [rbx + SIS_DriveRoot]
	lea rdx, [FrameFileProtocol] ; EFI_FILE_PROTOCOL
	lea r8, [FrameFileName]
	mov r9, 1 ; READ
	push qword 0
	sub rsp, 32
	mov rax, [rcx]
	call [rax + 8] ; Open
	cmp rax, 0
	jne $
	add rsp, 40

	; EFI_FILE_PROTOCOL.Read()
	; mov rcx, [FrameFileProtocol]
	; lea rdx, [FrameByteSize]
	; mov r8, Current_Frame
	; mov rax, [DRIVE_Root]
	; call [rax + 4*8] ; Read
	; cmp rax, EFI_ERR_SUCCESS
	; jne error_print
	; add rsp, 32

	; EFI_FILE_PROTOCOL.Close()

	cli
	hlt

	pop rbx
ret

.updateFileName:


FrameFileProtocol dq 0
FrameFileName dw __utf16__ `Bad_Apple_Frame 00000\0`
FrameByteSize dq FRAME_BYTE_SIZE

Current_Frame:
resb FRAME_BYTE_SIZE