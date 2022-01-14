# PULPissimo 환경 설정

PULPissimo에 관한 자세한 설명은 [PULPissimo github](https://github.com/pulp-platform/pulpissimo)에서 찾을 수 있다. 현재 사용된 버전은 [fix-tb-dpi](https://github.com/pulp-platform/pulpissimo/tree/fix-tb-dpi) branch 이다. PULPissimo 및 Custom CPU 환경을 위해 아래 설명을 순서대로 실행한다.

## 환경

이 README는 아래 환경에서 작성되었다. 
- Ubuntu 16.04
- Vivado 2018.3 (Synthesis 라이선스 필요)
- Xilinx Zedboard (ZCU102에서도 동작함)

아래를 실행하면 필요한 repository들을 받을 수 있지만, prerequisite들을 설치해야 하고 Custom CPU를 추가한 버전이 아니므로 아래 설명을 순서대로 실행하는 것을 추천한다.
```
$ git clone --recursive https://github.com/j-sungyeong/esca_samsung.git
```

## 1. PULP RISC-V GNU Compiler
자세한 내용은 [pulp-riscv-gnu-toolchain](https://github.com/pulp-platform/pulp-riscv-gnu-toolchain)에서 찾을 수 있다.

### Prerequisites
```
$ sudo apt-get install autoconf automake autotools-dev curl libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev
```

### Installation
컴파일러를 빌드할 폴더를 생성한 후 [TOOLCHAIN_PATH]에 full path를 넣는다. 예를 들어 ```/home/pulp_toolchain``` 폴더에 빌드하고자 한다면 ```--prefix=/home/pulp_toolchain```과 같이 설정한다. 아래 명령어를 실행하면 RV32IM cross-compiler가 빌드된다. C extension을 추가로 포함하고 싶으면 별개의 폴더에 ```--with-arch=rv32imc``` 옵션으로 새로운 컴파일러를 빌드한다. 이는 C extension을 추가하여 빌드한 컴파일러를 사용하면 application 컴파일 시 C extension을 제외할 수 없는 문제가 있기 때문이다.
```
$ git clone --recursive https://github.com/pulp-platform/pulp-riscv-gnu-toolchain
$ cd pulp-riscv-gnu-toolchain
$ ./configure --prefix=[TOOLCHAIN_PATH] --with-arch=rv32im --enable-multilib
$ make
```
빌드가 끝나면 ```PULP_RISCV_GCC_TOOLCHAIN``` 환경변수를 설정한다. ```.bashrc``` 파일에 추가해두면 매번 환경변수를 추가하지 않아도 된다. 앞으로 설정하는 모든 환경변수는 ```~/.bashrc``` 파일에 추가하는 것을 권장한다.
```
$ export PULP_RISCV_GCC_TOOLCHAIN=[TOOLCHAIN_PATH]
```

## 2. PULP SDK(v1 branch)
자세한 내용은 [pulp-sdk](https://github.com/pulp-platform/pulp-sdk)에서 찾을 수 있다. v1 branch는 out-dated branch 이지만 FPGA 용 application을 빌드하기 위해 필요한 파일을 포함하고 있어 사용하였다.

### Prerequisites
```
$ sudo apt install git python3-pip python-pip gawk texinfo libgmp-dev libmpfr-dev libmpc-dev swig3.0 libjpeg-dev lsb-core doxygen python-sphinx sox graphicsmagick-libmagick-dev-compat libsdl2-dev libswitch-perl libftdi1-dev cmake scons libsndfile1-dev
$ sudo pip3 install artifactory twisted prettytable sqlalchemy pyelftools 'openpyxl==2.6.4' xlsxwriter pyyaml numpy configparser pyvcd
$ sudo pip2 install configparser
```

pip 버전에 따라 에러가 발생할 수 있다. ```python3 -m pip install pip==20.3.4``` 와 ```python -m pip install pip==20.3.4``` 을 실행하여 pip 버전을 20.3.4로 변경하여 해결하거나, ```update-alternatives```를 통해 파이썬 버전 3.6 이상을 사용하여 해결할 수 있다. 후자의 경우 모듈을 설치한 후에는 파이썬 버전을 다시 3.5.2로 낮춰야 한다.

### Build SDK
SDK를 빌드하기 전에 ```PULP_RISCV_GCC_TOOLCHAIN``` 환경변수가 설정되어 있어야 한다.   
FPGA 용 application을 빌드하기 위해서는 FPGA 보드에 관계 없이 아래 파일들을 source하여 SDK를 빌드한다.
```
$ git clone https://github.com/pulp-platform/pulp-sdk.git -b v1

//move to pulp-sdk directory
$ source configs/pulpissimo.sh
$ source configs/fpgas/pulpissimo/genesys2.sh
$ make all
```
FPGA 용 SDK는 [gpio input bug](https://github.com/pulp-platform/hal/pull/20/commits/98523f50349f76ebd7e59e5ff95e6869e6a04449)가 존재한다. 빌드가 끝나면 ```pkg``` 폴더가 생성되며, 아래와 같이 코드를 수정한다.
```
$ vi pkg/sdk/dev/install/include/hal/gpio/gpio_v3.h

...

//Near line 173
static inline uint32_t hal_gpio_get_value()
{
  return gpio_padout_get(ARCHI_GPIO_ADDR);  //Change this to gpio_padin_get(ARCHI_GPIO_ADDR)
}

```

### Compile application
예제는 [pulp-rt-examples](https://github.com/pulp-platform/pulp-rt-examples)에서 받을 수 있다. 예를 들어, pulp-sdk를 이용하여 ```hello``` application을 컴파일하려면 아래와 같이 실행한다.

1. ```hello``` application 폴더로 이동한다.
2. application(test.c)을 열어서 코드를 아래와 같이 수정한다.
```
#include <stdio.h>
#include <rt/rt_api.h>

int __rt_fpga_fc_frequency = 20000000;      //20MHz (Zedboard의 경우 16MHz)
int __rt_fpga_periph_frequency = 10000000;  //10MHz

int main()
{
...
}
```
3. SDK를 source 한다.
```
$ source pulp-sdk/sourceme.sh
```
4. application을 컴파일한다.
```
make clean all
```

```hello/build/pulpissimo/test``` 경로에 ```test```라는 이름으로 elf 파일이 생성될 것이다.

### OpenOCD 설치
아래와 같이 실행하여 OpenOCD를 설치한다.
```
//move to pulp-sdk directory
$ source sourceme.sh && ./pulp-tools/bin/plpbuild checkout build --p openocd --stdout
```

만약 'CMake version'과 관련된 에러가 발생한다면 Vivado와 충돌이 발생했기 때문일 가능성이 높다. Vivado를 source 하지 않고(환경변수도 제거하고) 터미널을 새로 열어서 실행하면 해결될 것이다.


## 3. FPGA에 PULPissimo porting 하기
[Vivado 2018.3](https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vivado-design-tools/archive.html) 버전이 설치되어 있어야 하며, synthesis를 위한 라이선스가 필요하다.   
PULPissimo를 clone한 후 아래와 같이 실행한다.
```
//move to pulpissimo directory
$ ./update-ips

$ ./generate-scripts

$ source [Vivado install path]/Vivado/2018.3/settings64.sh

//move to pulpissimo-zedboard or pulpissimo-zcu102 directory under pulpissimo/fpga
$ make all
```
시간이 오래 걸리고 약 16GB의 메모리가 필요하다. 이렇게 하면 FPGA에 해당하는 bitstream이 생성된다. Bitstream을 FPGA에 다운로드하기 위해서는 JTAG 케이블을 연결해야 한다.

1. Vivado를 실행하여 'Open Hardware Manager'를 클릭한다.
2. 'Open target' - 'Auto Connect'를 클릭한다.
3. 'Program device'를 클릭하여 .bit 파일을 선택한 후 'Program'을 클릭한다.
4. Bitstream 다운로드가 완료되면 LED에 불이 들어올 것이다.

ZCU102 FPGA를 사용하면 'ERROR: [Common 17-39] 'program_hw_devices' failed due to earlier errors' 에러가 발생할 것이고, tcl console에 ```set_param xicom.use_bitstream_version_check false```를 입력하고 다시 다운로드하면 해결된다. 해당 에러는 보드 revision에 의해 발생한 것이다.

### FPGA에서 application 실행하기
Bitstream을 다운로드한 후, OpenOCD와 GDB를 이용하여 PULPissimo에서 application을 실행해볼 수 있다. Zedboard는 UART와 JTAG 모듈을 연결해야 하고, ZCU102는 JTAG 모듈만 연결하면 된다. 연결은 [여기](https://github.com/pulp-platform/pulpissimo/tree/fix-tb-dpi/fpga/pulpissimo-zedboard)를 참조하여 맞는 핀끼리 연결하면 된다.

1. FPGA에 bitstream을 다운로드한다.
2. 'Hardware Manager'의 localhost 서버를 닫는다. 닫지 않으면 OpenOCD 실행 시 "Error: libusb_claim_interface() failed with LIBUSB_ERROR_BUSY"가 발생한다.
3. JTAG 케이블을 연결한 후 OpenOCD를 실행한다. 예시는 zcu102이지만 zedboard에서도 동일한 방법으로 실행할 수 있다.
```
//under pulpissimo/fpga/pulpissimo-zcu102
$ $OPENOCD/bin/openocd -f openocd-zcu102-digilent-jtag-hs2.cfg
```
4. UART 통신을 위해 ```minicom```을 실행한다.
```
$ sudo minicom -s
```
Zedboard는 port를 ttyUSB0로 설정하고, ZCU102는 ttyUSB2로 설정한다. (다른 장치들과의 연결 상태에 따라 다른 번호에 연결되어 있을 수 있으며, 이 경우 연결된 ttyUSB를 찾아야 한다.) Baud rate은 115200으로 설정한다.   

5. 다른 터미널에서 아래와 같이 GDB를 실행한다.
```
$ riscv32-unknown-elf-gdb [PATH_TO_YOUR_ELF_FILE]
```
5. In gdb, type
```
(gdb) target remote localhost:3333
...
(gdb) load
```

GDB를 종료할 때는 ```disconnect```, ```quit```을 차례로 실행하여 연결을 끊어주는 것이 좋다. 그렇지 않으면 다음에 GDB를 실행할 때 OpenOCD에서 연결을 거부할 수도 있다.

# Customize
여기부터는 in-house CPU를 빌드하기 위해 수정한 부분을 설명한다. 이 repository의 폴더 및 파일들을 붙여넣기하여 수정할 수 있다. 번호에 맞는 설명을 따라 폴더 또는 파일을 복사한다. 또는 아래 명령어를 이용하여 clone했다면 메모리에 대한 변경 사항이 적용되어 있지만 original pulpissimo github와의 연동이 끊어지게 되며 일부 기능을 사용하지 못할 수 있다.
```
$ git clone --recursive https://github.com/j-sungyeong/esca_samsung.git
```

## 1. memory
In-house CPU는 JTAG를 통한 application 로드가 불가능하다. 따라서 메모리 초기화 파일인 .coe 파일을 이용하여 메모리를 초기화한다. 이를 위해 먼저 block memory generator를 각 메모리별로 생성하고 coe 파일을 설정할 필요가 있다. 

1. ```pulpissimo/fpga/pulpissimo-[board]/ips``` 폴더에 있는 ```xilinx_interleaved_ram```, ```xilinx_private_ram``` 폴더를 삭제하고 여기서 clone한 ```RISC-V backup/1. memory/pulpissimo-[board]/ips``` 폴더 하위의 6개 폴더를 붙여넣는다. Ram을 분리하여 빌드하는 Makefile과 tcl 파일이 들어있다.
2. ```1. memory/pulpissimo-[board]``` 폴더의 fpga-settings.mk 와 Makefile을 덮어쓴다. 수정된 ram을 포함하여 빌드하도록 변경되었다. Makefile을 살펴보면 빌드 및 clean을 위한 명령어들을 확인할 수 있다.
3. ```1. memory/pulpissimo-[board]/tcl``` 폴더의 run.tcl 파일을 덮어쓴다. 수정된 ram을 포함하여 빌드하도록 변경되었다.
4. ```1. memory/pulpissimo-[board]/rtl``` 폴더를 덮어쓴다. 메모리 관련 파일이 수정되었고, 빌드에 in-house CPU 를 선택할 수 있도록 했다. 또한 pulpissimo_tb.v 파일을 이용하여 Vivado에서 시뮬레이션을 해볼 수 있다.
5. pulpissimo/ips/pulp_soc/rtl/pulp_soc/l2_ram_multi_bank.sv 를 ```1. memory/l2_ram_multi_bank.sv``` 파일로 덮어쓴다.
6. ```1. memory/pulpissimo-[board]/coe``` 폴더를  ```pulpissimo/fpga/pulpissimo-[board]``` 아래에 붙여넣는다. 빌드를 위해 coe 폴더에 ```test``` 라는 이름으로 elf 파일을 넣고, ```./elf2coe.sh```를 실행하면 .coe 파일들이 생성되는 것을 확인할 수 있다.

## 2. CPU

1. ```pulpissimo/fpga``` 폴더 아래에 ```myrtl``` 폴더를 붙여넣는다. 해당 폴더는 RV32IMC 명령어를 실행 가능한 in-house CPU 코드가 있다. ```backups``` 폴더에 RV32I, RV32IM CPU 코드가 있으며, 필요하다면 myrtl 폴더에 덮어씌워 빌드해볼 수 있다.   
2. ```pulpissimo/fpga/pulpissimo``` 폴더를 ```2. CPU/pulpissimo``` 폴더로 덮어씌운다. 해당 폴더에는 ```myrtl``` 폴더에 있는 소스코드를 포함하여 빌드하도록 수정된 tcl 파일들이 있다. 만약 ```myrtl``` 폴더에 .sv 파일을 새로 생성하였다면 ips_src_files.tcl 파일의 MYIPS_ALL 부분에 ```$MYIPS/[파일명]   \``` 을 추가하면 빌드에 포함할 수 있다.
3. xilinx_pulpissimo - pulpissimo - soc_domain - pulp_soc 모듈에 xilinx_pulpissimo.v 파일을 참고하여 parameter로 USE_MYCPU를 연결한다. ```pulpissimo/ips/pulp_soc/rtl/fc/fc_subsystem.sv``` 파일은 ```2. CPU/fc_subsystem.sv``` 파일로 덮어쓴다. xilinx_pulpissimo.v 파일에서 USE_MYCPU의 값을 변경하면 in-house CPU 사용 여부를 설정할 수 있다. 

## 3. Software
PULPissimo의 자체 명령어를 제거하기 위해 pulpino 의 sw 빌드 환경을 이용하였다.
1. ```3. Software``` 폴더의 pulpino.zip을 압축해제하여 readme.txt 파일을 따라 실행한다. ```pulpino/sw/build```에 있는 cmake_configure.riscv.gcc.sh 파일의 설정을 변경하여 컴파일 옵션을 변경할 수 있다. 주로 변경하는 옵션은 아래와 같다.
- TARGET_C_FLAGS = "-O2 -march=rv32imc -g -mstrict-align" 을 변경하여 최적화 레벨과 RISC-V ISA를 변경할 수 있다. C extension을 제외하고 싶으면 C extension 없이 빌드된 컴파일러를 toolchain path로 지정한 뒤 readme.txt의 과정을 다시 진행해야 한다. -mstrict-align 옵션은 제외하면 에러가 발생한다.
- GCC_MARCH="rv32imc" 옵션에서 컴파일 시 포함할 Instruction set을 선택할 수 있다. 예를 들어 Integer 명령어만 포함하고자 하면 GCC_MARCH="rv32i"로 변경하면 된다.
2. ```pulpino/sw/build``` 경로에서 ```make [application]```를 실행하면 ```pulpino/sw/build/apps/[application]```에 [application].elf 파일이 생성된다. 생성된 elf 파일을 ```pulpissimo/fpga/pulpissimo-[board]/coe```에 복사하여 이름을 test로 변경한 후 사용하면 된다.

## 4. Simulation
Simulation을 위해서는 Questasim이 필요하다. 만약 Questasim 라이선스가 없다면 [이곳](https://github.com/j-sungyeong/esca_samsung)을 참조하여 Vivado 에서도 시뮬레이션 해볼 수 있으나, 변경사항이 있을 때마다 빌드를 새로 해야 하므로 비효율적이다.   
Quesasim을 이용하여 시뮬레이션하는 방법은 아래와 같다.

1. 
아래와 같이 pulp-sdk를 simulation 용으로 새로 빌드하여 source 한다.
```
$ export VSIM_PATH=[pulpissimo 설치 경로]/sim

//pulp-sdk 폴더로 이동
$ source configs/pulpissimo.sh
$ source configs/platform-rtl.sh
$ make all
```
   
아래와 같이 pulpissimo에서 simulation 을 위한 플랫폼을 빌드한다.
```
//pulpissimo 폴더에서
$ source setup/vsim.sh
$ make build
```
이후 코드를 수정하여 시뮬레이션 할 때마다 ```pulpissimo``` 폴더에서 ```make build```를 실행하여 변경사항을 적용해야 한다.

2. ```pulpissimo/sim/coe``` 폴더를 생성하고, ```pulpissimo/sim``` 폴더의 하위에 ```4. Simulation/tcl_files```와 ```4. Simulation/vcompile``` 폴더 하위의 파일을 해당하는 경로에 붙여넣기한다. In-house CPU 파일들을 포함하여 시뮬레이션 하도록 수정되어 있다. 만약 새로운 .sv 파일을 생성했다면 시뮬레이션에 포함하기 위해 ```pulpissimo/sim/vcompile/ips``` 폴더의 my_core.mk 파일을 수정하면 된다. 
3. ```pulpissimo/ips/tech_cells_generic/src/deprecated``` 폴더에 generic_memory.sv, generic_rom.sv 파일을 붙여넣는다. ```pulpissimo/rtl/tb``` 폴더에 tb_pulp.sv 파일을 붙여넣는다. JTAG 대신 coe 파일을 사용하여 시뮬레이션하도록 수정되어 있다. 
4. ```4. Simulation/bin2stim``` 폴더는 시뮬레이션을 위한 coe 파일을 생성하는 데 사용된다. 사용법은 1. memory의 coe 파일 생성 과정과 동일하나, 생성된 coe 파일의 형식이 다르므로 섞지 않도록 주의해야 한다. ```./elf2coe.sh```을 실행하면 ```pulpissimo/sim/coe``` 폴더에 .coe 파일들이 복사된다.
5. 가장 간단한 application인 hello 예제 폴더에서 pulp-sdk를 이용하여 build를 하면 시뮬레이션을 위한 파일들이 생성된다. ```hello/build/pulpissimo``` 폴더에 2번에서 생성한 ```pulpissimo/sim/coe``` 폴더를 링크하는 폴더를 생성한다. hello 예제의 소스코드는 사용되지 않는다. bin2stim 폴더에서 coe 파일을 생성한 후 hello 예제 폴더에서 ```make run gui=1```을 실행하여 Questasim 을 이용한 시뮬레이션을 진행할 수 있다. 

## resource
Zedboard에서 빌드된 PULPissimo bitstream을 사용할 수 있다. Riscy 또는 ibex(zero-riscy) 프로세서를 이용하여 빌드하였으며, 필요에 따라 사용할 수 있다. Dropbox에서 세미나 자료를 찾을 수 있다.