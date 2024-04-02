// GICv3 Physical LPI Example
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

#include <stdio.h>
#include <string.h>
#include "gicv3_basic.h"
#include "gicv3_lpis.h"
#include "gicv4_virt.h"

extern uint32_t getAffinity(void);
uint32_t initGIC(void);
uint32_t checkGICModel(void);

volatile unsigned int flag;

// --------------------------------------------------------
// These locations are based on the memory map of the Base Platform model
// refs: Fast Models Version 11.20 Reference Guide 
//     Table 8-6: Base Platform memory map.

#define CONFIG_TABLE      (0x80020000)
#define PENDING0_TABLE    (0x80030000)
#define PENDING1_TABLE    (0x80040000)

#define CMD_QUEUE         (0x80050000)
#define DEVICE_TABLE      (0x80060000)
#define COLLECTION_TABLE  (0x80070000)

#define VPE_TABLE         (0x80080000)
#define VCONFIG_TABLE     (0x80090000)
#define VPENDING_TABLE    (0x800A0000)

#define ITT               (0x800B0000)

#define ITS_BASE_ADDR     (0x2F020000)

// --------------------------------------------------------

int main(void)
{
  uint32_t type, entry_size;
  uint32_t rd0, rd1, target_rd0, target_rd1;

  //
  // Configure the interrupt controller
  //

  rd0 = initGIC();
  
  //
  // The example sends the vLPI to 0.0.1.0, so we also need its RD number
  //

  rd1 = getRedistID(0x00000100);

  //
  // Before we start, ensure the tables initially contain zeros
  //

  memset((void*)VCONFIG_TABLE, 0, 8192);
  memset((void*)VPENDING_TABLE, 0, 8192);

  //
  // Set up Redistributor structures used for LPIs
  // LPI configuration is global.
  // Each Redistributor maintains entries in a separate LPI Pending table.
  //    InnerCache & OuterCache : Device-nGnRnE
  //    shareability : Non-shareable
  setLPIConfigTableAddr(rd0, CONFIG_TABLE, GICV3_LPI_DEVICE_nGnRnE /*Attributes*/, 15 /* Number of ID bits */);
  setLPIPendingTableAddr(rd0, PENDING0_TABLE, GICV3_LPI_DEVICE_nGnRnE /*Attributes*/, 15 /* Number of ID bits */);
  enableLPIs(rd0);
  
  setLPIConfigTableAddr(rd1, CONFIG_TABLE, GICV3_LPI_DEVICE_nGnRnE /*Attributes*/, 15 /* Number of ID bits */);
  setLPIPendingTableAddr(rd1, PENDING1_TABLE, GICV3_LPI_DEVICE_nGnRnE /*Attributes*/, 15 /* Number of ID bits */);
  enableLPIs(rd1);

  setVPEConfTableAddr(rd0, VPE_TABLE, 0 /*attributes*/, 1 /*num_pages*/);
  setVPEConfTableAddr(rd1, VPE_TABLE, 0 /*attributes*/, 1 /*num_pages*/);


  //
  // Configure virtual interrupt
  //
  
  configureVLPI((uint8_t*)(VCONFIG_TABLE), 8192 /*INTID*/, GICV3_LPI_ENABLE, 0 /*Priority*/);


  //
  // Configure physical doorbell interrupt
  //

  configureLPI(rd0, 8192 /*INTID*/, GICV3_LPI_ENABLE, 0 /*Priority*/);   // We'll use this as a Default Doorbell


  //
  // Configure ITS
  //

  setITSBaseAddress((void*)ITS_BASE_ADDR);
  
  // Check that the model has been launched with the correct configuration
  if (checkGICModel() != 0)
    return 1;

  // Allocated memory for the ITS command queue
  initITSCommandQueue(CMD_QUEUE, GICV3_ITS_CQUEUE_VALID /*Attributes*/, 1 /*num_pages*/);

  // Allocate Device table
  setITSTableAddr(0 /*index*/,
                  DEVICE_TABLE /* addr */,
                  (GICV3_ITS_TABLE_PAGE_VALID | GICV3_ITS_TABLE_PAGE_DIRECT | GICV3_ITS_TABLE_PAGE_DEVICE_nGnRnE),
                  GICV3_ITS_TABLE_PAGE_SIZE_4K,
                  16 /*num_pages*/);

  // Allocate Collection table
  setITSTableAddr(1 /*index*/,
                  COLLECTION_TABLE /* addr */,
                  (GICV3_ITS_TABLE_PAGE_VALID | GICV3_ITS_TABLE_PAGE_DIRECT | GICV3_ITS_TABLE_PAGE_DEVICE_nGnRnE),
                  GICV3_ITS_TABLE_PAGE_SIZE_4K,
                  16 /*num_pages*/);


  // Allocate vPE table
  setITSTableAddr(2 /*index*/,
                  VPE_TABLE /* addr */,
                  (GICV3_ITS_TABLE_PAGE_VALID | GICV3_ITS_TABLE_PAGE_DIRECT | GICV3_ITS_TABLE_PAGE_DEVICE_nGnRnE),
                  GICV3_ITS_TABLE_PAGE_SIZE_4K,
                  1 /*num_pages*/);

  // NOTE: This example assumes that the following parameters are set on the Base Platform Model:
  // gic_distributor.GITS_BASER0-type=1
  // gic_distributor.GITS_BASER1-type=4
  // gic_distributor.GITS_BASER2-type=2

  // Enable the ITS
  enableITS();

  //
  // Create ITS mapping
  //

  // Get IDs in format used by ITS commands
  target_rd0 = getRdProcNumber(rd0);
  target_rd1 = getRdProcNumber(rd1);

  // Set up a mapping
	
 /*
    gic_distributor.ITS0 DECODE 0x00000000 0000000000000008:0000000000000001:80000000800b0000:0000000000000000 MAPD
    gic_distributor.ITS0 EXEC MAPD VALID:1 DEVICE:0x00000000 ITT_ADDRESS:0x00000000800b0000 SIZE:0x01
    gic_distributor.ITS0 TABLE_RD DEVICE_ID:0x00000000 FAULT
    gic_distributor.ITS0 TABLE_WR DEVICE_MAP DEVICE_ID:0x00000000 ITT_ADDRESS:0x00000000800b0000 INTERRUPT_BITS:0x02
    gic_distributor.ITS0 EXEC_END MAPD
 */
  itsMAPD(0 /*DeviceID*/, ITT /*addr of ITT*/, 2 /*bit width of EventID*/);         // Map a DeviceID to a ITT

  /*
    gic_distributor.ITS0 DECODE 0x00000020 0000000080090329:0000000000002000:8000000000000000:00000000800a000e VMAPP
    gic_distributor.ITS0 TABLE_WR VCPU_MAP VCPU:0x0000 TARGET_ADDRESS:0x000000002f100000 VPT_ADDRESS:0x00000000800a0000
    gic_distributor.ITS0 EXEC_END VMAPP
  */
  itsVMAPP(0 /*vpeid*/, target_rd0, VCONFIG_TABLE, VPENDING_TABLE, 1 /*alloc*/, 1 /*v*/, 8192 /*default doorbell*/, 14 /*size*/);

  /*
    gic_distributor.ITS0 DECODE 0x00000040 000000000000002e:0000000000000000:0000000000000000:0000000000000000 INVDB
    gic_distributor.ITS0 TABLE_RD VCPU VCPU:0x0000 TARGET:0x000000002f100000 VPT_ADDRESS:0x000000000000800a VINTERRUPT_BITS:0x0f
    gic_distributor.ITS0 EXEC_END INVDB
  */
  itsINVDB(0 /*vpeid*/);

  /*
    gic_distributor.ITS0 DECODE 0x00000060 000000000000002a:0000000000000000:000003ff00002000:0000000000000000 VMAPVI
    gic_distributor.ITS0 EXEC VMAPVI DEVICE:0x0000 VCPU:0x0000 ID:0x00000000 VIRTUAL_ID:0x00002000 PHYSICAL_ID:0x000003ff
    gic_distributor.ITS0 TABLE_RD DEVICE DEVICE_ID:0x00000000 ITT_ADDRESS:0x00000000800b0000 INTERRUPT_BITS:0x02
    gic_distributor.ITS0 TABLE_RD VCPU VCPU:0x0000 TARGET:0x000000002f100000 VPT_ADDRESS:0x000000000000800a VINTERRUPT_BITS:0x0f
    gic_distributor.ITS0 TABLE_WR ITT_VMAP DEVICE_ID:0x00000000 ITT_ADDRESS:0x00000000800b0000 ID:0x00000000 PHYSICAL_ID:0x000003ff VIRTUAL_ID:0x00002000 VCPU:0x0000
    gic_distributor.ITS0 EXEC_END VMAPVI
  */	
  itsVMAPTI(0 /*DeviceID*/, 0 /*EventID*/, 1023 /*individual doorbell*/, 0 /*vpeid*/, 8192 /*vINTID*/);

  /*
    gic_distributor.ITS0 DECODE 0x00000080 0000000000000025:0000000000000000:0000000000000000:0000000000000000 VSYNC
    gic_distributor.EXEC VSYNC VCPU:0x0000
    gic_distributor.TABLE_RD VCPU VCPU:0x0000 TARGET:0x000000002f100000 VPT_ADDRESS:0x000000000000800a VINTERRUPT_BITS:0x0f
    gic_distributor.ITS0 EXEC_END VSYNC
  */
  itsVSYNC(0 /*vpeid*/);

  //
  // Generate interrupt
  //

  printf("main(): Sending vLPI 8192 to vPEID 0\n");

  /*
    gic_distributor.ITS0 DECODE 0x000000a0 000000000000000c:0000000000000000:0000000000000000:0000000000000000 INV
    gic_distributor.ITS0 EXEC INV DEVICE:0x00000000 ID:0x00000000
    gic_distributor.ITS0 TABLE_RD DEVICE DEVICE_ID:0x00000000 ITT_ADDRESS:0x00000000800b0000 INTERRUPT_BITS:0x02
    gic_distributor.ITS0 TABLE_RD ITT_VLPI ITT_ADDRESS:0x00000000800b0000 ID:0x00000000 PHYSICAL_ID:0x00002000 VCPU:0x0000
    gic_distributor.ITS0 TABLE_RD VCPU VCPU:0x0000 TARGET:0x000000002f100000 VPT_ADDRESS:0x000000000000800a VINTERRUPT_BITS:0x0f
    gic_distributor.ITS0 EXEC_END INV
  */
  itsINV(0 /*DeviceID*/, 0 /*EventID*/);

  /*
    gic_distributor.ITS0 DECODE 0x000000c0 0000000000000003:0000000000000000:0000000000000000:0000000000000000 INT
    gic_distributor.ITS0 EXEC INT DEVICE:0x00000000 ID:0x00000000
    gic_distributor.ITS0 TABLE_RD DEVICE DEVICE_ID:0x00000000 ITT_ADDRESS:0x00000000800b0000 INTERRUPT_BITS:0x02
    gic_distributor.ITS0 TABLE_RD ITT_VLPI ITT_ADDRESS:0x00000000800b0000 ID:0x00000000 PHYSICAL_ID:0x00002000 VCPU:0x0000
    gic_distributor.ITS0 TABLE_RD VCPU VCPU:0x0000 TARGET:0x000000002f100000 VPT_ADDRESS:0x000000000000800a VINTERRUPT_BITS:0x0f
    gic_distributor.ITS0 EXEC_END INT
  */
  itsINT(0 /*DeviceID*/, 0 /*EventID*/);

  /* gic_distributor.rd_0_0_0_0 VSETPEND 0x00002000 VPT_ADDR 0x00000000800a0000 */

  // Wait for interrupt
  while(flag < 1)
  {
	  // Nothing
  }

  // Make vPE resident on RD1 (0.0.1.0)
  // 0.0.0.0 and 0.0.1.0 are within the same CommonLPIAff group
  makeResident(rd1, 0 /*vpeid*/, 1 /*g0*/, 1 /*g1*/);

  // NOTE:
  // This code assumes that the IRQ and FIQ exceptions
  // have been routed to the appropriate Exception level
  // and that the PSTATE masks are clear.  In this example
  // this is done in the startup_virt.s file


  printf("main(): Test end\n");

  // Semihosting halt will be called from 0.0.1.0
  while(1)
  {
	  // Nothing
  }

  return 1;
}

