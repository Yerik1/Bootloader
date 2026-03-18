BITS 16

; =========================================================
; Estados del juego
; =========================================================
STATE_CONFIRM   equ 0
STATE_RUNNING   equ 1
STATE_EXIT      equ 2

; =========================================================
; Orientaciones
; =========================================================
ROT_0           equ 0
ROT_90          equ 1
ROT_180         equ 2
ROT_270         equ 3

; =========================================================
; Acciones abstractas de input.asm
; =========================================================
ACT_NONE        equ 0
ACT_START       equ 1
ACT_EXIT        equ 2
ACT_LEFT        equ 3
ACT_RIGHT       equ 4
ACT_UP          equ 5
ACT_DOWN        equ 6
ACT_RESTART     equ 7

; =========================================================
; Variables globales compartidas
; name_row = Y en VGA
; name_col = X en VGA
; =========================================================
game_state      db STATE_CONFIRM
orientation     db ROT_0
name_row        db 60
name_col        db 30
flip_h  db 0
flip_v  db 0

game_start:
    call game_init

main_loop:
    cmp byte [game_state], STATE_CONFIRM
    je confirm_loop

    cmp byte [game_state], STATE_RUNNING
    je running_loop

    cmp byte [game_state], STATE_EXIT
    je exit_loop

    jmp main_loop

game_init:
    mov byte [game_state], STATE_CONFIRM
    mov byte [orientation], ORIENT_NORMAL
    call set_mode_text
    call clear_screen_text
    call draw_confirm_screen
    ret

confirm_loop:
    call read_key_action

    cmp al, ACT_START
    je start_game

    cmp al, ACT_EXIT
    je request_exit

    jmp confirm_loop

start_game:
    call randomize_position
    mov byte [orientation], ORIENT_NORMAL
    mov byte [game_state], STATE_RUNNING

    call set_mode_13h
    call clear_screen_vga
    call draw_game_screen
    call draw_names_bitmap
    jmp main_loop

request_exit:
    mov byte [game_state], STATE_EXIT
    jmp main_loop

running_loop:
    call read_key_action

    cmp al, ACT_LEFT
    je do_left

    cmp al, ACT_RIGHT
    je do_right

    cmp al, ACT_UP
    je do_up

    cmp al, ACT_DOWN
    je do_down

    cmp al, ACT_RESTART
    je do_restart

    cmp al, ACT_EXIT
    je do_quit

    jmp running_loop

do_left:
    mov al, [orientation]
    dec al
    and al, 03h
    mov [orientation], al

    call clear_screen_vga
    call draw_game_screen
    call draw_names_bitmap
    jmp running_loop

do_right:
    mov al, [orientation]
    inc al
    and al, 03h
    mov [orientation], al

    call clear_screen_vga
    call draw_game_screen
    call draw_names_bitmap
    jmp running_loop

do_up:
    mov al, [orientation]
    test al, 1
    jnz .use_h

.use_v:
    mov al, [flip_v]
    xor al, 1
    mov [flip_v], al
    jmp .redraw

.use_h:
    mov al, [flip_h]
    xor al, 1
    mov [flip_h], al

.redraw:
    call clear_screen_vga
    call draw_game_screen
    call draw_names_bitmap
    jmp running_loop

do_down:
    mov al, [orientation]
    test al, 1
    jnz .use_h

.use_v:
    mov al, [flip_v]
    xor al, 1
    mov [flip_v], al
    jmp .redraw

.use_h:
    mov al, [flip_h]
    xor al, 1
    mov [flip_h], al

.redraw:
    call clear_screen_vga
    call draw_game_screen
    call draw_names_bitmap
    jmp running_loop
    
do_restart:
    call randomize_position
    mov byte [orientation], ROT_0
    mov byte [flip_h], 0
    mov byte [flip_v], 0
    call clear_screen_vga
    call draw_game_screen
    call draw_names_bitmap
    jmp running_loop

do_quit:
    mov byte [game_state], STATE_EXIT
    jmp main_loop

exit_loop:
    call set_mode_text
    call clear_screen_text
    call draw_exit_screen
hang_game:
    jmp hang_game

draw_exit_screen:
    mov dh, 10
    mov dl, 28
    call text_set_cursor
    mov si, msg_exit
    call text_print_string
    ret

msg_exit db 'Juego finalizado. Reinicie QEMU.', 0
