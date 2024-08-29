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
	mov rdx, [rcx + EFI_OFFS_GetMemoryMap]
	mov [EFI_GetMemoryMap], rdx
	mov rdx, [rcx + EFI_OFFS_AllocPool]
	mov [EFI_AllocPool], rdx
	mov rdx, [rcx + EFI_OFFS_ExitBootServices]
	mov [EFI_ExitBootServices], rdx
	mov rdx, [rcx + EFI_OFFS_STALL]
	mov [EFI_Stall], rdx

	; ConOut
	mov rcx, [EFI_SystemTable]
	mov rdx, [rcx + EFI_OFFS_ConOut]
	mov [EFI_ConOut], rdx
	mov rcx, [rdx + EFI_ConOut_Output]
	mov [EFI_PrintString], rcx


	; Get Memory Map
.Get_Memory_Map:
	lea rdx, [EFI_MemoryMap] ; first time use bogus pointer

.try_again_MM:
	lea rcx, [EFI_MM_MapSize]
	lea r8, [EFI_MM_MapKey]
	lea r9, [EFI_MM_DescVer]
	push r9
	lea r9, [EFI_MM_DescSize]
	sub rsp, 32
	call [EFI_GetMemoryMap]
	add rsp, 40
	cmp eax, EFI_ERR_BUFFER_TOO_SMALL
	jne .skip_alloc_MM

	mov rcx, [EFI_MM_DescSize]
	add [EFI_MM_MapSize], rcx
	add [EFI_MM_MapSize], rcx
	mov rdx, [EFI_MM_MapSize] ; required map size + new entry from this alloc
	mov rcx, 2 ; type EFI_LOADER_DATA
	lea r8, [EFI_MemoryMap]
	sub rsp, 32
	call [EFI_AllocPool]
	add rsp, 32
	cmp rax, EFI_ERR_SUCCESS
	jne error_print
	jmp .try_again_MM

.skip_alloc_MM:
	cmp rax, EFI_ERR_SUCCESS
	jne error_print

.test_print:
	sub rsp, 32
	mov rcx, [EFI_ConOut]
	lea rdx, [text.test_string]
	call [EFI_PrintString]
.stall:
	mov rcx, 1000000 ; 1 sec
	call [EFI_Stall]
	add rsp, 32

; CAN do stuff here before leaving loader

.load:
; EFI_BOOT_SERVICES.LocateHandleBuffer()
	mov rcx, DRIVE_Handle
	mov rdx, NULL
	mov r8, NULL
	lea r9, [DRIVE_HandleBuffer]
	push r9
	lea r9, [NOHANDLES]
; EFI_BOOT_SERVICES.HandleProtocol()
; EFI_FILE_PROTOCOL.Open()
; EFI_FILE_PROTOCOL.Read()
; EFI_LOAD_FILE2_PROTOCOL.LoadFile()
; 


.exit_boot_services:
	lea rcx, [EFI_MM_MapSize]
	lea rdx, [EFI_MemoryMap]
	lea r8, [EFI_MM_MapKey]
	lea r9, [EFI_MM_DescVer]
	push r9
	lea r9, [EFI_MM_DescSize]
	sub rsp, 32
	mov rdi, [EFI_MM_MapSize]
	call [EFI_GetMemoryMap]
	add rsp, 40
	cmp eax, EFI_ERR_BUFFER_TOO_SMALL
	je .exit_boot_services
	cmp rax, EFI_ERR_SUCCESS
	jne error_print

	mov rcx, [EFI_Handle]
	mov rdx, [EFI_MM_MapKey]
	sub rsp, 32
	call [EFI_ExitBootServices]
	add rsp, 32
	cmp rax, EFI_ERR_SUCCESS
	jne error_print

	; free memory map (maybe)

end: ; transfer control to kernel
	jmp $ ; or ret to close


error_print:
	push rax
	sub rsp, 32
	mov rcx, [EFI_ConOut]
	lea rdx, [text.error_string]
	call [EFI_PrintString]
	add rsp, 32
	pop rax
	jmp $

text:
	.test_string: dw __utf16__ `Hello World!\r\n\0` ; each char becomes 00xxh
	.error_string: dw __utf16__ `ERROR: Check RAX!\r\n\0` ; each char becomes 00xxh

times SECT_AL - ($-start) db 0


section .data follows=.text
data:
; see https://uefi.org/sites/default/files/resources/UEFI_Spec_2_10_A_Aug8.pdf
	EFI_Handle		dq 0
	EFI_SystemTable	dq 0

	EFI_BootServices 	dq 0
	EFI_RuntimeServices dq 0
	EFI_ConOut			dq 0

	EFI_GetMemoryMap	dq 0	; IN/OUT (UINT* MapSize), OUT (*MemoryMap, UINT* MapKey, UINT* DescriptorSize, UINT32* DescriptorVersion)
	EFI_AllocPool		dq 0	; IN (UINT MemoryType, UINT size), OUT (**Buffer)
	EFI_ExitBootServices dq 0	; IN (*Handle, UINT MapKey)
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
	DRIVE_HandleBuffer	dq 0

.offsets:
	; System Table
	EFI_OFFS_ConOut 			equ 64
	EFI_OFFS_RuntimeServices	equ 88
	EFI_OFFS_BootServices		equ 96

	; Boot Services
	EFI_OFFS_GetMemoryMap		equ 56
	EFI_OFFS_AllocPool			equ 64
	EFI_OFFS_ExitBootServices	equ 232
	EFI_OFFS_STALL 				equ 248

	; ConOut
	EFI_ConOut_Output			equ 8

.exit_codes:
	EFI_ERR_SUCCESS				equ 0
	EFI_ERR_BUFFER_TOO_SMALL	equ 5

times SECT_AL - ($-data) db 0
