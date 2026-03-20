# Directorios de headers de GNU-EFI.
EFIINC=/usr/include/efi
EFIARCHINC=/usr/include/efi/x86_64

# Objeto de arranque y linker script que GNU-EFI usa para enlazar
# correctamente una aplicación UEFI.
CRT0=/usr/lib/crt0-efi-x86_64.o
LDS=/usr/lib/elf_x86_64_efi.lds

# Directorios de bibliotecas de GNU-EFI.
GNUEFILIB=/usr/lib
GNUEFILIB2=/usr/lib/gnuefi

# Flags de compilación:
# -fpic           : código independiente de posición.
# -fshort-wchar   : wchar_t de 2 bytes, requerido por UEFI.
# -mno-red-zone   : evita usar red zone en x86_64.
# -ffreestanding  : indica entorno sin libc convencional.
CFLAGS=-I$(EFIINC) -I$(EFIARCHINC) -fpic -fshort-wchar -mno-red-zone -Wall -ffreestanding

# Flags de enlazado específicos para binarios UEFI.
LDFLAGS=-nostdlib -znocombreloc -T $(LDS) -shared -Bsymbolic -L$(GNUEFILIB) -L$(GNUEFILIB2)
LIBS=-lefi -lgnuefi

# Firmware UEFI para QEMU (OVMF).
OVMF_CODE=/usr/share/OVMF/OVMF_CODE_4M.fd
OVMF_VARS_TEMPLATE=/usr/share/OVMF/OVMF_VARS_4M.fd

# Carpeta donde se construye la imagen de disco virtual.
IMGDIR=../uefi-test
IMG=$(IMGDIR)/uefi_disk.img
VARS=$(IMGDIR)/OVMF_VARS_4M.fd

# Regla por defecto: generar el ejecutable UEFI final.
all: BOOTX64.EFI

main2.o: main2.c uefi_api.h
	gcc $(CFLAGS) -c main2.c -o main2.o

uefi_api.o: uefi_api.c uefi_api.h
	gcc $(CFLAGS) -c uefi_api.c -o uefi_api.o

uefi_input.o: uefi_input.c uefi_api.h
	gcc $(CFLAGS) -c uefi_input.c -o uefi_input.o

uefi_random.o: uefi_random.c uefi_api.h
	gcc $(CFLAGS) -c uefi_random.c -o uefi_random.o

game_entry.o: game_entry.asm
	nasm -f elf64 game_entry.asm -o game_entry.o

main.so: main2.o uefi_api.o uefi_input.o uefi_random.o game_entry.o
	ld $(LDFLAGS) $(CRT0) main2.o uefi_api.o uefi_input.o uefi_random.o game_entry.o $(LIBS) -o main.so

# ------------------------------------------------------------
# Conversión a ejecutable UEFI
# ------------------------------------------------------------
# objcopy toma secciones relevantes del ELF y las transforma en
# un ejecutable PE/COFF que UEFI puede cargar.
# ------------------------------------------------------------
BOOTX64.EFI: main.so
	objcopy \
		-j .text -j .sdata -j .data -j .dynamic -j .dynsym \
		-j .rel -j .rela -j .reloc \
		--target=efi-app-x86_64 main.so BOOTX64.EFI

# ------------------------------------------------------------
# Crear imagen de disco FAT vacía
# ------------------------------------------------------------
# Se genera un archivo de 64 MB y se formatea como FAT.
# Luego se crean los directorios estándar EFI/BOOT.
# ------------------------------------------------------------
$(IMG):
	mkdir -p $(IMGDIR)
	dd if=/dev/zero of=$(IMG) bs=1M count=64
	mformat -i $(IMG) -F ::
	mmd -i $(IMG) ::/EFI
	mmd -i $(IMG) ::/EFI/BOOT

# Copiar el ejecutable UEFI a la ruta estándar de arranque.
image: BOOTX64.EFI $(IMG)
	mcopy -o -i $(IMG) BOOTX64.EFI ::/EFI/BOOT/BOOTX64.EFI

# Crear copia editable de OVMF_VARS.
# Esto evita modificar la plantilla original del firmware.
vars:
	mkdir -p $(IMGDIR)
	cp $(OVMF_VARS_TEMPLATE) $(VARS)

# ------------------------------------------------------------
# Ejecutar en QEMU
# ------------------------------------------------------------
# - OVMF_CODE: firmware UEFI de solo lectura.
# - VARS     : variables UEFI persistentes.
# - IMG      : disco con BOOTX64.EFI.
# ------------------------------------------------------------
run: image vars
	qemu-system-x86_64 \
	  -drive if=pflash,format=raw,readonly=on,file=$(OVMF_CODE) \
	  -drive if=pflash,format=raw,file=$(VARS) \
	  -drive file=$(IMG),format=raw,if=ide

# Limpieza básica de artefactos de compilación.
clean:
	rm -f *.o *.so *.EFI
	rm -f $(VARS)

# Limpieza completa, incluyendo la imagen de disco.
distclean: clean
	rm -f $(IMG)