// --------------------------------------------------------

void fiqHandler(void)
{
  uint32_t ID;
  uint32_t group = 0;

  // Read the IAR to get the INTID of the interrupt taken
  ID = readIARGrp0();

  printf("FIQ: Received INTID %d\n", ID);

  switch (ID)
  {
    case 1021:
      printf("FIQ: Received Non-secure interrupt from the ITS\n");
      ID = readIARGrp1();
      printf("FIQ: Read INTID %d from IAR1\n", ID);
      group = 1;
      break;
    case 1023:
      printf("FIQ: Interrupt was spurious\n");
      return;
    default:
      printf("FIQ: Panic, unexpected INTID\n");
  }

  // Write EOIR to deactivate interrupt
  if (group == 0)
    writeEOIGrp0(ID);
  else
    writeEOIGrp1(ID);

  flag++;
  return;
}

// --------------------------------------------------------

uint32_t initGIC(void)
{
  uint32_t rd;

  // Set location of GIC
  setGICAddr((void*)0x2F000000 /*Distributor*/, (void*)0x2F100000 /*Redistributor*/);

  // Enable GIC
  enableGIC();

  // Get the ID of the Redistributor connected to this PE
  rd = getRedistID(getAffinity());

  // Mark this core as beign active
  wakeUpRedist(rd);

  // Configure the CPU interface
  // This assumes that the SRE bits are already set
  setPriorityMask(0xFF);
  enableGroup0Ints();
  enableGroup1Ints();
  enableNSGroup1Ints();  // This call only works as example runs at EL3

  return rd;
}

