BITS 64
default rel

global game_start_asm

extern uefi_clear_screen
extern uefi_draw_block
extern uefi_read_action
extern uefi_wait_key
extern uefi_randomize_position

section .data

; -----------------------------------------
; Estado del juego
; -----------------------------------------
orientation db 0          ; 0,1,2,3 => 0,90,180,270
flip_h      db 0
flip_v      db 0

base_x      dw 40
base_y      dw 40

rand_x      dw 0
rand_y      dw 0

word_dx     dw 0
word_dy     dw 0

step_x      dw 0
step_y      dw 0
reverse_ord db 0
order_flip  db 0

; -----------------------------------------
; Constantes de acciones
; -----------------------------------------
ACT_NONE    equ 0
ACT_START   equ 1
ACT_EXIT    equ 2
ACT_LEFT    equ 3
ACT_RIGHT   equ 4
ACT_UP      equ 5
ACT_DOWN    equ 6
ACT_RESTART equ 7

; -----------------------------------------
; Escala y layout
; -----------------------------------------
SCALE       equ 4
LETTER_ADV  equ 36        ; 8*4 + 4
LINE_ADV    equ 44        ; 8*4 + 12
COLOR_WHITE equ 0xFFFFFF
COLOR_BG    equ 0x000000

; -----------------------------------------
; Variables temporales
; -----------------------------------------
tmp_row     db 0
tmp_col     db 0
pre_row     db 0
pre_col     db 0
rot_row     db 0
rot_col     db 0
row_bits    db 0
shift_count db 0

; -----------------------------------------
; Bitmaps 8x8
; -----------------------------------------
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

section .text

; =========================================================
; game_start_asm
; =========================================================
game_start_asm:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15

    ; mantener alineación para llamadas C
    sub rsp, 8

    ; estado inicial
    mov byte [orientation], 0
    mov byte [flip_h], 0
    mov byte [flip_v], 0
    mov byte [order_flip], 0
    
    ; posición inicial pseudoaleatoria
    lea rdi, [rel rand_x]
    lea rsi, [rel rand_y]
    mov edx, 340
    mov ecx, 220
    call uefi_randomize_position

    mov ax, [rand_x]
    add ax, 20
    mov [base_x], ax

    mov ax, [rand_y]
    add ax, 20
    mov [base_y], ax

main_loop:
    ; limpiar pantalla
    mov edi, COLOR_BG
    call uefi_clear_screen

    ; dibujar nombres
    call draw_names

wait_input:
    call uefi_wait_key
    call uefi_read_action

    cmp eax, ACT_LEFT
    je do_left
    cmp eax, ACT_RIGHT
    je do_right
    cmp eax, ACT_UP
    je do_up
    cmp eax, ACT_DOWN
    je do_down
    cmp eax, ACT_RESTART
    je do_restart
    cmp eax, ACT_EXIT
    je done

    jmp wait_input

do_left:
    mov al, [orientation]
    dec al
    and al, 3
    mov [orientation], al
    jmp main_loop

do_right:
    mov al, [orientation]
    inc al
    and al, 3
    mov [orientation], al
    jmp main_loop

; Reflejo relativo a pantalla:

do_up:
    mov al, [orientation]
    cmp al, 1
    je .vertical_word
    mov al, [orientation]
    cmp al, 3
    je .vertical_word
    mov al, [flip_v]
    xor al, 1
    mov [flip_v], al
    jmp main_loop
    
.vertical_word:
    mov al, [order_flip]
    xor al, 1
    mov [order_flip], al
    jmp main_loop


; Reflejo complementario:
do_down:
    mov al, [orientation]
    cmp al, 1
    je .vertical_word
    mov al, [orientation]
    cmp al, 3
    je .vertical_word
    mov al, [flip_v]
    xor al, 1
    mov [flip_v], al
    jmp main_loop
    
.vertical_word:
    mov al, [order_flip]
    xor al, 1
    mov [order_flip], al
    jmp main_loop

do_restart:
    ; randomize_position(&rand_x, &rand_y, max_x, max_y)
    lea rdi, [rel rand_x]
    lea rsi, [rel rand_y]

    ; límites seguros para que el bloque completo no se salga
    mov edx, 340          ; max_x lógico
    mov ecx, 220          ; max_y lógico
    call uefi_randomize_position

    mov ax, [rand_x]
    add ax, 20
    mov [base_x], ax

    mov ax, [rand_y]
    add ax, 20
    mov [base_y], ax

    mov byte [orientation], 0
    mov byte [flip_h], 0
    mov byte [flip_v], 0
    mov byte [order_flip], 0
    jmp main_loop

