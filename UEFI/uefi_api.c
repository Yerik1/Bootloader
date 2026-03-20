#include <efi.h>
#include <efilib.h>
#include <efiprot.h>
#include "uefi_api.h"

/* Puntero global al protocolo gráfico una vez localizado. */
static EFI_GRAPHICS_OUTPUT_PROTOCOL *gGop = NULL;

/* GUID del protocolo GOP. Se usa para pedirle a UEFI ese servicio. */
static EFI_GUID gGopGuid = EFI_GRAPHICS_OUTPUT_PROTOCOL_GUID;

EFI_STATUS uefi_init_gop(EFI_SYSTEM_TABLE *SystemTable) {

    /* LocateProtocol busca una implementación del protocolo GOP y
       deja en gGop el puntero para usarlo después. */
    return uefi_call_wrapper(
        SystemTable->BootServices->LocateProtocol,
        3,
        &gGopGuid,
        NULL,
        (VOID **)&gGop
    );
}

/* ------------------------------------------------------------
   put_pixel
   ------------------------------------------------------------
   Función interna para escribir un solo pixel.
   "color" se interpreta como 0xRRGGBB.
   ------------------------------------------------------------ */
static void put_pixel(UINT32 x, UINT32 y, UINT32 color) {
    if (gGop == NULL) return; /* Si GOP no fue inicializado, no se puede dibujar. */

    /* Resolución visible actual. */
    UINT32 width = gGop->Mode->Info->HorizontalResolution;
    UINT32 height = gGop->Mode->Info->VerticalResolution;
    
    /* PixelsPerScanLine puede ser >= width.
       Representa cuántos pixels ocupa realmente una fila en memoria. */
    UINT32 ppsl = gGop->Mode->Info->PixelsPerScanLine;

    /* Validación de límites para no escribir fuera del framebuffer. */
    if (x >= width || y >= height) return;

    /* FrameBufferBase es la dirección de memoria donde vive la imagen.
       Se castea al tipo de pixel definido por UEFI. */
    EFI_GRAPHICS_OUTPUT_BLT_PIXEL *fb =
        (EFI_GRAPHICS_OUTPUT_BLT_PIXEL *)(UINTN)gGop->Mode->FrameBufferBase;

    /* Índice lineal del pixel (x, y) dentro del framebuffer. */
    UINTN idx = (UINTN)y * ppsl + x;

    /* UEFI guarda los canales como Blue, Green, Red. */
    fb[idx].Blue = (UINT8)(color & 0xFF);
    fb[idx].Green = (UINT8)((color >> 8) & 0xFF);
    fb[idx].Red = (UINT8)((color >> 16) & 0xFF);
    fb[idx].Reserved = 0;
}

void uefi_clear_screen(UINT32 color) {
    if (gGop == NULL) return;

    UINT32 width = gGop->Mode->Info->HorizontalResolution;
    UINT32 height = gGop->Mode->Info->VerticalResolution;

    /* Recorre toda la pantalla y pinta cada pixel del mismo color.*/
    for (UINT32 y = 0; y < height; ++y) {
        for (UINT32 x = 0; x < width; ++x) {
            put_pixel(x, y, color);
        }
    }
}

void uefi_draw_block(UINT32 x, UINT32 y, UINT32 size, UINT32 color) {
    /* Dibuja un cuadrado de lado "size" usando put_pixel. */
    for (UINT32 dy = 0; dy < size; ++dy) {
        for (UINT32 dx = 0; dx < size; ++dx) {
            put_pixel(x + dx, y + dy, color);
        }
    }
}
