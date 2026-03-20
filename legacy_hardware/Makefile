ASM=nasm
QEMU=qemu-system-i386

all: os-image.bin

stage.bin: stage.asm game.asm input.asm random.asm render.asm
	$(ASM) -f bin stage.asm -o stage.bin

boot.asm: boot.asm.in stage.bin
	@STAGE_SIZE=$$(stat -c%s stage.bin); \
	STAGE_SECTORS=$$(( ($$STAGE_SIZE + 511) / 512 )); \
	PARTITION_SECTORS=$$(( $$STAGE_SECTORS + 1 )); \
	echo "stage.bin bytes: $$STAGE_SIZE"; \
	echo "stage sectors: $$STAGE_SECTORS"; \
	echo "partition sectors: $$PARTITION_SECTORS"; \
	sed -e "s/_STAGE_SECTORS_/$$STAGE_SECTORS/" \
	    -e "s/_PARTITION_SECTORS_/$$PARTITION_SECTORS/" \
	    boot.asm.in > boot.asm

boot.bin: boot.asm
	$(ASM) -f bin boot.asm -o boot.bin

os-image.bin: boot.bin stage.bin
	cat boot.bin stage.bin > os-image.bin
	truncate -s 1474560 os-image.bin

run: os-image.bin
	$(QEMU) -drive format=raw,file=os-image.bin,if=ide

run-floppy: os-image.bin
	$(QEMU) -drive format=raw,file=os-image.bin,if=floppy

clean:
	rm -f *.bin boot.asm
