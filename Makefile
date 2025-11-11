ASM = nasm
ASM_FLAGS = -f bin

BootEFI = HDA_DRIVE/efi/boot/bootx64.efi
BadApple = HDA_DRIVE/programs/bad_apple.bin
FrameData = HDA_DRIVE/frame_data/CompressedFrameData.bin

Converter = video_converter/bin/converter.exe
InputPath/Pattern = image_sequence/bad_apple_

.PHONY: makefile run

all: $(BootEFI) $(BadApple) | $(FrameData)

$(BootEFI): UEFI/efi.asm
	-mkdir $(subst /,\\,$(dir $@))
	$(ASM) $(ASM_FLAGS) -o$@ $^

$(BadApple): src/main.asm src/*.asm
	-mkdir $(subst /,\\,$(dir $@))
	$(ASM) $(ASM_FLAGS) -o$@ $<

$(FrameData): $(Converter)
	-mkdir $(subst /,\\,$(dir $@))
	$(Converter) $(InputPath/Pattern) $(dir $(FrameData))/CompressedFrameData.bin

$(Converter): video_converter/converter.cpp
	g++ video_converter/converter.cpp -o$@ -I"video_converter/include" -L"video_converter/lib" -lopencv_core -lopencv_imgproc -lopencv_imgcodecs

run: all
	qemu-system-x86_64 \
	-bios ovmf-x64/OVMF-pure-efi.fd \
	-drive format=raw,file=fat::rw::HDA_DRIVE \
	-m 100M \
	-monitor stdio \
	-no-reboot -d cpu_reset,int -D log.txt
