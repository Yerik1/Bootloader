#include <efi.h>
#include <efilib.h>
#include "uefi_api.h"

extern void game_start_asm(void);
void uefi_input_init(EFI_SYSTEM_TABLE *SystemTable);

EFI_STATUS EFIAPI efi_main(EFI_HANDLE ImageHandle, EFI_SYSTEM_TABLE *SystemTable) {
    EFI_STATUS Status;
    EFI_INPUT_KEY Key;
    UINTN Index;

    InitializeLib(ImageHandle, SystemTable);

    Print(L"UEFI bootloader iniciado.\r\n");
    Print(L"Prueba plataforma UEFI para juego ASM.\r\n");
    Print(L"Presione una tecla para iniciar.\r\n");

    while (1) {
        Status = uefi_call_wrapper(
            SystemTable->BootServices->WaitForEvent,
            3,
            1,
            &SystemTable->ConIn->WaitForKey,
            &Index
        );

        if (EFI_ERROR(Status)) {
            Print(L"Fallo en WaitForEvent.\r\n");
            return Status;
        }

        Status = uefi_call_wrapper(SystemTable->ConIn->ReadKeyStroke, 2, SystemTable->ConIn, &Key);
        if (!EFI_ERROR(Status)) {
            break;
        }
    }

    Status = uefi_init_gop(SystemTable);
    if (EFI_ERROR(Status)) {
        Print(L"No se pudo inicializar GOP.\r\n");
        uefi_call_wrapper(SystemTable->BootServices->Stall, 1, 2000000);
        return Status;
    }

    uefi_input_init(SystemTable);
    uefi_random_init(SystemTable);
    game_start_asm();

    uefi_call_wrapper(SystemTable->BootServices->Stall, 1, 2000000);
    return EFI_SUCCESS;
}
