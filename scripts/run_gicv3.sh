#!/bin/bash

if [ $# -lt 1 ];then
    echo "no arguments"
else
    echo "application: $1"
fi

FVP_Base_RevC-2xAEMvA \
    -C cluster0.NUM_CORES=1 \
    -C cluster1.NUM_CORES=0 \
    -C gic_distributor.GITS_BASER0-type=1 \
    -C gic_distributor.GITS_BASER1-type=4 \
    -C bp.secure_memory=0 \
    -C gic_distributor.ITS-count=1 \
    -C gic_distributor.ITS-use-physical-target-addresses=0 \
    -C gic_distributor.GITS_BASER6-type=0 \
    -C gic_distributor.extended-ppi-count=32 \
    -C gic_distributor.extended-spi-count=32 \
    --application=$1
