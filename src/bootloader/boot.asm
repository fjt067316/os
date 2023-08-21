org 0x7C00 ; 0x7C00 is a hardcoded offset we have no choice here
bits 16 ; tell assembler to make 16bit stuff because our processor uses it

%define ENDL 0x0D, 0x0A

; FAT12 Header
; These values are copied from the fat12 header generated in the makefile that gets overwrittien
; https://wiki.osdev.org/FAT
jmp short start ; short jump to start of actual bootloader code (0x3C offset?)
nop

bdb_oem: 					db 'MSWIN4.1' ; 8 bytes -> could set this value to anythingI guess its not really used
bdb_bytes_per_sector: 		dw 512 
bdb_sectors_per_cluster: 	db 1
bdb_reserved_sectors: 		dw 1 ; start of disk is the reserved sector
bdb_fat_count:				db 2 ; number of fat tables 1/2 is normal
bdb_dir_entries_count: 		dw 0E0h
bdb_total_sectors: 			dw 2880 ; 2880*512 = 1.44mb
bdb_media_descriptor_type: 	db 0F0h ; 0x0F0 => 3.5" floppy disk
bdb_sectors_per_fat: 		dw 9 
bdb_sectors_per_track:		dw 18
bdb_heads:					dw 2
bdb_hidden_sector_count: 	dd 0
bdb_large_sector_count:		dd 0

; extended boot record
ebr_drive_number:			db 0 ;  value is pretty much useless?
							db 0 ; reserved byte idk its just needed
ebr_signature:				db 29h ; must be 28h or 29h idk why
ebr_volume_id: 				db 42h, 08h, 00h, 85h
ebr_volume_label: 			db 'sex machine' ; 11 byte string padded with spaces if its less
ebr_system_id:				db 'FAT12   ' ; 8 bytes padded

start:
	jmp main

puts:
	push si
	push ax
	push bx

.loop: 
	lodsb 			; load byte from DS:SI into into al/ax/eax reg
	or al, al 		; If al is 0 "or al, al" will cause the zero flag AF to be set to 1 
	jz .done 		; if ZF is 1 jump done
	
	mov ah, 0x0E 	; calls bios interrupt
	mov bh, 0 		; set page number to 0 (default gui setting idk dw about it)
	int 0x10 		; trigger softwarte interrupt number 0x10 -> then bios checks value in ah to see what subfunction to execute, 0x0E => print char in al reg to screen	

	jmp .loop 		; else jump loop

.done:
	pop bx
	pop ax
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


	; read data from floppy 
	mov [ebr_drive_number], dl
	mov ax, 1						; LBA = 1
	mov cl, 1						; 1 sector to read
	mov bx, 0x7E00					; data should be stored after the bootloader
	call disk_read

	; print message	
	mov si, msg_hello
	call puts
	cli
	hlt

; Error handlers
floppy_error:
	mov si, msg_read_failed
	call puts
	jmp wait_input_and_reboot

wait_input_and_reboot:
	mov ah, 0
	int 16h				; wait for keypress
	jmp 0FFFFh:0 		; jump to beginning of BIOS, should trigger reboot

.halt:
	cli 				; disable interrupts so we cant leave halt state
	hlt 
	; jmp .halt; infinate loop to halt


; Convert LBA (logical block addr) to CHS (cylinder head sector) address
; Params: 
; 	- ax: an LBA address
; Returns:
; 	- cx[5:0] -> sector number 1-indexed
; 	- cx[15:6] -> cylinder number
; 	- dh -> head number
;
; div word [bdb_heads] => puts quotient in ax, remainder in dx
;
lba_to_chs:
	push ax
	push dx

	xor dx, dx							; dx = 0
	div word [bdb_sectors_per_track]	; ax = LBA / sectors per track
	inc dx								; dx = (LBA % sector per track) +1 = sector num
	mov cx, dx							; cx = dx

	xor dx, dx							; dx = 0
	div word [bdb_heads]				; ax = (LBA/sectors per track) / heads = cylinder num

	mov dh, dl							; dh = head ie upper 8 bits dx reg
	mov ch, al 							; ch = cylinder (lower 8 bits ax)
	shl ah, 6
	or cl, ah							; put upper 2 bits of cylinder in cl

	pop ax
	mov dl, al
	pop ax
	ret

;
; Read sectors from disk
; Params:
;	- ax: LBA address
;	- cl: number of sectors to read 
;	- dl: drive number 
; 	- es:bx: memory addr where to store read data

disk_read:
	push ax
	push bx
	push cx 
	push dx
	push di

    push cx                             ; temporarily save CL (number of sectors to read)
    call lba_to_chs                     ; compute CHS
    pop ax                              ; AL = number of sectors to read
    
    mov ah, 02h
    mov di, 3      

.retry:
	pusha					; save all registers
	stc						; set carry flag
	int 13h					; if successfull the carry flag will be cleared
	jnc .done				; conditional jump if no carry

	; read failed
	popa
	call disk_reset
	dec di
	test di, di
	jnz .retry				; if di == 0 we have run out or retries

.fail:
	; done all attempts
	jmp floppy_error

.done:
	popa

	pop di
	pop dx
	pop cx 
	pop bx
	pop ax
	ret 

; Reset disk controller
; call interrupt 13 with ah = 0
; Params: 
;	dl: drive number
disk_reset:
	pusha
	mov ah, 0
	stc 				; set carry flag if successfull it will be set to 0 by int 13h
	int 13h
	jc floppy_error
	popa
	ret



msg_hello db 'Hello', ENDL, 0
msg_read_failed db 'Failed to read from floppy', ENDL, 0

; last 2 bytes of first sector should be 0xAA55 
; we fill the other bytes after assembly code with 0 by using db -> define bytes
; sector = 512B so we go to 510B and then write the 2 bytes 0xAA55 at the end
times 510-($-$$) db 0 ; $-$$ is the program length so far  
dw 0AA55h ; h to specify hex
