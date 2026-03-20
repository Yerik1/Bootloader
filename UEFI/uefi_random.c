#include <efi.h>
#include <efilib.h>
#include "uefi_api.h"

/* Se guarda la System Table para acceder a RuntimeServices->GetTime. */
static EFI_SYSTEM_TABLE *gRandST = NULL;

/* Semilla inicial por defecto. Se mezcla luego con el tiempo real. */
static UINT32 gRandSeed = 0x1234ABCDu;

/* ------------------------------------------------------------
   mix32
   ------------------------------------------------------------
   Función de mezcla (hash simple) para "desordenar" bits.
   Sirve para mejorar la distribución de los valores de entrada.
   ------------------------------------------------------------ */
static UINT32 mix32(UINT32 x) {
    x ^= x >> 16;
    x *= 0x7feb352dU;
    x ^= x >> 15;
    x *= 0x846ca68bU;
    x ^= x >> 16;
    return x;
}

void uefi_random_init(EFI_SYSTEM_TABLE *SystemTable) {
    EFI_TIME Time;
    EFI_STATUS Status;

    gRandST = SystemTable;
    
    /* Intentar obtener la hora del firmware para derivar una semilla
       menos predecible que la constante inicial. */
    if (gRandST != NULL && gRandST->RuntimeServices != NULL) {
        Status = uefi_call_wrapper(
            gRandST->RuntimeServices->GetTime,
            2,
            &Time,
            NULL
        );

        if (!EFI_ERROR(Status)) {
            UINT32 seed = 0;
            /* Se combinan varios campos del tiempo en un entero de 32 bits. */
            seed ^= ((UINT32)Time.Year << 16);
            seed ^= ((UINT32)Time.Month << 8);
            seed ^= (UINT32)Time.Day;
            seed ^= ((UINT32)Time.Hour << 24);
            seed ^= ((UINT32)Time.Minute << 16);
            seed ^= ((UINT32)Time.Second << 8);
            seed ^= (UINT32)Time.Nanosecond;
            
            /* Se mezcla con la semilla global existente. */
            gRandSeed ^= mix32(seed);
        }
    }

    /* Mezcla final para dejar la semilla en un estado más uniforme. */
    gRandSeed = mix32(gRandSeed);
}

void uefi_random_stir(UINT32 value) {
    /* eventos como teclas presionadas alteran
       la secuencia pseudoaleatoria. */
    gRandSeed ^= mix32(value + 0x9E3779B9u);
    gRandSeed = mix32(gRandSeed);
}

UINT16 uefi_random16(void) {
    /* Xorshift simple: rápido y compacto. */
    gRandSeed ^= gRandSeed << 13;
    gRandSeed ^= gRandSeed >> 17;
    gRandSeed ^= gRandSeed << 5;
    
    /* Solo se retornan 16 bits. */
    return (UINT16)(gRandSeed & 0xFFFFu);
}

void uefi_randomize_position(UINT16 *out_x, UINT16 *out_y, UINT16 max_x, UINT16 max_y) {
    EFI_TIME Time;
    EFI_STATUS Status;

    /* Validar punteros y rangos antes de escribir. */
    if (out_x == NULL || out_y == NULL || max_x == 0 || max_y == 0) {
        return;
    }

    /* Antes de generar coordenadas, se vuelve a mezclar la semilla
       con datos del tiempo actual para introducir más variación. */
    if (gRandST != NULL && gRandST->RuntimeServices != NULL) {
        Status = uefi_call_wrapper(
            gRandST->RuntimeServices->GetTime,
            2,
            &Time,
            NULL
        );

        if (!EFI_ERROR(Status)) {
            UINT32 t = 0;
            t ^= ((UINT32)Time.Second << 24);
            t ^= ((UINT32)Time.Minute << 16);
            t ^= ((UINT32)Time.Hour << 8);
            t ^= (UINT32)Time.Nanosecond;
            uefi_random_stir(t);
        }
    }

    /* Se genera cada coordenada dentro de su respectivo rango.
       El operador % limita el resultado a [0, max-1]. */
    *out_x = (UINT16)(uefi_random16() % max_x);
    *out_y = (UINT16)(uefi_random16() % max_y);
}
