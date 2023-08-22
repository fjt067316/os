bits 16

section .entry

extern kmain
global entry


entry:
    cli
    ; setup stack
    mov ax, ds
    mov ss, ax
    mov sp, 0
    mov bp, sp
    sti

    ; expect boot drive in dl, send it as argument to cstart function
    push 60
    push 9
    call kmain

    cli
    hlt