done:
    add rsp, 8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; =========================================================
; draw_names
; Dibuja:
;   YERIK
;   GABRIEL
; =========================================================
draw_names:
    push rbx
    push r12
    push r13
    push r14

    ; -----------------------------------------
    ; Definir layout de la palabra según orientation
    ; step_x / step_y = avance entre letras
    ; word_dx / word_dy = offset entre palabras
    ; reverse_ord = orden base de las letras
    ; -----------------------------------------
    mov al, [orientation]
    cmp al, 0
    je .rot0
    cmp al, 1
    je .rot90
    cmp al, 2
    je .rot180
    jmp .rot270

.rot0:
    mov word [step_x], LETTER_ADV
    mov word [step_y], 0
    mov word [word_dx], 0
    mov word [word_dy], LINE_ADV
    mov byte [reverse_ord], 0
    jmp .layout_ready

.rot90:
    mov word [step_x], 0
    mov word [step_y], LETTER_ADV
    mov word [word_dx], LINE_ADV
    mov word [word_dy], 0
    mov byte [reverse_ord], 0
    jmp .layout_ready

.rot180:
    mov word [step_x], LETTER_ADV
    mov word [step_y], 0
    mov ax, 0
    mov [word_dx], ax
    mov ax, -LINE_ADV
    mov [word_dy], ax
    mov byte [reverse_ord], 1
    jmp .layout_ready

.rot270:
    mov word [step_x], 0
    mov word [step_y], LETTER_ADV
    mov ax, -LINE_ADV
    mov [word_dx], ax
    mov ax, 0
    mov [word_dy], ax
    mov byte [reverse_ord], 1

.layout_ready:
    ; -----------------------------------------
    ; Ajustar reverse_ord por reflexiones
    ; Si la palabra avanza horizontalmente, flip_h invierte el orden.
    ; Si la palabra avanza verticalmente, flip_v invierte el orden.
    ; -----------------------------------------
    mov al, [orientation]
    test al, 1
    jnz .vertical_word

.horizontal_word:
    mov al, [flip_h]
    cmp al, 0
    je .reverse_done
    mov al, [reverse_ord]
    xor al, 1
    mov [reverse_ord], al
    jmp .reverse_done

.vertical_word:
    mov al, [flip_v]
    cmp al, 0
    je .reverse_done
    mov al, [reverse_ord]
    xor al, 1
    mov [reverse_ord], al

.reverse_done:
    ; -----------------------------------------
    ; Ajuste manual del orden de letras
    ; -----------------------------------------
    mov al, [order_flip]
    cmp al, 0
    je .order_done

    mov al, [reverse_ord]
    xor al, 1
    mov [reverse_ord], al

.order_done:
    ; =========================================
    ; Primera palabra: YERIK
    ; =========================================
    xor ebx, ebx
    mov bx, [base_x]

    xor r12d, r12d
    mov r12w, [base_y]

    cmp byte [reverse_ord], 0
    je .yerik_normal

.yerik_reverse:
    lea rsi, [rel bmp_K]
    call draw_letter
    call advance_pos

    lea rsi, [rel bmp_I]
    call draw_letter
    call advance_pos

    lea rsi, [rel bmp_R]
    call draw_letter
    call advance_pos

    lea rsi, [rel bmp_E]
    call draw_letter
    call advance_pos

    lea rsi, [rel bmp_Y]
    call draw_letter
    jmp .next_word

.yerik_normal:
    lea rsi, [rel bmp_Y]
    call draw_letter
    call advance_pos

    lea rsi, [rel bmp_E]
    call draw_letter
    call advance_pos

    lea rsi, [rel bmp_R]
    call draw_letter
    call advance_pos

    lea rsi, [rel bmp_I]
    call draw_letter
    call advance_pos

    lea rsi, [rel bmp_K]
    call draw_letter

.next_word:
    ; =========================================
    ; Segunda palabra: GABRIEL
    ; Offset entre palabras rotado
    ; =========================================
    mov bx, [base_x]
    mov r12w, [base_y]

    mov ax, [word_dx]
    add bx, ax

    mov ax, [word_dy]
    add r12w, ax

    cmp byte [reverse_ord], 0
    je .gabriel_normal

