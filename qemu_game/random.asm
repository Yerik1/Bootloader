BITS 16

SCREEN_W        equ 320
SCREEN_H        equ 200

NAME_W          equ 124
NAME_H          equ 40

MARGIN_X        equ 4
MARGIN_Y        equ 4

X_RANGE         equ 188
Y_RANGE         equ 152

rand_seed       dw 0A53Ch

randomize_position:
    mov ah, 00h
    int 1Ah                    ; CX:DX = ticks

    ; -----------------------------------------
    ; Actualizar semilla con mezcla de tiempo
    ; seed = seed xor CX xor DX
    ; seed = seed + 0x9E37
    ; -----------------------------------------
    mov ax, [rand_seed]
    xor ax, cx
    xor ax, dx
    add ax, 09E37h
    mov [rand_seed], ax

    ; -----------------------------------------
    ; X = MARGIN_X + (seed % X_RANGE)
    ; -----------------------------------------
    xor dx, dx
    mov bx, X_RANGE
    div bx
    add dl, MARGIN_X
    mov [name_col], dl

    ; -----------------------------------------
    ; Nueva mezcla para Y
    ; ax = seed rotada y perturbada
    ; -----------------------------------------
    mov ax, [rand_seed]
    rol ax, 3
    add ax, 07123h
    xor ax, cx
    xor dx, dx
    mov bx, Y_RANGE
    div bx
    add dl, MARGIN_Y
    mov [name_row], dl

    ret
