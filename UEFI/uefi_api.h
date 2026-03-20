#ifndef UEFI_API_H
#define UEFI_API_H

#include <efi.h>

typedef enum {
    ACT_NONE = 0,
    ACT_START,
    ACT_EXIT,
    ACT_LEFT,
    ACT_RIGHT,
    ACT_UP,
    ACT_DOWN,
    ACT_RESTART
} GAME_ACTION;

EFI_STATUS uefi_init_gop(EFI_SYSTEM_TABLE *SystemTable);

void uefi_clear_screen(UINT32 color);
void uefi_draw_block(UINT32 x, UINT32 y, UINT32 size, UINT32 color);

UINT32 uefi_read_action(void);
void uefi_wait_key(void);

void uefi_random_init(EFI_SYSTEM_TABLE *SystemTable);
void uefi_random_stir(UINT32 value);
UINT16 uefi_random16(void);
void uefi_randomize_position(UINT16 *out_x, UINT16 *out_y, UINT16 max_x, UINT16 max_y);

#endif
