 export CFLAGS = -std=c99 -g -ffreestanding -nostdlib
export ASMFLAGS =
export CC = gcc
export LD = gcc
export ASM = nasm
export LINKFLAGS =
export LIBS =

export TARGET = i686-elf
export TARGET_ASM = nasm
export TARGET_ASMFLAGS =
export TARGET_CFLAGS = -std=c99 -g #-O2
export TARGET_CC = $(TARGET)-gcc
export TARGET_CXX = $(TARGET)-g++
export TARGET_LD = $(TARGET)-gcc
export TARGET_LINKFLAGS =
export TARGET_LIBS =

export BUILD_DIR = $(abspath build)

ASM=nasm

SRC_DIR=src
BUILD_DIR=build


LDFLAGS = -T linker.ld

.PHONY: all floppy_img kernel bootloader clean always

# Floppy image 
floppy_img: $(BUILD_DIR)/main_floppy.img

$(BUILD_DIR)/main_floppy.img: bootloader kernel stage2 # bootloader, kernel are dependencies/prereqs
	# bs is sector size "/dev/zero is a special file in Unix-like operating systems that provides as many null characters (ASCII NUL, 0x00) as are read from it."
	dd if=/dev/zero of=$(BUILD_DIR)/main_floppy.img bs=512 count=2880 # create a file (main_floppy.img) full of zeros of size 512*2880=1.44mb (Bytes*Number Sectors)
	mkfs.fat -F 12 -n "MaVolumeLabelBro" $(BUILD_DIR)/main_floppy.img
	# The next line overwrites the fat12 headers in the floppy disk so in boot.asm we have to manually redefine them again
	dd if=$(BUILD_DIR)/bootloader.bin of=$(BUILD_DIR)/main_floppy.img conv=notrunc # Copy bootloader binary into first sector of floppy disk, notrunc means dont truncate file ie dont delete most of our floppy disk lol
	mcopy -i $(BUILD_DIR)/main_floppy.img $(BUILD_DIR)/stage2.bin "::stage2.bin"
	mcopy -i $(BUILD_DIR)/main_floppy.img $(BUILD_DIR)/kernel.bin "::kernel.bin" # copy kernel.bin to root directory of floppy disk and name it "kernel.bin" using msdos format with mcopy

# Bootloader
bootloader: $(BUILD_DIR)/bootloader.bin
# compile bootloader asm (boot.asm) to binary
$(BUILD_DIR)/bootloader.bin: always 
	$(ASM) $(SRC_DIR)/bootloader/boot.asm -f bin -o $(BUILD_DIR)/bootloader.bin 

# stage2: $(BUILD_DIR)/stage2.bin
# # compile stage2 asm (main.asm) to binary
# $(BUILD_DIR)/stage2.bin: always 
# 	$(ASM) $(SRC_DIR)/bootloader/stage2/main.asm -f elf -o $(BUILD_DIR)/stage2.bin 
stage2: $(BUILD_DIR)/stage2.bin

$(BUILD_DIR)/stage2.bin: always
	@$(MAKE) -C src/bootloader/stage2 BUILD_DIR=$(abspath $(BUILD_DIR))


# Kernel 
kernel: $(BUILD_DIR)/kernel.bin
# compile kernel assmebly (main.asm) to binary
$(BUILD_DIR)/kernel.bin: always
	$(ASM) $(SRC_DIR)/kernel/main.asm -f bin -o $(BUILD_DIR)/kernel.bin


# Always
always:
	mkdir -p $(BUILD_DIR) # create build/ if it doesnt exist

clean:
	@$(MAKE) -C src/bootloader/stage2 BUILD_DIR=$(abspath $(BUILD_DIR)) clean
	rm -rf $(BUILD_DIR)/*
