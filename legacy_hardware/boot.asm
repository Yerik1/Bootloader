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

    mov si, msg_boot
    call print_string

    mov ah, 41h
    mov bx, 55AAh
    mov dl, [boot_drive]
    int 13h
    jc no_extensions
    cmp bx, 0AA55h
    jne no_extensions

    mov si, dap_packet
    mov ah, 42h
    mov dl, [boot_drive]
    int 13h
    jc disk_error

    jmp 0000h:7E00h

no_extensions:
    mov si, msg_noext
    call print_string
    jmp halt

disk_error:
    mov si, msg_err
    call print_string
    jmp halt

halt:
    cli
.hang:
    hlt
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

boot_drive db 0

msg_boot   db 13,10,'Legacy MBR: cargando stage...',13,10,0
msg_err    db 13,10,'Error leyendo stage por LBA.',13,10,0
msg_noext  db 13,10,'BIOS sin INT13h extensions.',13,10,0

dap_packet:
    db 10h
    db 00h
    dw 3
    dw 7E00h
    dw 0000h
    dq 1

times 446-($-$$) db 0

    db 80h
    db 00h, 02h, 00h
    db 0Eh
    db 0FFh, 0FFh, 0FFh
    dd 1
    dd 4

times 16*3 db 0

dw 0AA55h
