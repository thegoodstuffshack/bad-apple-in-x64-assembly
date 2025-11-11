; idt.asm
;
; https://wiki.osdev.org/Interrupt_Descriptor_Table


IDT_SIZE equ 256 * 16 ; 256 entries each 16 bytes long
DEFAULT_SEGMENT_SELECTOR equ 0x8 ; rpl 0, gdt, kernel mode cs (0x8)
IDT_GATETYPE_INTERRUPT equ 0xE
IDT_GATETYPE_TRAP equ 0xF


;
setup_idt:
    call add_idt_entries

    ; load new idt
    lea rax, [idt]
    push rax
    push word IDT_SIZE - 1
    lidt [rsp]
    add rsp, 10

.end:
    ret


add_idt_entries:
    ; add unhandled interrupts
    xor r8, r8
    lea rax, [general_protection_handler] ; general protection
    mov bx, DEFAULT_SEGMENT_SELECTOR
    mov cl, IDT_GATETYPE_INTERRUPT
    xor dl, dl
.loop:
    call add_idt_entry
    add r8, 0x10
    cmp r8, 31 * 16 + 0x10
    jne .loop

    mov bx, DEFAULT_SEGMENT_SELECTOR
    mov cl, IDT_GATETYPE_INTERRUPT
    xor dl, dl
    lea rax, [pit_interrupt_handler]
    mov r8, (PIC_MASTER_IRQ_VECTOR + 0) * 16 ; irq0
    call add_idt_entry ; IRQ0 pit_interrupt_handler

.end:
    ret

; all ISTs zero for now
; IN rax: offset
; IN bx: segment selector
; IN cl: gate type
; IN dl: DPL
; IN r8: idt entry offset
add_idt_entry:
    push rax
    push bx
    push cx
    push dx

    mov r9d, eax ; offset bits 15:0
    and r9d, 0x0000FFFF

    shl ebx, 16 ; segment selector
    or r9d, ebx

    and rcx, 0xF ; gate type
    shl rcx, 40
    or r9, rcx

    and rdx, 0x3 ; DPL
    or rdx, 0x4 ; present bit
    shl rdx, 45
    or r9, rdx

    mov r10, rax
    shr r10, 16 ; offset bits 16:31
    shl r10, 48
    or r9, r10

    lea rbx, [idt] ; add entry
    mov [rbx + r8], r9
    shr rax, 32 ; offset bits 32:63
    mov [rbx + r8 + 8], rax

.end:
    pop dx
    pop cx
    pop bx
    pop rax
    ret


;
general_protection_handler:
    mov rdi, [SIS]
    mov rdi, [rdi + SIS_VRAM]
    lea rbx, [gp_interrupt_string]
    ; call printstring
    mov rax, 0xFEFEFECECECE
    hlt


gp_interrupt_string: db "this interrupt was eaten", 0

    align 16
idt: times IDT_SIZE db 0
