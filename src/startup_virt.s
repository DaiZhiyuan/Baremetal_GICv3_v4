//==================================================================
// Armv8-A Startup Code
//
// Copyright (C) Arm Limited, 2019 All rights reserved.
//
// The example code is provided to you as an aid to learning when working
// with Arm-based technology, including but not limited to programming tutorials.
// Arm hereby grants to you, subject to the terms and conditions of this Licence,
// a non-exclusive, non-transferable, non-sub-licensable, free-of-charge licence,
// to use and copy the Software solely for the purpose of demonstration and
// evaluation.
// ------------------------------------------------------------

  .section  BOOT,"ax"
  .align 3

// ------------------------------------------------------------

  .global start64
  .type start64, @function
start64:

  // Clear registers
  // ---------------
  // This is primarily for RTL simulators, to avoid
  // possibility of X propagation

  MOV      x0, #0
  MOV      x1, #0
  MOV      x2, #0
  MOV      x3, #0
  MOV      x4, #0
  MOV      x5, #0
  MOV      x6, #0
  MOV      x7, #0
  MOV      x8, #0
  MOV      x9, #0
  MOV      x10, #0
  MOV      x11, #0
  MOV      x12, #0
  MOV      x13, #0
  MOV      x14, #0
  MOV      x15, #0
  MOV      x16, #0
  MOV      x17, #0
  MOV      x18, #0
  MOV      x19, #0
  MOV      x20, #0
  MOV      x21, #0
  MOV      x22, #0
  MOV      x23, #0
  MOV      x24, #0
  MOV      x25, #0
  MOV      x26, #0
  MOV      x27, #0
  MOV      x28, #0
  MOV      x29, #0
  MOV      x30, #0

  // Disable trapping of CPTR_EL3 accesses or use of Adv.SIMD/FPU
  // -------------------------------------------------------------

  MOV      x0, #0                           // Clear all trap bits
  MSR      CPTR_EL3, x0


  // Configure GIC CPU IF
  // -------------------
  // For processors that do not support legacy operation
  // these steps could be omitted.

  MSR      SCR_EL3, xzr                      // Ensure NS bit is clear
  ISB
  MOV      x0, #1
  MSR      ICC_SRE_EL3, x0					 // Enable System Register interface
  ISB
  MSR      ICC_SRE_EL1, x0


  // Now do the NS SRE bits
  MOV      x1, #1                            // Set NS bit, to access Non-secure registers
  MSR      SCR_EL3, x1
  ISB
  MSR      ICC_SRE_EL2, x0
  ISB
  MSR      ICC_SRE_EL1, x0

  // Configure SCR_EL3
  // ------------------
  // Have interrupts routed to EL3

  MOV      w1, #0              // Initial value of register is unknown
  ORR      w1, w1, #(1 << 11)  // Set ST bit (Secure EL1 can access CNTPS_TVAL_EL1, CNTPS_CTL_EL1 & CNTPS_CVAL_EL1)
  ORR      w1, w1, #(1 << 10)  // Set RW bit (EL1 is AArch64, as this is the Secure world)
  ORR      w1, w1, #(1 << 3)   // Set EA bit (SError routed to EL3)
  ORR      w1, w1, #(1 << 2)   // Set FIQ bit (FIQs routed to EL3)
  ORR      w1, w1, #(1 << 1)   // Set IRQ bit (IRQs routed to EL3)
  MSR      SCR_EL3, x1

  // Ensure changes to system register are visible
  ISB

  // Which core am I
  // ----------------

  MRS      x0, MPIDR_EL1
  MOV      x1, #0xFFFFFF
  AND      x0, x0, x1                        // Mask off to leave Aff2.Aff1.Aff0
  CBZ      x0, primary                       // If core 0, run the primary init code
  MOV      x1, #0x100
  CMP      x0, x1                            // If core 1, run the secondary init code
  .global  secondary
  B.EQ     secondary

  // Otherwise go to sleep
sleep:
  WFI
  B        sleep

// ------------------------------------------------------------
// Primary core
// ------------------------------------------------------------

primary:

  // Install vector table
  // ---------------------
  .global  el3_vectors
  LDR      x0, =el3_vectors
  MSR      VBAR_EL3, x0


  // Enable Interrupts
  // ------------------
  MSR      DAIFClr, 0x3


  // Branch to scatter loading and C library init code
  // -------------------------------------------------
  .global  __main
  B        __main


// ------------------------------------------------------------
// Helper functions
// ------------------------------------------------------------

  .type getAffinity, "function"
  .cfi_startproc
  .global getAffinity
getAffinity:
  MRS      x0, MPIDR_EL1
  UBFX     x1, x0, #32, #8      // rd, rn, #p, #n ==> x1 = x0[39:31]
  BFI      w0, w1, #24, #8      // rd, rn, #p, #n ==> w0[31:24] = w1[7:0]
  RET
  .cfi_endproc

// ------------------------------------------------------------
// End of file
// ------------------------------------------------------------
