#include <efi.h>
#include <efilib.h>
#include "uefi_api.h"

/* Se guarda la System Table para poder acceder luego a ConIn y
   BootServices sin pasarla en cada llamada. */
static EFI_SYSTEM_TABLE *gInputST = NULL;

void uefi_input_init(EFI_SYSTEM_TABLE *SystemTable) {
  /* Inicializa el módulo de entrada guardando la tabla del sistema.*/
    gInputST = SystemTable;
}

void uefi_wait_key(void) {
    UINTN Index;

    /* Si no hay acceso a SystemTable o a la consola de entrada, salir. */
    if (gInputST == NULL || gInputST->ConIn == NULL) return;

    while (1) {
        /* WaitForEvent bloquea hasta que el evento WaitForKey ocurra,
           o sea, hasta que haya una tecla disponible. */
        EFI_STATUS Status = uefi_call_wrapper(
            gInputST->BootServices->WaitForEvent,
            3,
            1,
            &gInputST->ConIn->WaitForKey,
            &Index
        );
        /* Si no hubo error, ya hay algo que leer. */
        if (!EFI_ERROR(Status)) {
            return;
        }
    }
}

UINT32 uefi_read_action(void) {
    EFI_INPUT_KEY Key;
    EFI_STATUS Status;
    UINT32 entropy;

    /* Si el módulo no fue inicializado, no hay acción posible. */
    if (gInputST == NULL || gInputST->ConIn == NULL) {
        return ACT_NONE;
    }

    /* Lee una tecla de la consola de entrada. */
    Status = uefi_call_wrapper(gInputST->ConIn->ReadKeyStroke, 2, gInputST->ConIn, &Key);
    if (EFI_ERROR(Status)) {
        return ACT_NONE;
    }

    /* Combina ScanCode y UnicodeChar para crear un valor variable
       que se inyecta al estado del generador pseudoaleatorio. */
    entropy = ((UINT32)Key.ScanCode << 16) ^ (UINT32)Key.UnicodeChar;
    uefi_random_stir(entropy);

    /* Primero se manejan teclas especiales que llegan por ScanCode,
       como flechas y ESC. */
    switch (Key.ScanCode) {
        case SCAN_LEFT:  return ACT_LEFT;
        case SCAN_RIGHT: return ACT_RIGHT;
        case SCAN_UP:    return ACT_UP;
        case SCAN_DOWN:  return ACT_DOWN;
        case SCAN_ESC:   return ACT_EXIT;
        default: break;
    }

    /* Luego se manejan teclas alfanuméricas según UnicodeChar. */
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
