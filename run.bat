mkdir HDA_DRIVE\efi\boot
mkdir HDA_DRIVE\programs

nasm -f bin UEFI/efi.asm -o HDA_DRIVE/efi/boot/bootx64.efi

nasm -f bin src/run.asm -o HDA_DRIVE/programs/bad-apple.bin

qemu-system-x86_64 ^
-bios ovmf-x64/usr/share/edk2.git/ovmf-x64/OVMF-pure-efi.fd ^
-drive format=raw,file=fat::rw::HDA_DRIVE ^
-drive format=raw,file=ovmf-x64/usr/share/edk2.git/ovmf-x64/UefiShell.iso ^
-monitor stdio