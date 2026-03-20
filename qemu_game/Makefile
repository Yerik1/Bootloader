ASM=nasm
QEMU=qemu-system-i386

all: os-image.bin

boot.bin: boot.asm
	$(ASM) -f bin boot.asm -o boot.bin

stage.bin: stage.asm game.asm input.asm random.asm render.asm
	$(ASM) -f bin stage.asm -o stage.bin

os-image.bin: boot.bin stage.bin
	cat boot.bin stage.bin > os-image.bin
	truncate -s 1474560 os-image.bin

run: os-image.bin
	$(QEMU) -drive format=raw,file=os-image.bin,if=floppy

clean:
	rm -f *.bin
