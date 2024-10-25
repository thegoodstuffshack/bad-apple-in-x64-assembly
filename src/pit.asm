RELOAD_VALUE equ 0x9B84 ; ~29.97Hz

PIT:
.init:
	cli
	mov al, 0b00110100	; channel 0, lobyte/hibyte, mode 2, binary
	out 0x43, al		; send to PIT controller
	
	mov ax, RELOAD_VALUE
	out 0x40, al
	mov al, ah
	out 0x40, al
	sti
ret

; ; using status latch
; .wait: ; should work so long as the wait loop can check at least once per count
; 	cli
; .w1:
; 	mov al, 0b11100010 ; latch status, channel 0
; 	out 0x43, al
; 	in al, 0x40
; 	and al, 0b10000000
; 	jz .w1
; 	sti
; ret

; using count
.wait: ; doesnt latch the count, however should still work, not ideal and can get stuck
	cli
	in al, 0x40
	mov cl, al
	in al, 0x40
	mov ch, al
	mov dx, cx
	inc dx

.w1:
	cmp cx, dx
	jae .tick

	in al, 0x40
	mov cl, al
	in al, 0x40
	mov ch, al
	jmp .w1

.tick:
	sti
ret