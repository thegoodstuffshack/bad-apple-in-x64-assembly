[BITS 64]
M_OFFS equ 0x00100000
[org M_OFFS]

section .header

; see https://learn.microsoft.com/en-us/windows/win32/debug/pe-format
MS_DOS_HEADER:
	dw 0x5A4D 		; magic number 'MZ'
	times 58 db 0	; rest of the header can remain as zeroes
	dd 0x00000080 	; address of PE_HEADER start (at signature)

PE_HEADER:
	times 64 db 0	; MS-DOS_STUB, can leave blank
	dd 0x00004550	; Signature, "PE\0\0"
COFF_FILE_HEADER:
	dw 0x8664		; machine type: x64
	dw 2			; number of sections (.text .data)
	dd 0x66CA7400	; unix epoch time of creation
	dd 0			; symbol table deprecated for images
	dd 0			; no symbols in symbol table
	dw OPTIONAL_HEADER_SIZE
	dw 0x1202 		; system file, debug stripped, exe image

OPTIONAL_HEADER:
	dw 0x020b		; PE32+
	dw 0			; linker version
	dd SIZEOFALLTEXTSECTIONS
	dd SIZEOFALLDATASECTIONS
	dd SIZEOFALLBSSSECTIONS
	dd start-M_OFFS	; entry point address
	dd start-M_OFFS	; relative offset of entry point in memory (same as entry point)
	dq M_OFFS		; image base, desired offset in memory (see org)
	SECT_AL equ 1024
	dd SECT_AL	; section alignment - write decimal as hex
	dd SECT_AL	; file alignment    - write decimal as hex
	times 16 db 0	; os, image and subsystem version, 4 bytes reserved
	dd SECT_AL+SIZEOFALLTEXTSECTIONS+SIZEOFALLDATASECTIONS+SIZEOFALLBSSSECTIONS	; image size
	dd SECT_AL		; size of headers, rounded to multiple of file alignment
	dd 0			; checksum, not required
	dw 10			; subsystem: EFI application
	dw 0			; dll characteristics (N/A)
	dq 0x10000		; size of stack reserve
	dq 0x10000		; size of stack commit
	dq 0x10000		; size of heap reserve
	dq 0			; size of heap commit
	dd 0			; reserved (loader flags)
	dd 0			; number of RVA and sizes
OPTIONAL_HEADER_END:
OPTIONAL_HEADER_SIZE equ OPTIONAL_HEADER_END - OPTIONAL_HEADER

SIZEOFALLTEXTSECTIONS equ SECT_AL
SIZEOFALLDATASECTIONS equ 5*SECT_AL
SIZEOFALLBSSSECTIONS  equ 0

SECTION_TABLE:
.1:
	dq `.text`
	dd SECT_AL
	dd SECT_AL
	dd SECT_AL
	dd SECT_AL
	dd 0
	dd 0
	dw 0
	dw 0
	dd 0xE00000E0	; section has everything, can be executed, read and written
.2:
	dq `.data`
	dd SECT_AL
	dd 2*SECT_AL
	dd SECT_AL
	dd 2*SECT_AL
	dd 0
	dd 0
	dw 0
	dw 0
	dd 0xC0000040	; section has init data, can be read and written

times SECT_AL - ($-$$) db 0


section .text follows=.header

	NULL equ 0

start:
	sub rsp, 8 ; align stack to 64

	mov [EFI_Handle], rcx
	mov [EFI_SystemTable], rdx

	mov rcx, [rdx + EFI_OFFS_BootServices]
	mov [EFI_BootServices], rcx
	mov rdx, [rcx + EFI_OFFS_RuntimeServices]
	mov [EFI_RuntimeServices], rdx

	; Boot Services
	mov rdx, [rcx + EFI_OFFS_AllocPool]
	mov [EFI_AllocPool], rdx
	mov rdx, [rcx + EFI_OFFS_FreePool]
	mov [EFI_FreePool], rdx
	mov rdx, [rcx + EFI_OFFS_STALL]
	mov [EFI_Stall], rdx

	; ConOut
	mov rcx, [EFI_SystemTable]
	mov rdx, [rcx + EFI_OFFS_ConOut]
	mov [EFI_ConOut], rdx
	mov rcx, [rdx + EFI_ConOut_Output]
	mov [EFI_PrintString], rcx

.test_print:
	sub rsp, 32
	mov rcx, [EFI_ConOut]
	lea rdx, [text.test_string]
	call [EFI_PrintString]
.stall:
	mov rcx, 500000 ; 1 sec
	call [EFI_Stall]
	add rsp, 32

.load_program:
; EFI_BOOT_SERVICES.OpenProtocol()
	mov rcx, [EFI_Handle]
	lea rdx, [EFI_GUID_LOADED_IMAGE_PROTOCOL]
	lea r8, [DRIVE_Handle]
	mov r9, [EFI_Handle]
	push qword 1 ; EFI_OPEN_PROTOCOL_BY_HANDLE_PROTOCOL
	sub rsp, 40
	mov rax, [EFI_BootServices]
	call [rax + EFI_OFFS_OpenProtocol]
	cmp rax, EFI_ERR_SUCCESS
	jne error_print
	add rsp, 48

