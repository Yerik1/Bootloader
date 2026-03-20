BITS 16
ORG 7E00h

jmp stage_start

%include "game.asm"
%include "input.asm"
%include "random.asm"
%include "render.asm"

stage_start:
    call game_start

.hang:
    jmp .hang
