#!/bin/bash

if [ $PULP_RISCV_GCC_TOOLCHAIN ]
then
	echo "ELF to COE file"
else
	echo "PULP_RISCV_GCC_TOOLCHAIN not defined."
	exit 1
fi

$PULP_RISCV_GCC_TOOLCHAIN/bin/riscv32-unknown-elf-objcopy -O binary test test.bin
./bin2hex.perl > test.hex
./hex2coe_split.perl