; EFI_BOOT_SERVICES.OpenProtocol()
	mov rcx, [DRIVE_Handle]
	mov rcx, [rcx + 24]
	lea rdx, [EFI_GUID_SIMPLE_FILE_SYSTEM_PROTOCOL]
	lea r8, [EFI_SFSP] ; EFI_SIMPLE_FILE_SYSTEM_PROTOCOL
	mov r9, [EFI_Handle]
	push qword 1 ; EFI_OPEN_PROTOCOL_BY_HANDLE_PROTOCOL
	sub rsp, 40
	mov rax, [EFI_BootServices]
	call [rax + EFI_OFFS_OpenProtocol]
	cmp rax, EFI_ERR_SUCCESS
	jne error_print
	add rsp, 16

; EFI_SIMPLE_FILE SYSTEM_PROTOCOL.OpenVolume()
	mov rcx, [EFI_SFSP]
	lea rdx, [DRIVE_Root] ; get EFI_FILE_PROTOCOL
	mov rax, [EFI_SFSP]
	call [rax + 8] ; OpenVolume
	cmp rax, EFI_ERR_SUCCESS
	jne error_print
	add rsp, 32

; EFI_FILE_PROTOCOL.Open()
	mov rcx, [DRIVE_Root]
	lea rdx, [DRIVE_ProgramFile] ; EFI_FILE_PROTOCOL
	lea r8, [ProgramFileName]
	mov r9, 1 ; READ
	push qword NULL
	sub rsp, 32
	mov rax, [DRIVE_Root]
	call [rax + 8] ; Open
	cmp rax, EFI_ERR_SUCCESS
	jne error_print
	add rsp, 8

; get file info - EFI_FILE_PROTOCOL.GetInfo()
.try_again_GI:
	mov rcx, [DRIVE_ProgramFile]
	lea rdx, [EFI_GUID_FILE_INFO_ID]
	lea r8, [DRIVE_InfoBufferSize]
	mov r9, [DRIVE_InfoBuffer]
	mov rax, [DRIVE_Root]
	call [rax + 8*8] ; GetInfo
	cmp eax, EFI_ERR_BUFFER_TOO_SMALL
	je .alloc_GI
	cmp rax, EFI_ERR_SUCCESS
	jne error_print
	jmp .skip_GI

.alloc_GI:
	mov rdx, [DRIVE_InfoBufferSize]
	lea r8, [DRIVE_InfoBuffer]
	call allocPool
	cmp rax, EFI_ERR_SUCCESS
	jne error_print
	jmp .try_again_GI

.skip_GI:
; get file size
	mov rdx, [DRIVE_InfoBuffer]
	mov rdx, [rdx + 8] ; FileSize
	mov [ProgramFileSize], rdx

; get buffer for program
	lea r8, [ProgramFilePtr]
	call allocPool
	cmp rax, EFI_ERR_SUCCESS
	jne error_print

; EFI_FILE_PROTOCOL.Read()
	mov rcx, [DRIVE_ProgramFile]
	lea rdx, [ProgramFileSize]
	mov r8, [ProgramFilePtr]
	mov rax, [DRIVE_Root]
	call [rax + 4*8] ; Read
	cmp rax, EFI_ERR_SUCCESS
	jne error_print
	add rsp, 32

; free memory
	mov rcx, [DRIVE_InfoBuffer]
	sub rsp, 32
	call [EFI_FreePool]
	cmp rax, EFI_ERR_SUCCESS
	jne error_print
; close file -- close both jic
	mov rcx, [DRIVE_ProgramFile]
	mov rax, [DRIVE_Root]
	call [rax + 2*8] ; Close
	cmp rax, EFI_ERR_SUCCESS
	jne error_print
	mov rcx, [DRIVE_Root]
	mov rax, rcx
	call [rax + 2*8] ; Close
	cmp rax, EFI_ERR_SUCCESS
	jne error_print
	add rsp, 32

; check file
	mov rcx, [ProgramFilePtr]
	mov rcx, [rcx + 2]
	cmp rcx, [ProgramSignature]
	je .exit_boot_services

	sub rsp, 32
	mov rcx, [EFI_ConOut]
	lea rdx, [text.FILE_ERROR]
	call [EFI_PrintString]
	jmp $

.exit_boot_services:
	lea rcx, [EFI_MM_MapSize]
	mov rdx, [EFI_MemoryMap]
	lea r8, [EFI_MM_MapKey]
	lea r9, [EFI_MM_DescVer]
	push r9
	lea r9, [EFI_MM_DescSize]
	sub rsp, 32
	mov rdi, [EFI_MM_MapSize]
	mov rax, [EFI_BootServices]
	lea rax, [rax + EFI_OFFS_GetMemoryMap]
	call [rax] ; IN/OUT (UINT* MapSize), OUT (*MemoryMap, UINT* MapKey, UINT* DescriptorSize, UINT32* DescriptorVersion)

	add rsp, 40
	cmp eax, EFI_ERR_BUFFER_TOO_SMALL
	je .alloc_MemoryMap
	cmp rax, EFI_ERR_SUCCESS
	je .continue
	jmp error_print

