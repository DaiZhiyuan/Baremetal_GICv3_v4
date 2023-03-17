AArch64 Generic Interrupt Controller (v3/v4) Example
====================================================

Introduction
============
This example demonstrates the use of the Generic Interrupt Controller (GIC) in a baremetal environment.


Notice
=======
Copyright (C) Arm Limited, 2019-2021 All rights reserved.

The example code is provided to you as an aid to learning when working
with Arm-based technology, including but not limited to programming tutorials.
Arm hereby grants to you, subject to the terms and conditions of this Licence,
a non-exclusive, non-transferable, non-sub-licensable, free-of-charge licence,
to use and copy the Software solely for the purpose of demonstration and
evaluation.

You accept that the Software has not been tested by Arm therefore the Software
is provided 'as is', without warranty of any kind, express or implied. In no
event shall the authors or copyright holders be liable for any claim, damages
or other liability, whether in action or contract, tort or otherwise, arising
from, out of or in connection with the Software or the use of Software.


Requirements
============
* Arm Development Studio Gold edition (GICv3.0)
* Arm Development Studio Platinum edition (GICv3.1 and GICv4.1)


File list
=========
 <root>
  |-> headers
  |   |-> generic_timer.h
  |   |-> gicv3_basic.h
  |   |-> gicv3_lpi.h
  |   |-> gicv3_registers.h
  |   |-> gicv4_virt.h
  |   |-> system_counter.h
  |
  |-> src
  |   |-> el3_vectors.s      Minimal vector table
  |   |-> generic_timer.s    Helper functions for Generic Timer
  |   |-> gicv3_basic.c      Helper functions for GICv3.1
  |   |-> gicv3_lpis.c       Helper functions for GICv3.1 physical LPIs
  |   |-> gicv4_virt.c       Helper functions for GICv4.1 virtualization
  |   |-> main_basic.c       Example showing usage of SPIs and PPIs.
  |   |-> main_gicv31.c      Example showing usage of GICv3.1 Extended PPI and SPI rangess.
  |   |-> main_lpi.c         Example showing usage of physical LPIs.
  |   |-> main_vlpi.c        Example showing usage of GICv4.1 virtual LPIs.
  |   |-> main_vsgi.c        Example showing usage of GICv4.1 virtual SGIs.
  |   |-> secondary_virt.s   Boot code for secondary core, used by the GICv4.1 example.
  |   |-> startup.s          Minimal reset handler.
  |   |-> startup_virt.s     Minimal reset handler, used by the GICv4.1 example.
  |   |-> system_counter.s   Helper functions for System Counter
  |
  |-> scripts
  |   |-> run_gicv3.sh       Helper scripts for runing FVP
  |   |-> run_gicv4.sh       Helper scripts for runing FVP
  |
  |-> pre-build
  |   |-> image_basic.axf    Pre-build executable image for GICv3.0 SPI & PPI.
  |   |-> image_gicv31.axf   Pre-build executable image for GICv3.1 Extended PPI and SPI.
  |   |-> image_lpi.axf      Pre-build executbale image for GICv3.x physical LPI.
  |   |-> image_vlpi.axf     Pre-build executbale image for GICv4.1 virtual LPI.
  |   |-> image_vsgi.axf     Pre-build executbale image for GICv4.1 virtual SGI.
  |
  |-> Makefile
  |-> ReadMe.txt             This file
  |-> scatter.txt            Memory layout for linker


Description
===========
The package includes a number of small example programs, each demonstrating a different aspect of using the GIC.

These examples work with GICv3.x and GICv4.x:

image_basic
This example shows the basic set up of a GICv3/4 interrupt controller, including the PPI and SPI interrupt types.

image_lpi
This example shows the setup and use of physical LPIs and the ITS.


These examples require GICv3.1:

image_gicv31
This example shows the use of the GICv3.1 extended PPI and SPI ranges.


These examples require GICv4.1:

image_vlpi
This example shows the setup and use of GICv4.1 virtual LPIs.

image_vsgi
This example shows the setup and use of GICv4.1 virtual SGIs.



Building the example from the command line
==========================================
To build the example:
- Open a DS-5 or Arm Developer Studio command prompt, then navigate to the location of the example

The make command depends on the version of the GIC architecture implemented.

For GICv3.x:
    - Run "make DEBUG=TRUE"

For GICv4.1:
    - Run "make GIC=GICV4"       to build PPI, SPI, and physical LPI examples.
    - Run "make GIC=GICV4 gicv4" to build vLPI and vSGI examples.


Optionally, adding "DEBUG=TRUE" results in additional logging messages being printed.

Note:
When a GIC implements GICv3.x, the Redistributors occupy 128K of address space.  
When GICv4.x is implemented, they occupy 256K.  
The example requires the Redistributor size at build time, which is why the GIC version is passed as an argument to make.


Explanation of model parameters
===============================
These examples are intended to run on the FVP Base Platform model (FVP_Base_AEMv8A-AEMv8A).
This model takes a number of parameters to configure how the GIC appears to software.
Some of the examples require non-default values, this section describes the parameters used for the different examples.

-C cluster0.gicv3.extended-interrupt-range-support=1
Controls whether the PE supports the GICv3.1 extended range, default 0.  the image_gicv31 examples requires this to be set to 1.


-C gic_distributor.extended-ppi-count=<n>
Controls how many (if any) GICv3.1 extended PPIs are available, default 0.  The image_gicv31 example requires this to be set to 32.


-C gic_distributor.extended-spi-count=<n>
Controls how many (if any) GICv3.1 extended SPIs are available, default 0.  The image_gicv31 example requires this to be set to 32.


-C gic_distributor.ITS-count=<n>
Controls how many (if any) ITSs are present, default 0. Most of the examples require it to be set to 1.


-C gic_distributor.ITS-use-physical-target-addresses=<n>
Controls the value of GITS_TYPER.PTA, default 1.  Most of the examples requires it to be set to 0.


-C gic_distributor.virtual-lpi-support=<bool>
Whether the GIC supports GICv4.x, default FALSE.  The GICv4.1 examples require it to be set to TRUE.


-C has-gicv4.1=<bool>
Whether the GIC supports GICv4.1, default FALSE.  The GICv4.1 examples require this to be set to TRUE.


-C gic_distributor.GITS_BASER<x>-type=<n>
The type of table for each GITS_BASER<n> register.  Most of the examples require to be set to:
GITS_BASER0 = 1
GITS_BASER1 = 4
GITS_BASER2 = 2 (GICv4.1 examples only)


-C gic_distributor.ITS-vmovp-bit=<bool>
Controls the value of GITS_TYPER.VMOVP, default 0.  GICv4.1 examples require 1.


-C gic_distributor.common-lpi-configuration=2
-C gic_distributor.ITS-shared-vPE-table=2

Collectively control the ITS's CommonLPIAff behaviour.
GICv4.1 examples require them both to be set to 2.
