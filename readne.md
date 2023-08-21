https://github.com/microsoft/WSL/issues/6389 => bochs wsl debug

Bootloader Entry Point: In the x86 architecture, when a computer boots up, the BIOS loads the initial code from a bootable device, such as a floppy disk or a hard drive, to a specific memory location. For bootable floppy disks, the BIOS loads the first sector (512 bytes) of the disk to memory address 0x7C00. This memory location serves as the entry point for the bootloader code.

Execution Start: The code located at memory address 0x7C00 is the first code that gets executed when the computer boots up. This code initializes the system, sets up the environment, and often loads the rest of the operating system kernel or application.

Limitation on Bootloader Size: The size of the bootloader code loaded into memory address 0x7C00 is limited to 512 bytes, which corresponds to one sector on a disk. This limitation is due to the BIOS loading mechanism. As a result, bootloader developers need to carefully manage their code and consider strategies like chainloading to load additional code if necessary.