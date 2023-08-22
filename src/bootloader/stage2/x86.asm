bits 16

section .text

global write_char

write_char:
    push bp
    mov bp, sp 
    
    mov ah, 0Eh
    mov al, [bp+4]
    mov bh, [bp+6]

    int 10h

    pop bx
    mov sp, bp
    pop bp
    ret