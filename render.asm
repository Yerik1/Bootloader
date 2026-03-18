BITS 16

ORIENT_NORMAL   equ 0
ORIENT_LEFT     equ 1
ORIENT_RIGHT    equ 2
ORIENT_UP       equ 3
ORIENT_DOWN     equ 4

VGA_SEG         equ 0A000h
SCREEN_W        equ 320
SCREEN_H        equ 200
LETTER_SCALE    equ 1
LETTER_W        equ 16      ; 8 * scale
LETTER_H        equ 16
LETTER_ADV      equ 18      ; 16 + 2 px espacio
WORD_GAP        equ 10

msg_title       db 'MY NAME BOOTEABLE', 0
msg_confirm1    db 'ENTER/S/Y = iniciar', 0
msg_confirm2    db 'Q o ESC   = salir', 0
msg_confirm3    db 'En juego: Flechas transforman, R reinicia', 0
msg_confirm4    db 'En juego: Q o ESC salen', 0
msg_names       db 'Nombres: Yerik y Gabriel', 0

base_x          dw 0
base_y          dw 0
curr_x          dw 0
curr_y          dw 0
row_idx         db 0
col_idx         db 0
bitmap_row_idx  db 0
row_bits        db 0
shift_count     db 0
pre_row         db 0
pre_col         db 0
rot_row         db 0
rot_col         db 0

; =========================================================
; MODO TEXTO
; =========================================================
set_mode_text:
    mov ax, 0003h
    int 10h
    ret

clear_screen_text:
    mov ax, 0600h
    mov bh, 07h
    mov cx, 0000h
    mov dx, 184Fh
    int 10h

    mov dh, 0
    mov dl, 0
    call text_set_cursor
    ret

text_set_cursor:
    mov ah, 02h
    mov bh, 00h
    int 10h
    ret

text_putc:
    mov ah, 0Eh
    mov bh, 00h
    mov bl, 07h
    int 10h
    ret

text_print_string:
.next_char:
    lodsb
    cmp al, 0
    je .done
    call text_putc
    jmp .next_char
.done:
    ret

draw_confirm_screen:
    mov dh, 2
    mov dl, 28
    call text_set_cursor
    mov si, msg_title
    call text_print_string

    mov dh, 7
    mov dl, 26
    call text_set_cursor
    mov si, msg_confirm1
    call text_print_string

    mov dh, 9
    mov dl, 26
    call text_set_cursor
    mov si, msg_confirm2
    call text_print_string

    mov dh, 12
    mov dl, 14
    call text_set_cursor
    mov si, msg_confirm3
    call text_print_string

    mov dh, 14
    mov dl, 14
    call text_set_cursor
    mov si, msg_confirm4
    call text_print_string

    mov dh, 18
    mov dl, 20
    call text_set_cursor
    mov si, msg_names
    call text_print_string
    ret

; =========================================================
; VGA MODO 13h
; =========================================================
set_mode_13h:
    mov ax, 0013h
    int 10h
    ret

clear_screen_vga:
    push ax
    push cx
    push di
    push es

    mov ax, VGA_SEG
    mov es, ax
    xor di, di
    xor ax, ax
    mov cx, 32000         ; 64000 bytes / 2
    rep stosw

    pop es
    pop di
    pop cx
    pop ax
    ret

draw_game_screen:
    ; Por simplicidad, no dibujamos texto en VGA.
    ; Solo limpia y dibuja el nombre.
    ret

; =========================================================
; plot_pixel
; Entrada:
;   CX = x
;   DX = y
;   AL = color
; =========================================================
plot_pixel:
    push bx
    push di
    push es

    mov bx, dx            ; bx = y
    shl bx, 6             ; y*64
    mov di, dx
    shl di, 8             ; y*256
    add di, bx            ; y*320
    add di, cx            ; y*320 + x

    mov bx, VGA_SEG
    mov es, bx
    mov es:[di], al

    pop es
    pop di
    pop bx
    ret

; =========================================================
; draw_scaled_pixel
; Entrada:
;   CX = x base
;   DX = y base
;   AL = color
; Dibuja bloque scale x scale
; =========================================================
draw_scaled_pixel:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov si, cx            ; x base
    mov di, dx            ; y base
    xor bx, bx            ; dy = 0

.dy_loop:
    cmp bx, LETTER_SCALE
    jae .done

    xor dx, dx            ; dx = dx temporal como dx_inner? no
    xor cx, cx            ; dx_inner en cx

.dx_loop:
    cmp cx, LETTER_SCALE
    jae .next_row

    mov ax, si
    add ax, cx            ; x final
    push cx
    mov cx, ax

    mov ax, di
    add ax, bx            ; y final
    mov dx, ax

    mov al, 15            ; color blanco
    call plot_pixel

    pop cx
    inc cx
    jmp .dx_loop

.next_row:
    inc bx
    jmp .dy_loop

