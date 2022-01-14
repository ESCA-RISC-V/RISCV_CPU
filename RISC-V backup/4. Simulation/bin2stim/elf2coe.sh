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
./hex2coe_sim.perl
$PULP_RISCV_GCC_TOOLCHAIN/bin/riscv32-unknown-elf-objdump -d test > test.dump
cp *.coe /home/sun/sun/esca_samsung/escaplp/sim/coe/
