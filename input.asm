BITS 16

ACT_NONE        equ 0
ACT_START       equ 1
ACT_EXIT        equ 2
ACT_LEFT        equ 3
ACT_RIGHT       equ 4
ACT_UP          equ 5
ACT_DOWN        equ 6
ACT_RESTART     equ 7

SCAN_UP         equ 48h
SCAN_LEFT       equ 4Bh
SCAN_RIGHT      equ 4Dh
SCAN_DOWN       equ 50h

read_key_action:
    mov ah, 00h
    int 16h

    cmp al, 0
    jne .ascii_keys

    cmp ah, SCAN_LEFT
    je .ret_left

    cmp ah, SCAN_RIGHT
    je .ret_right

    cmp ah, SCAN_UP
    je .ret_up

    cmp ah, SCAN_DOWN
    je .ret_down

    mov al, ACT_NONE
    ret

.ascii_keys:
    cmp al, 0Dh
    je .ret_start

    cmp al, 's'
    je .ret_start
    cmp al, 'S'
    je .ret_start

    cmp al, 'y'
    je .ret_start
    cmp al, 'Y'
    je .ret_start

    cmp al, 'r'
    je .ret_restart
    cmp al, 'R'
    je .ret_restart

    cmp al, 'q'
    je .ret_exit
    cmp al, 'Q'
    je .ret_exit

    cmp al, 1Bh
    je .ret_exit

    mov al, ACT_NONE
    ret

.ret_start:
    mov al, ACT_START
    ret

.ret_exit:
    mov al, ACT_EXIT
    ret

.ret_left:
    mov al, ACT_LEFT
    ret

.ret_right:
    mov al, ACT_RIGHT
    ret

.ret_up:
    mov al, ACT_UP
    ret

.ret_down:
    mov al, ACT_DOWN
    ret

.ret_restart:
    mov al, ACT_RESTART
    ret