.done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; =========================================================
; draw_names_bitmap
; =========================================================
draw_names_bitmap:
    xor ax, ax
    mov al, [name_col]
    mov [base_x], ax
    mov [curr_x], ax

    xor ax, ax
    mov al, [name_row]
    mov [base_y], ax
    mov [curr_y], ax

    ; -------------------------
    ; Primera línea: YERIK
    ; -------------------------
    mov si, bmp_Y
    call draw_letter_current
    call advance_letter

    mov si, bmp_E
    call draw_letter_current
    call advance_letter

    mov si, bmp_R
    call draw_letter_current
    call advance_letter

    mov si, bmp_I
    call draw_letter_current
    call advance_letter

    mov si, bmp_K
    call draw_letter_current

    ; -------------------------
    ; "newline"
    ; curr_x = base_x
    ; curr_y += separación vertical
    ; -------------------------
    mov ax, [base_x]
    mov [curr_x], ax

    mov ax, [base_y]
    add ax, 24              ; 16 px alto + margen
    mov [curr_y], ax

    ; -------------------------
    ; Segunda línea: GABRIEL
    ; -------------------------
    mov si, bmp_G
    call draw_letter_current
    call advance_letter

    mov si, bmp_A
    call draw_letter_current
    call advance_letter

    mov si, bmp_B
    call draw_letter_current
    call advance_letter

    mov si, bmp_R
    call draw_letter_current
    call advance_letter

    mov si, bmp_I
    call draw_letter_current
    call advance_letter

    mov si, bmp_E
    call draw_letter_current
    call advance_letter

    mov si, bmp_L
    call draw_letter_current

    ret

advance_letter:
    add word [curr_x], LETTER_ADV
    ret

; =========================================================
; draw_letter_current
; Entrada:
;   SI = bitmap 8x8 de la letra
; =========================================================
draw_letter_current:
    mov byte [row_idx], 0

.row_loop:
    cmp byte [row_idx], 8
    je .done

    mov byte [col_idx], 0

.col_loop:
    cmp byte [col_idx], 8
    je .next_row

    ; -----------------------------------------
    ; Leer bit original del bitmap en (row, col)
    ; -----------------------------------------
    xor bx, bx
    mov bl, [row_idx]
    mov al, [si + bx]
    mov [row_bits], al

    mov al, 7
    sub al, [col_idx]
    mov [shift_count], al

    mov al, [row_bits]
    mov cl, [shift_count]
    shr al, cl
    and al, 1
    cmp al, 1
    jne .skip_pixel

    ; -----------------------------------------
    ; Aplicar reflexiones primero
    ; -----------------------------------------
    mov al, [flip_v]
    cmp al, 0
    je .no_vflip

    mov al, 7
    sub al, [row_idx]
    mov [pre_row], al
    jmp .row_ready

.no_vflip:
    mov al, [row_idx]
    mov [pre_row], al

.row_ready:
    mov al, [flip_h]
    cmp al, 0
    je .no_hflip

    mov al, 7
    sub al, [col_idx]
    mov [pre_col], al
    jmp .col_ready

.no_hflip:
    mov al, [col_idx]
    mov [pre_col], al

.col_ready:
    ; -----------------------------------------
    ; Aplicar rotación sobre (pre_row, pre_col)
    ; -----------------------------------------
    mov al, [orientation]
    cmp al, ROT_0
    je .map_rot0
    cmp al, ROT_90
    je .map_rot90
    cmp al, ROT_180
    je .map_rot180
    cmp al, ROT_270
    je .map_rot270

.map_rot0:
    mov al, [pre_row]
    mov [rot_row], al
    mov al, [pre_col]
    mov [rot_col], al
    jmp .mapped

.map_rot90:
    mov al, [pre_col]
    mov [rot_row], al
    mov al, 7
    sub al, [pre_row]
    mov [rot_col], al
    jmp .mapped

.map_rot180:
    mov al, 7
    sub al, [pre_row]
    mov [rot_row], al
    mov al, 7
    sub al, [pre_col]
    mov [rot_col], al
    jmp .mapped

.map_rot270:
    mov al, 7
    sub al, [pre_col]
    mov [rot_row], al
    mov al, [pre_row]
    mov [rot_col], al
    jmp .mapped

.mapped:
    ; x = curr_x + rot_col * scale
    xor ax, ax
    mov al, [rot_col]
    shl ax, 1
    add ax, [curr_x]
    mov cx, ax

    ; y = curr_y + rot_row * scale
    xor ax, ax
    mov al, [rot_row]
    shl ax, 1
    add ax, [curr_y]
    mov dx, ax

    call draw_scaled_pixel

.skip_pixel:
    inc byte [col_idx]
    jmp .col_loop

.next_row:
    inc byte [row_idx]
    jmp .row_loop

.done:
    ret

; =========================================================
; Bitmaps 8x8
; =========================================================
bmp_A db 00111100b
      db 01000010b
      db 01000010b
      db 01111110b
      db 01000010b
      db 01000010b
      db 01000010b
      db 00000000b

bmp_B db 01111100b
      db 01000010b
      db 01000010b
      db 01111100b
      db 01000010b
      db 01000010b
      db 01111100b
      db 00000000b

bmp_E db 01111110b
      db 01000000b
      db 01000000b
      db 01111100b
      db 01000000b
      db 01000000b
      db 01111110b
      db 00000000b

bmp_G db 00111100b
      db 01000010b
      db 01000000b
      db 01001110b
      db 01000010b
      db 01000010b
      db 00111100b
      db 00000000b

bmp_I db 00111100b
      db 00011000b
      db 00011000b
      db 00011000b
      db 00011000b
      db 00011000b
      db 00111100b
      db 00000000b

bmp_K db 01000010b
      db 01000100b
      db 01001000b
      db 01110000b
      db 01001000b
      db 01000100b
      db 01000010b
      db 00000000b

bmp_L db 01000000b
      db 01000000b
      db 01000000b
      db 01000000b
      db 01000000b
      db 01000000b
      db 01111110b
      db 00000000b

bmp_R db 01111100b
      db 01000010b
      db 01000010b
      db 01111100b
      db 01001000b
      db 01000100b
      db 01000010b
      db 00000000b

bmp_Y db 01000010b
      db 00100100b
      db 00011000b
      db 00011000b
      db 00011000b
      db 00011000b
      db 00111100b
      db 00000000b
