# ARMv8 Startup Example Makefile
#
# Copyright (C) ARM Limited, 2013. All rights reserved.
#
# This makefile is intended for use with GNU make
# This example is intended to be built with the Arm GNU Toolchain for AArch64

TOOLCHAIN ?= /usr/local/src/arm-gnu-toolchain-13.3.rel1-x86_64-aarch64-none-elf/bin
CROSS ?= $(TOOLCHAIN)/aarch64-none-elf-

ARCHFLAGS= -march=armv8-a -mstrict-align -mgeneral-regs-only
ASFLAGS= -gdwarf-3 -c $(ARCHFLAGS)
CFLAGS=  -gdwarf-3 -c $(ARCHFLAGS) -I"./headers" -O1 -ffreestanding -fno-pie -fno-pic -fno-stack-protector
LDFLAGS= -nostartfiles --specs=rdimon.specs -Wl,--build-id=none -Wl,--entry=start64 -Wl,--no-warn-rwx-segments

CC= $(CROSS)gcc
AS= $(CROSS)gcc
LD= $(CROSS)gcc

GIC?=	GICV3

ifeq "$(GIC)" "GICV4"
	CFLAGS += -DGICV4=TRUE
endif

ifeq "$(DEBUG)" "TRUE"
    CFLAGS += -DDEBUG
endif

# Select build rules based on Windows or Unix
ifdef WINDIR
DONE=@if exist $(1) if exist $(2) echo Build completed.
RM=if exist $(1) del /q $(1)
SHELL=$(WINDIR)\system32\cmd.exe
else
ifdef windir
DONE=@if exist $(1) if exist $(2) echo Build completed.
RM=if exist $(1) del /q $(1)
SHELL=$(windir)\system32\cmd.exe
else
DONE=@if [ -f $(1) ]; then if [ -f $(2) ]; then echo Build completed.; fi; fi
RM=rm -f $(1)
endif
endif

all: image_basic.axf image_lpi.axf image_gicv31.axf
	$(call DONE,$(EXECUTABLE))

CSCOPE = cscope
TAGS = ctags

gicv4: image_vlpi.axf image_vsgi.axf

rebuild: clean all

clean:
	$(call RM,*.o)
	$(call RM,cscope*)
	$(call RM,tags)
	$(call RM,image_basic.axf)
	$(call RM,image_lpi.axf)
	$(call RM,image_gicv31.axf)
	$(call RM,image_vlpi.axf)
	$(call RM,image_vsgi.axf)

cscope:
	@find . -name '*.[hcsS]' -print > cscope.files
	@cscope -bkqu
.PHONY:cscope

tags:
	@find . -name '*.[hcsS]' -print | xargs $(TAGS) -a
.PHONY:tags

main_basic.o: ./src/main_basic.c
	$(CC) ${CFLAGS} ./src/main_basic.c

main_gicv31.o: ./src/main_gicv31.c
	$(CC) ${CFLAGS} ./src/main_gicv31.c

main_lpi.o: ./src/main_lpi.c
	$(CC) ${CFLAGS} ./src/main_lpi.c

main_vlpi.o: ./src/main_vlpi.c
	$(CC) ${CFLAGS} ./src/main_vlpi.c

main_vsgi.o: ./src/main_vsgi.c
	$(CC) ${CFLAGS} ./src/main_vsgi.c

gicv3_basic.o: ./src/gicv3_basic.c
	$(CC) ${CFLAGS} ./src/gicv3_basic.c

gicv3_lpis.o: ./src/gicv3_lpis.c
	$(CC) ${CFLAGS} ./src/gicv3_lpis.c

gicv4_virt.o: ./src/gicv4_virt.c
	$(CC) ${CFLAGS} ./src/gicv4_virt.c

system_counter.o: ./src/system_counter.c
	$(CC) ${CFLAGS} ./src/system_counter.c

sp804_timer.o: ./src/sp804_timer.c
	$(CC) ${CFLAGS} ./src/sp804_timer.c

runtime.o: ./src/runtime.c
	$(CC) ${CFLAGS} ./src/runtime.c

startup.o: ./src/startup.s
	$(AS) ${ASFLAGS} ./src/startup.s

startup_virt.o: ./src/startup_virt.s
	$(AS) ${ASFLAGS} ./src/startup_virt.s

secondary_virt.o: ./src/secondary_virt.s
	$(AS) ${ASFLAGS} ./src/secondary_virt.s

el3_vectors.o: ./src/el3_vectors.s
	$(AS) ${ASFLAGS} ./src/el3_vectors.s

generic_timer.o: ./src/generic_timer.s
	$(AS) ${ASFLAGS} ./src/generic_timer.s

gicv3_cpuif.o: ./src/gicv3_cpuif.S
	$(AS) ${ASFLAGS} ./src/gicv3_cpuif.S

image_basic.axf: LDSCRIPT = linker.ld
image_basic.axf: main_basic.o generic_timer.o system_counter.o sp804_timer.o runtime.o startup.o gicv3_basic.o gicv3_cpuif.o el3_vectors.o linker.ld
	$(LD) $(LDFLAGS) -Wl,-T,$(LDSCRIPT) -o $@ $(filter %.o,$^)

image_gicv31.axf: LDSCRIPT = linker.ld
image_gicv31.axf: main_gicv31.o runtime.o startup.o gicv3_basic.o gicv3_cpuif.o el3_vectors.o linker.ld
	$(LD) $(LDFLAGS) -Wl,-T,$(LDSCRIPT) -o $@ $(filter %.o,$^)

image_lpi.axf: LDSCRIPT = linker.ld
image_lpi.axf: main_lpi.o generic_timer.o system_counter.o runtime.o startup.o gicv3_basic.o gicv3_lpis.o gicv3_cpuif.o el3_vectors.o linker.ld
	$(LD) $(LDFLAGS) -Wl,-T,$(LDSCRIPT) -o $@ $(filter %.o,$^)

image_vlpi.axf: LDSCRIPT = linker_virt.ld
image_vlpi.axf: main_vlpi.o generic_timer.o system_counter.o runtime.o startup_virt.o secondary_virt.o gicv3_basic.o gicv4_virt.o gicv3_lpis.o gicv3_cpuif.o el3_vectors.o linker_virt.ld
	$(LD) $(LDFLAGS) -Wl,-T,$(LDSCRIPT) -o $@ $(filter %.o,$^)

image_vsgi.axf: LDSCRIPT = linker_virt.ld
image_vsgi.axf: main_vsgi.o generic_timer.o system_counter.o runtime.o startup_virt.o secondary_virt.o gicv3_basic.o gicv4_virt.o gicv3_lpis.o gicv3_cpuif.o el3_vectors.o linker_virt.ld
	$(LD) $(LDFLAGS) -Wl,-T,$(LDSCRIPT) -o $@ $(filter %.o,$^)
