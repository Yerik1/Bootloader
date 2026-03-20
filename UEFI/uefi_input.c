#include <efi.h>
#include <efilib.h>
#include "uefi_api.h"

static EFI_SYSTEM_TABLE *gInputST = NULL;

void uefi_input_init(EFI_SYSTEM_TABLE *SystemTable) {
    gInputST = SystemTable;
}

void uefi_wait_key(void) {
    UINTN Index;

    if (gInputST == NULL || gInputST->ConIn == NULL) return;

    while (1) {
        EFI_STATUS Status = uefi_call_wrapper(
            gInputST->BootServices->WaitForEvent,
            3,
            1,
            &gInputST->ConIn->WaitForKey,
            &Index
        );

        if (!EFI_ERROR(Status)) {
            return;
        }
    }
}

UINT32 uefi_read_action(void) {
    EFI_INPUT_KEY Key;
    EFI_STATUS Status;
    UINT32 entropy;

    if (gInputST == NULL || gInputST->ConIn == NULL) {
        return ACT_NONE;
    }

    Status = uefi_call_wrapper(gInputST->ConIn->ReadKeyStroke, 2, gInputST->ConIn, &Key);
    if (EFI_ERROR(Status)) {
        return ACT_NONE;
    }

    entropy = ((UINT32)Key.ScanCode << 16) ^ (UINT32)Key.UnicodeChar;
    uefi_random_stir(entropy);

    switch (Key.ScanCode) {
        case SCAN_LEFT:  return ACT_LEFT;
        case SCAN_RIGHT: return ACT_RIGHT;
        case SCAN_UP:    return ACT_UP;
        case SCAN_DOWN:  return ACT_DOWN;
        case SCAN_ESC:   return ACT_EXIT;
        default: break;
    }

    switch (Key.UnicodeChar) {
        case CHAR_CARRIAGE_RETURN:
        case L's':
        case L'S':
        case L'y':
        case L'Y':
            return ACT_START;

        case L'r':
        case L'R':
            return ACT_RESTART;

        case L'q':
        case L'Q':
            return ACT_EXIT;

        default:
            return ACT_NONE;
    }
}