.alloc_MemoryMap:
	mov rdx, [EFI_MM_DescSize]
	shl rdx, 1
	add rdx, [EFI_MM_MapSize]
	lea r8, [EFI_MemoryMap]
	call allocPool
	cmp rax, EFI_ERR_SUCCESS
	je .exit_boot_services
	jmp error_print

.continue:
	mov rcx, [EFI_Handle]
	mov rdx, [EFI_MM_MapKey]
	sub rsp, 32
	mov rax, [EFI_BootServices]
	lea rax, [rax + EFI_OFFS_ExitBootServices] ;  IN (*Handle, UINTN MapKey)
	call [rax]
	add rsp, 32
	cmp rax, EFI_ERR_SUCCESS
	jne error_print

end: ; transfer control to program
	mov rax, [ProgramFilePtr]
	jmp rax


; IN rdx: size
; OUT r8: **
; Returns rax: EFI_STATUS
allocPool:
	mov rcx, 1 ; type EFI_LOADER_DATA
	sub rsp, 32
	call [EFI_AllocPool]
	add rsp, 32
	ret

error_print:
	push rax
	sub rsp, 32
	mov rcx, [EFI_ConOut]
	lea rdx, [text.error_string]
	call [EFI_PrintString]
	add rsp, 32
	pop rax
	jmp $

times SECT_AL - ($-start) db 0


section .data follows=.text
data:
text:  ; each char becomes 00xxh when __utf16__ (uefi standard)
	.test_string: dw __utf16__ `Hello World!\r\n\0`
	.error_string: dw __utf16__ `ERROR: Check RAX!\r\n\0`
	.FILE_ERROR: dq __utf16__ `The program signature does not match\r\n\0`

; see https://uefi.org/sites/default/files/resources/UEFI_Spec_2_10_A_Aug8.pdf
	EFI_Handle		dq 0
	EFI_SystemTable	dq 0

	EFI_BootServices 	dq 0
	EFI_RuntimeServices dq 0
	EFI_ConOut			dq 0

	EFI_AllocPool		dq 0	; IN (UINT MemoryType, UINT size), OUT (**Buffer)
	EFI_FreePool		dq 0	; IN (*Buffer)
	EFI_Stall			dq 0	; IN (UINT micro seconds)
	EFI_PrintString		dq 0	; IN (*ConOut, *String)

	; Memory Map (MM) -- may need to copy map elsewhere
	EFI_MemoryMap	dq 0
	EFI_MM_MapSize	dq 0
	EFI_MM_MapKey	dq 0
	EFI_MM_DescSize dq 0
	EFI_MM_DescVer	dq 0

	; Drive Protocol
	DRIVE_Handle		dq 0
	DRIVE_Root			dq 0
	EFI_SFSP			dq 0 ; simple file system protocol
	DRIVE_ProgramFile	dq 0
	DRIVE_InfoBufferSize dq 0
	DRIVE_InfoBuffer	dq 0
	
	; Program Stuff
	ProgramFilePtr   dq 0
	ProgramFileSize  dq 0
	ProgramFileName  dw __utf16__ `\\programs\\bad-apple.bin\0`
	ProgramSignature db 'BadApple'

	; GUIDs
	EFI_GUID_LOADED_IMAGE_PROTOCOL: dd 0x5B1B31A1
	dw 0x9562,0x11d2
    db 0x8E,0x3F,0x00,0xA0,0xC9,0x69,0x72,0x3B
	EFI_GUID_SIMPLE_FILE_SYSTEM_PROTOCOL: dd 0x0964e5b22 
	dw 0x6459,0x11d2
	db 0x8e,0x39,0x00,0xa0,0xc9,0x69,0x72,0x3b
	EFI_GUID_FILE_INFO_ID: dd 0x09576e92
	dw 0x6d3f,0x11d2
	db 0x8e,0x39
	db 0x00,0xa0,0xc9,0x69,0x72,0x3b


.offsets:
	; System Table
	EFI_OFFS_ConOut 			equ 64
	EFI_OFFS_RuntimeServices	equ 88
	EFI_OFFS_BootServices		equ 96

	; Boot Services
	EFI_OFFS_GetMemoryMap		equ 56
	EFI_OFFS_AllocPool			equ 64
	EFI_OFFS_FreePool			equ 72
	EFI_OFFS_ExitBootServices	equ 232
	EFI_OFFS_STALL 				equ 248
	EFI_OFFS_OpenProtocol		equ 280
	EFI_OFFS_CloseProtocol		equ 288
	EFI_OFFS_LocateHandleBuffer	equ 312

	; ConOut
	EFI_ConOut_Output			equ 8

.exit_codes:
	EFI_ERR_SUCCESS				equ 0
	EFI_ERR_BUFFER_TOO_SMALL	equ 5

times SECT_AL - ($-data) db 0
