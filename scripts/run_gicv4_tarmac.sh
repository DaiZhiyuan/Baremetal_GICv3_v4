#!/bin/bash

if [ $# -lt 1 ];then
    echo "no arguments"
else
    echo "application: $1"
fi

FVP_Base_RevC-2xAEMvA \
    -C has-gicv4.1=1 \
    -C bp.secure_memory=0 \
    -C gic_distributor.ITS-count=1 \
    -C gic_distributor.ITS-use-physical-target-addresses=0 \
    -C gic_distributor.GITS_BASER0-type=1 \
    -C gic_distributor.GITS_BASER1-type=4 \
    -C gic_distributor.GITS_BASER2-type=2 \
    -C gic_distributor.GITS_BASER6-type=0 \
    -C gic_distributor.virtual-lpi-support=1 \
    -C gic_distributor.reg-base-per-redistributor=0.0.0.0=0x2f100000,0.0.1.0=0x2f140000,0.0.2.0=0x2f180000,0.0.3.0=0x2f1C0000,0.1.0.0=0x2f200000,0.1.1.0=0x2f240000,0.1.2.0=0x2f280000,0.1.3.0=0x2f2c0000 \
    -C gic_distributor.common-lpi-configuration=2 \
    -C gic_distributor.ITS-shared-vPE-table=2 \
    -C gic_distributor.ITS-vmovp-bit=1 \
    -C gic_distributor.has_VPENDBASER-dirty-flag-on-load=1 \
    -C gic_distributor.extended-ppi-count=0 \
    -C gic_distributor.extended-spi-count=1024 \
    -C semihosting-enable=1 \
    -C pctl.startup=0.*.*.0 \
    --plugin=/usr/local/src/Base_RevC_AEMvA_pkg/plugins/Linux64_GCC-9.3/TarmacTrace.so \
    -C TRACE.TarmacTrace.trace-file=/root/gic.tarmac \
    -C TRACE.TarmacTrace.trace_gicv3_its=1 \
    -C TRACE.TarmacTrace.trace_gicv3=1 \
    --stat \
    --application=$1
