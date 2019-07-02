kernel_name:=mct
kernel_xo:=$(kernel_name).xo
xclbin_sw_emu:=$(kernel_name)_sw_emu.xclbin
xclbin_hw_emu:=$(kernel_name)_hw_emu.xclbin
incdir=$(XILINX_SDX)/runtime/include/1_2
runtime:=$(XILINX_SDX)/runtime/lib/x86_64
platform_vlnv := $(DEVICE)
platform := $(subst :,_,$(platform_vlnv))
platform := $(subst .,_,$(platform))

hw_emu: main emconfig.json $(kernel_xo) $(xclbin_hw_emu)
	XCL_EMULATION_MODE=hw_emu ./main $(xclbin_hw_emu)

sw_emu: main emconfig.json $(kernel_xo) $(xclbin_sw_emu)
	XCL_EMULATION_MODE=sw_emu ./main $(xclbin_sw_emu)

$(kernel_xo): ../imports/*
	vivado -mode batch -source ../imports/package_xo.tcl ../*.xpr


$(xclbin_hw_emu): $(kernel_xo)
	xocc --debug --link --target hw_emu --platform $(platform) --output $(xclbin_hw_emu) $(kernel_xo)

$(xclbin_sw_emu): $(kernel_xo)
	xocc --debug --link --target sw_emu --platform $(platform) --output $(xclbin_sw_emu) $(kernel_xo)

main.o: main.c
	xcpp -g -Wall -DSDX_PLATFORM=$(platform) -I $(incdir) -c ./main.c -o main.o

main: main.o
	xcpp -L$(runtime) -lxilinxopencl  -lstdc++ main.o -o main

emconfig.json:
	emconfigutil --platform $(platform)

clean:
	rm -f main.o main $(xclbin_sw_emu) $(xclbin_hw_emu) emconfig.json sdaccel_profile_summary.csv *.log *.jou kernel_info.dat sdaccel_profile_kernels.csv *.wdb *.wcfg
	rm -rf  _xocc_link_$(kernel_name)_$(kernel_name)_hw_emu.dir .Xil

