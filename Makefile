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

# Keep objects for each GIC/DEBUG configuration separate.  The GICV4 define
# changes the Redistributor register layout, so sharing objects between
# configurations produces silently broken images.
CONFIG= $(GIC)$(if $(filter TRUE,$(DEBUG)),-debug,)
OBJDIR= build/$(CONFIG)

# Select build rules based on Windows or Unix
ifdef WINDIR
RM=del /q
RMDIR=rmdir /s /q
SHELL=$(WINDIR)\system32\cmd.exe
else
ifdef windir
RM=del /q
RMDIR=rmdir /s /q
SHELL=$(windir)\system32\cmd.exe
else
RM=rm -f
RMDIR=rm -rf
endif
endif

BASIC_OBJS=  $(OBJDIR)/main_basic.o $(OBJDIR)/generic_timer.o \
             $(OBJDIR)/system_counter.o $(OBJDIR)/sp804_timer.o \
             $(OBJDIR)/runtime.o $(OBJDIR)/startup.o \
             $(OBJDIR)/gicv3_basic.o $(OBJDIR)/gicv3_cpuif.o \
             $(OBJDIR)/el3_vectors.o

GICV31_OBJS= $(OBJDIR)/main_gicv31.o $(OBJDIR)/runtime.o \
             $(OBJDIR)/startup.o $(OBJDIR)/gicv3_basic.o \
             $(OBJDIR)/gicv3_cpuif.o $(OBJDIR)/el3_vectors.o

LPI_OBJS=    $(OBJDIR)/main_lpi.o $(OBJDIR)/generic_timer.o \
             $(OBJDIR)/system_counter.o $(OBJDIR)/runtime.o \
             $(OBJDIR)/startup.o $(OBJDIR)/gicv3_basic.o \
             $(OBJDIR)/gicv3_lpis.o $(OBJDIR)/gicv3_cpuif.o \
             $(OBJDIR)/el3_vectors.o

VLPI_OBJS=   $(OBJDIR)/main_vlpi.o $(OBJDIR)/generic_timer.o \
             $(OBJDIR)/system_counter.o $(OBJDIR)/runtime.o \
             $(OBJDIR)/startup_virt.o $(OBJDIR)/secondary_virt.o \
             $(OBJDIR)/gicv3_basic.o $(OBJDIR)/gicv4_virt.o \
             $(OBJDIR)/gicv3_lpis.o $(OBJDIR)/gicv3_cpuif.o \
             $(OBJDIR)/el3_vectors.o

VSGI_OBJS=   $(OBJDIR)/main_vsgi.o $(OBJDIR)/generic_timer.o \
             $(OBJDIR)/system_counter.o $(OBJDIR)/runtime.o \
             $(OBJDIR)/startup_virt.o $(OBJDIR)/secondary_virt.o \
             $(OBJDIR)/gicv3_basic.o $(OBJDIR)/gicv4_virt.o \
             $(OBJDIR)/gicv3_lpis.o $(OBJDIR)/gicv3_cpuif.o \
             $(OBJDIR)/el3_vectors.o

all: image_basic.axf image_lpi.axf image_gicv31.axf
	@echo Build completed.

CSCOPE = cscope
TAGS = ctags

gicv4: image_vlpi.axf image_vsgi.axf

rebuild: clean all

clean:
	$(RMDIR) build
	$(RM) *.o
	$(RM) cscope*
	$(RM) tags
	$(RM) image_basic.axf
	$(RM) image_lpi.axf
	$(RM) image_gicv31.axf
	$(RM) image_vlpi.axf
	$(RM) image_vsgi.axf

cscope:
	@find . -name '*.[hcsS]' -print > cscope.files
	@cscope -bkqu
.PHONY:cscope

tags:
	@find . -name '*.[hcsS]' -print | xargs $(TAGS) -a
.PHONY:tags

$(OBJDIR)/%.o: ./src/%.c $(wildcard headers/*.h)
	@mkdir -p $(OBJDIR)
	$(CC) ${CFLAGS} -o $@ $<

$(OBJDIR)/%.o: ./src/%.s
	@mkdir -p $(OBJDIR)
	$(AS) ${ASFLAGS} -o $@ $<

$(OBJDIR)/%.o: ./src/%.S
	@mkdir -p $(OBJDIR)
	$(AS) ${ASFLAGS} -o $@ $<

image_basic.axf: LDSCRIPT = linker.ld
image_basic.axf: $(BASIC_OBJS) linker.ld
	$(LD) $(LDFLAGS) -Wl,-T,$(LDSCRIPT) -o $@ $(BASIC_OBJS)

image_gicv31.axf: LDSCRIPT = linker.ld
image_gicv31.axf: $(GICV31_OBJS) linker.ld
	$(LD) $(LDFLAGS) -Wl,-T,$(LDSCRIPT) -o $@ $(GICV31_OBJS)

image_lpi.axf: LDSCRIPT = linker.ld
image_lpi.axf: $(LPI_OBJS) linker.ld
	$(LD) $(LDFLAGS) -Wl,-T,$(LDSCRIPT) -o $@ $(LPI_OBJS)

image_vlpi.axf: LDSCRIPT = linker_virt.ld
image_vlpi.axf: $(VLPI_OBJS) linker_virt.ld
	$(LD) $(LDFLAGS) -Wl,-T,$(LDSCRIPT) -o $@ $(VLPI_OBJS)

image_vsgi.axf: LDSCRIPT = linker_virt.ld
image_vsgi.axf: $(VSGI_OBJS) linker_virt.ld
	$(LD) $(LDFLAGS) -Wl,-T,$(LDSCRIPT) -o $@ $(VSGI_OBJS)
