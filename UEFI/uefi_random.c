#include <efi.h>
#include <efilib.h>
#include "uefi_api.h"

static EFI_SYSTEM_TABLE *gRandST = NULL;
static UINT32 gRandSeed = 0x1234ABCDu;

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

    if (gRandST != NULL && gRandST->RuntimeServices != NULL) {
        Status = uefi_call_wrapper(
            gRandST->RuntimeServices->GetTime,
            2,
            &Time,
            NULL
        );

        if (!EFI_ERROR(Status)) {
            UINT32 seed = 0;
            seed ^= ((UINT32)Time.Year << 16);
            seed ^= ((UINT32)Time.Month << 8);
            seed ^= (UINT32)Time.Day;
            seed ^= ((UINT32)Time.Hour << 24);
            seed ^= ((UINT32)Time.Minute << 16);
            seed ^= ((UINT32)Time.Second << 8);
            seed ^= (UINT32)Time.Nanosecond;
            gRandSeed ^= mix32(seed);
        }
    }

    gRandSeed = mix32(gRandSeed);
}

void uefi_random_stir(UINT32 value) {
    gRandSeed ^= mix32(value + 0x9E3779B9u);
    gRandSeed = mix32(gRandSeed);
}

UINT16 uefi_random16(void) {
    gRandSeed ^= gRandSeed << 13;
    gRandSeed ^= gRandSeed >> 17;
    gRandSeed ^= gRandSeed << 5;
    return (UINT16)(gRandSeed & 0xFFFFu);
}

void uefi_randomize_position(UINT16 *out_x, UINT16 *out_y, UINT16 max_x, UINT16 max_y) {
    EFI_TIME Time;
    EFI_STATUS Status;

    if (out_x == NULL || out_y == NULL || max_x == 0 || max_y == 0) {
        return;
    }

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

    *out_x = (UINT16)(uefi_random16() % max_x);
    *out_y = (UINT16)(uefi_random16() % max_y);
}
