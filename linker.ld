OUTPUT_FORMAT("elf64-littleaarch64")
OUTPUT_ARCH(aarch64)
ENTRY(start64)

MEMORY
{
  SRAM (rwx) : ORIGIN = 0x04000000, LENGTH = 0x00040000
}

SECTIONS
{
  .text :
  {
    KEEP(*(BOOT))
    *(.text*)
    *(.rodata*)
    *(.eh_frame*)
    KEEP(*(VECTORS))
    KEEP(*(AArch64_GenericTimer))
    KEEP(*(v8_aarch64_gicv3_cpuif))
    KEEP(*(secondary_boot))
  } > SRAM

  .data :
  {
    *(.data*)
  } > SRAM

  .bss (NOLOAD) :
  {
    . = ALIGN(8);
    __bss_start__ = .;
    __bss_start = .;
    _bss_start = .;
    *(.bss*)
    *(COMMON)
    . = ALIGN(8);
    __bss_end__ = .;
    __bss_end = .;
    _bss_end = .;
  } > SRAM

  end = .;
  __end__ = .;

  __stack_top = 0x04028000;
  __stack_bottom = 0x04020000;
  __stack = __stack_top;
  _stack = __stack_top;

  /DISCARD/ :
  {
    *(.comment)
    *(.note.GNU-stack)
  }
}