// --------------------------------------------------------

uint32_t checkGICModel(void)
{
  uint32_t type, entry_size;

  //
  // Check GICv4.1 is implemented
  //
  if (isGICv4x(0) != GICV3_v41)
  {
     printf("checkGICModel(): GITS_TYPER.{VLPIS,RVEPID}!={1,1}, GICv4.1 not supported\n");
     return 1;
  }

  //
  // Check the model used to identify RD's in ITS commands
  //
  if (getITSPTA() == 1)
  {
     printf("checkGICModel(): GITS_TYPER.PTA==1, this example expects PTA==0\n");
     return 1;
  }

   //
   // Check Individual doorbell interrupt^M
   //
#ifdef DEBUG
      printf("feature check: Individual doorbell interrupt %s\n", getITSNID() ? "not supported.":"supported.");
#endif
  
  //
  // Check the GITS_BASER<n> types
  //
  getITSTableType(0 /*index*/, &type, &entry_size);
  if (type != GICV3_ITS_TABLE_TYPE_DEVICE)
  {
    printf("checkGICModel() - GITS_BASER0 not expected value (seeing 0x%x, expected 0x%x).\n", type, GICV3_ITS_TABLE_TYPE_DEVICE);
    return 1;
  }

  getITSTableType(1 /*index*/, &type, &entry_size);
  if (type != GICV3_ITS_TABLE_TYPE_COLLECTION)
  {
    printf("checkGICModel() - GITS_BASER1 not expected value (seeing 0x%x, expected 0x%x).\n", type, GICV3_ITS_TABLE_TYPE_COLLECTION);
    return 1;
  }

  getITSTableType(2 /*index*/, &type, &entry_size);
  if (type != GICV3_ITS_TABLE_TYPE_VIRTUAL)
  {
    printf("checkGICModel() - GITS_BASER2 not expected value (seeing 0x%x, expected 0x%x).\n", type, GICV3_ITS_TABLE_TYPE_VIRTUAL);
    return 1;
  }
  
  //
  // Check whether the ITS thinks it shares the vPE Configuration Table with the RDs
  //
  if (itsSharedTableSupport() != 0x2)
  {
    printf("checkGICModel() - GITS_TYPER.SVE not expected value (seeing 0x%x, expected 0x2).\n", itsSharedTableSupport());
    return 1;
  }
  
  //
  // Check the CommonLPIAff group the ITS believes it shares the table with
  //
  if (itsGetAffinity() !=0)
  {
    printf("checkGICModel() - GITS_MPIDR does not report 0x0\n");
    return 1;
  }

  return 0;
}
