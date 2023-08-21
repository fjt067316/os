org 0x7C00 ; 0x7C00 is a hardcoded offset we have no choice here
bits 16 ; tell assembler to make 16bit stuff because our processor uses it

%define ENDL 0x0D, 0x0A

start:
	jmp main

puts:
	push si
	push ax
	push bx

.loop 
	lodsb ; load byte from DS:SI into into al/ax/eax reg
	or al, al ; If al is 0 "or al, al" will cause the zero flag AF to be set to 1 
	jz .done ; if ZF is 1 jump done
	
	mov ah, 0x0E ; calls bios interrupt
	mov bh, 0 ; set page number to 0 (default gui setting idk dw about it)
	int 0x10 ; trigger softwarte interrupt number 0x10 -> then bios checks value in ah to see what subfunction to execute, 0x0E => print char in al reg to screen	

	jmp .loop ; else jump loop

.done
	pop ax
	pop bx
	pop si
	ret

main:
	; setup data variables
	mov ax, 0
	mov ds, ax ; canmt write to ds or es directly 
	mov es, ax

	; setup stack
	mov ss, ax
	mov sp, 0x7C00	


	; print message
	mov si, msg_hello
	call puts
	hlt

.halt:
	jmp .halt; infinate loop to halt


msg_hello db 'Hello', ENDL, 0

; last 2 bytes of first sector should be 0xAA55 
; we fill the other bytes with 0 by using db -> define bytes
; sector = 512B so we go to 510B and then write the 2 bytes 0xAA55 at the end
times 510-($-$$) db 0 ; $-$$ is the program length so far  
dw 0AA55h ; h to specify hex
