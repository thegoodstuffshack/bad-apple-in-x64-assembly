
RELOAD_VALUE equ 0x9B5C ; 30Hz

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

.wait: ; should work so long as the wait loop can check at least once per count
	cli
.w1:
	mov al, 0b11100010 ; latch status, channel 0
	out 0x43, al
	in al, 0x40
	and al, 0b10000000
	jz .w1
	sti
ret
