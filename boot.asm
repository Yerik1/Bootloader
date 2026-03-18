BITS 16
ORG 7C00h

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 7C00h
    sti

    mov [boot_drive], dl

    ; limpiar pantalla texto
    mov ax, 0600h
    mov bh, 07h
    mov cx, 0000h
    mov dx, 184Fh
    int 10h

    mov si, msg_boot
    call print_string

    ; leer stage.bin desde sector 2
    mov ah, 02h
    mov al, 32              ; cantidad de sectores a cargar
    mov ch, 0
    mov cl, 2
    mov dh, 0
    mov dl, [boot_drive]
    mov bx, 7E00h
    int 13h
    jc disk_error

    jmp 0000h:7E00h

disk_error:
    mov si, msg_err
    call print_string
.hang:
    jmp .hang

print_string:
.next:
    lodsb
    cmp al, 0
    je .done
    mov ah, 0Eh
    mov bh, 00h
    mov bl, 07h
    int 10h
    jmp .next
.done:
    ret

msg_boot db 'Bootloader: cargando juego...', 0
msg_err  db 13,10,'Error leyendo disco.',0
boot_drive db 0

times 510-($-$$) db 0
dw 0AA55h