.gabriel_reverse:
    lea rsi, [rel bmp_L]
    call draw_letter
    call advance_pos

    lea rsi, [rel bmp_E]
    call draw_letter
    call advance_pos

    lea rsi, [rel bmp_I]
    call draw_letter
    call advance_pos

    lea rsi, [rel bmp_R]
    call draw_letter
    call advance_pos

    lea rsi, [rel bmp_B]
    call draw_letter
    call advance_pos

    lea rsi, [rel bmp_A]
    call draw_letter
    call advance_pos

    lea rsi, [rel bmp_G]
    call draw_letter
    jmp .done

.gabriel_normal:
    lea rsi, [rel bmp_G]
    call draw_letter
    call advance_pos

    lea rsi, [rel bmp_A]
    call draw_letter
    call advance_pos

    lea rsi, [rel bmp_B]
    call draw_letter
    call advance_pos

    lea rsi, [rel bmp_R]
    call draw_letter
    call advance_pos

    lea rsi, [rel bmp_I]
    call draw_letter
    call advance_pos

    lea rsi, [rel bmp_E]
    call draw_letter
    call advance_pos

    lea rsi, [rel bmp_L]
    call draw_letter

.done:
    pop r14
    pop r13
    pop r12
    pop rbx
    ret


advance_pos:
    mov ax, [step_x]
    add bx, ax

    mov ax, [step_y]
    add r12w, ax
    ret

; =========================================================
; draw_letter
; Entrada:
;   RSI -> bitmap 8x8
;   BL  -> x base letra
;   R12B -> y base letra
; =========================================================
draw_letter:
    push rax
    push rcx
    push rdx
    push r8
    push r9
    push r10
    push r11
    push r13

    ; Guardar puntero al bitmap en registro callee-saved
    mov r13, rsi

    mov byte [tmp_row], 0

.row_loop:
    cmp byte [tmp_row], 8
    je .done

    mov byte [tmp_col], 0

.col_loop:
    cmp byte [tmp_col], 8
    je .next_row

    ; row_bits = bitmap[tmp_row]
    xor eax, eax
    mov al, [tmp_row]
    movzx r10d, al
    mov al, [r13 + r10]
    mov [row_bits], al

    ; shift = 7 - col
    mov al, 7
    sub al, [tmp_col]
    mov [shift_count], al

    ; if bit == 0 -> skip
    mov al, [row_bits]
    mov cl, [shift_count]
    shr al, cl
    and al, 1
    cmp al, 1
    jne .skip_pixel

    ; -----------------------------------------
    ; Aplicar reflejos
    ; -----------------------------------------
    mov al, [flip_v]
    cmp al, 0
    je .no_vflip

    mov al, 7
    sub al, [tmp_row]
    mov [pre_row], al
    jmp .row_ready

.no_vflip:
    mov al, [tmp_row]
    mov [pre_row], al

.row_ready:
    mov al, [flip_h]
    cmp al, 0
    je .no_hflip

    mov al, 7
    sub al, [tmp_col]
    mov [pre_col], al
    jmp .col_ready

.no_hflip:
    mov al, [tmp_col]
    mov [pre_col], al

.col_ready:
    ; -----------------------------------------
    ; Aplicar rotación
    ; -----------------------------------------
    mov al, [orientation]
    cmp al, 0
    je .rot0
    cmp al, 1
    je .rot90
    cmp al, 2
    je .rot180
    jmp .rot270

.rot0:
    mov al, [pre_row]
    mov [rot_row], al
    mov al, [pre_col]
    mov [rot_col], al
    jmp .mapped

.rot90:
    mov al, [pre_col]
    mov [rot_row], al
    mov al, 7
    sub al, [pre_row]
    mov [rot_col], al
    jmp .mapped

.rot180:
    mov al, 7
    sub al, [pre_row]
    mov [rot_row], al
    mov al, 7
    sub al, [pre_col]
    mov [rot_col], al
    jmp .mapped

.rot270:
    mov al, 7
    sub al, [pre_col]
    mov [rot_row], al
    mov al, [pre_row]
    mov [rot_col], al

.mapped:
    ; x = base_x + rot_col * SCALE
    xor eax, eax
    mov al, [rot_col]
    imul eax, SCALE
    add eax, ebx

    ; y = base_y + rot_row * SCALE
    xor edx, edx
    mov dl, [rot_row]
    imul edx, SCALE
    add edx, r12d

    ; uefi_draw_block(x, y, SCALE, white)
    mov edi, eax
    mov esi, edx
    mov edx, SCALE
    mov ecx, COLOR_WHITE
    call uefi_draw_block

.skip_pixel:
    inc byte [tmp_col]
    jmp .col_loop

.next_row:
    inc byte [tmp_row]
    jmp .row_loop

.done:
    pop r13
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rax
    ret
