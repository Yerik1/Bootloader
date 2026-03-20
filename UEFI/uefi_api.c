#include <efi.h>
#include <efilib.h>
#include <efiprot.h>
#include "uefi_api.h"

static EFI_GRAPHICS_OUTPUT_PROTOCOL *gGop = NULL;
static EFI_GUID gGopGuid = EFI_GRAPHICS_OUTPUT_PROTOCOL_GUID;

EFI_STATUS uefi_init_gop(EFI_SYSTEM_TABLE *SystemTable) {
    return uefi_call_wrapper(
        SystemTable->BootServices->LocateProtocol,
        3,
        &gGopGuid,
        NULL,
        (VOID **)&gGop
    );
}

static void put_pixel(UINT32 x, UINT32 y, UINT32 color) {
    if (gGop == NULL) return;

    UINT32 width = gGop->Mode->Info->HorizontalResolution;
    UINT32 height = gGop->Mode->Info->VerticalResolution;
    UINT32 ppsl = gGop->Mode->Info->PixelsPerScanLine;

    if (x >= width || y >= height) return;

    EFI_GRAPHICS_OUTPUT_BLT_PIXEL *fb =
        (EFI_GRAPHICS_OUTPUT_BLT_PIXEL *)(UINTN)gGop->Mode->FrameBufferBase;

    UINTN idx = (UINTN)y * ppsl + x;

    fb[idx].Blue = (UINT8)(color & 0xFF);
    fb[idx].Green = (UINT8)((color >> 8) & 0xFF);
    fb[idx].Red = (UINT8)((color >> 16) & 0xFF);
    fb[idx].Reserved = 0;
}

void uefi_clear_screen(UINT32 color) {
    if (gGop == NULL) return;

    UINT32 width = gGop->Mode->Info->HorizontalResolution;
    UINT32 height = gGop->Mode->Info->VerticalResolution;

    for (UINT32 y = 0; y < height; ++y) {
        for (UINT32 x = 0; x < width; ++x) {
            put_pixel(x, y, color);
        }
    }
}

void uefi_draw_block(UINT32 x, UINT32 y, UINT32 size, UINT32 color) {
    for (UINT32 dy = 0; dy < size; ++dy) {
        for (UINT32 dx = 0; dx < size; ++dx) {
            put_pixel(x + dx, y + dy, color);
        }
    }
}
