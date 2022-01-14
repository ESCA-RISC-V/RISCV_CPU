# #  Makefile to generate RISC-V binary for Computer Architecture class
#
#  Author: Prof. Taeweon Suh
#          Computer Science & Engineering
#	   College of Informatics
#          Korea University
#
#  Date:   2020-06-11
#

    HOME=/home/sun/sun/esca_samsung/pulp-compiler
    RVBIN=$(HOME)/bin
    AS=$(RVBIN)/riscv32-unknown-elf-as
    LD=$(RVBIN)/riscv32-unknown-elf-ld
    CC=$(RVBIN)/riscv32-unknown-elf-gcc
    CPP=$(RVBIN)/riscv32-unknown-elf-cpp        
    OBJDUMP=$(RVBIN)/riscv32-unknown-elf-objdump
    OBJCOPY=$(RVBIN)/riscv32-unknown-elf-objcopy
#   ASFLAGS= -Wall -O2 -g
#    ASFLAGS= -g -mips32
    ASFLAGS= -g -march=rv32i
    LDFLAGS= -N -X -Tlabcode.lds 
    CCFLAGS= -c -g -march=rv32im
    
    all: test 

    test: myexam.o foo.o
	$(LD) $(LDFLAGS)  myexam.o foo.o -o test
	$(OBJDUMP) -xSd  test > test.dump
	$(OBJCOPY) -O  binary test test.bin
	./bin2hex.perl > test.hex
	./hex2coe_split.perl
#	./mipsel-readelf -a labcode > labcode.r
#	./mipsel-nm labcode > labcode.n
	 
    lab0.o: lab0.s 
	$(AS) $(ASFLAGS) lab0.s -o lab0.o
	
	myexam.o: myexam.s
	$(AS) $(ASFLAGS) myexam.s -o myexam.o

    foo.o:	foo.c
#	$(CPP) add.c > add.i
#	$(CC) -Wall -S add.i
#	$(AS) $(ASFLAGS) add.s -o add.o
	$(CC) $(CCFLAGS) foo.c
	
    clean:
	rm -rf *.dump *.hex *.bin *.coe
