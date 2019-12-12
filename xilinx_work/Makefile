.PHONY: help

help::
	$(ECHO) "Makefile Usage:"
	$(ECHO) "  make all TARGET=<sw_emu/hw_emu/hw> DEVICE=<FPGA platform>"
	$(ECHO) "      Command to generate the design for specified Target and Device."
	$(ECHO) ""
	$(ECHO) "  make clean "
	$(ECHO) "      Command to remove the generated non-hardware files."
	$(ECHO) ""
	$(ECHO) "  make cleanall"
	$(ECHO) "      Command to remove all the generated files."
	$(ECHO) ""
	$(ECHO) "  make check TARGET=<sw_emu/hw_emu/hw> DEVICE=<FPGA platform>"
	$(ECHO) "      Command to run application in emulation."
	$(ECHO) ""
	$(ECHO) "  make build TARGET=<sw_emu/hw_emu/hw> DEVICE=<FPGA platform>"
	$(ECHO) "      Command to build xclbin application."
	$(ECHO) ""
	$(ECHO) "  make run_nimbix DEVICE=<FPGA platform>"
	$(ECHO) "      Command to run application on Nimbix Cloud."
	$(ECHO) ""
	$(ECHO) "  make aws_build DEVICE=<FPGA platform>"
	$(ECHO) "      Command to build AWS xclbin application on AWS Cloud."
	$(ECHO) ""

# Points to SDAccel_Examples Directory
COMMON_REPO = ../../SDAccel_Examples/
ABS_COMMON_REPO = $(shell readlink -f $(COMMON_REPO))

TARGETS := hw
TARGET := $(TARGETS)
DEVICE := $(DEVICES)
XCLBIN := ./xclbin
XL_SHELL ?= xdma

include ./utils.mk

DSA := $(call device2dsa, $(DEVICE))
BUILD_DIR := ./_x.$(TARGET).$(DSA)

BUILD_DIR_ederah = $(BUILD_DIR)/ederah

CXX := $(XILINX_SDX)/bin/xcpp
XOCC := $(XILINX_SDX)/bin/xocc
VIVADO := $(XILINX_VIVADO)/bin/vivado

#Include Libraries
include $(ABS_COMMON_REPO)/libs/opencl/opencl.mk
include $(ABS_COMMON_REPO)/libs/xcl2/xcl2.mk
CXXFLAGS += $(xcl2_CXXFLAGS)
LDFLAGS += $(xcl2_LDFLAGS)
HOST_SRCS += $(xcl2_SRCS)

CXXFLAGS += $(opencl_CXXFLAGS) -Wall -O0 -g -std=c++14
LDFLAGS += $(opencl_LDFLAGS)

HOST_SRCS += ../sw/kernel.cpp

# Host compiler global settings
CXXFLAGS += -fmessage-length=0
LDFLAGS += -lrt -lstdc++

ifeq ($(TARGET),hw_emu)
	CLDEBUG ?= -g
endif

# Kernel compiler global settings
CLFLAGS += -t $(TARGET) --platform $(DEVICE) --save-temps $(CLDEBUG)


EXECUTABLE = host
CMD_ARGS = $(XCLBIN)/ederah.$(TARGET).$(DSA).xclbin

EMCONFIG_DIR = $(XCLBIN)/$(DSA)

BINARY_CONTAINERS += $(XCLBIN)/ederah.$(TARGET).$(DSA).xclbin
BINARY_CONTAINER_ederah_OBJS += $(XCLBIN)/ederah.$(TARGET).$(DSA).xo

CP = cp -rf

.PHONY: all clean cleanall docs emconfig
all: check-devices $(EXECUTABLE) $(BINARY_CONTAINERS) emconfig

.PHONY: exe
exe: $(EXECUTABLE)

.PHONY: build
build: $(BINARY_CONTAINERS)

# Building kernel
$(XCLBIN)/ederah.$(TARGET).$(DSA).xo: ../hw/$(XL_SHELL)/kernel.xml ../hw/$(XL_SHELL)/package_kernel.tcl gen_xo.tcl ../hw/tools/*.vhd ../hw/engine/*.vhd ../hw/$(XL_SHELL)/*.sv ../hw/$(XL_SHELL)/*.v ../hw/$(XL_SHELL)/*.vhd
	mkdir -p $(XCLBIN)
	$(VIVADO) -mode batch -source gen_xo.tcl -tclargs $(XCLBIN)/ederah.$(TARGET).$(DSA).xo ederah $(TARGET) $(DSA) $(XL_SHELL)

# Building bistream
$(XCLBIN)/ederah.$(TARGET).$(DSA).xclbin: $(BINARY_CONTAINER_ederah_OBJS)
	mkdir -p $(XCLBIN)
	$(XOCC) $(CLFLAGS) $(LDCLFLAGS) -lo $(XCLBIN)/ederah.$(TARGET).$(DSA).xclbin $(XCLBIN)/ederah.$(TARGET).$(DSA).xo

# Building Host
$(EXECUTABLE): check-xrt $(HOST_SRCS) $(HOST_HDRS)
	$(CXX) $(CXXFLAGS) $(HOST_SRCS) $(HOST_HDRS) -o '$@' $(LDFLAGS)

emconfig:$(EMCONFIG_DIR)/emconfig.json
$(EMCONFIG_DIR)/emconfig.json:
	emconfigutil --platform $(DEVICE) --od $(EMCONFIG_DIR)
	export XCL_EMULATION_MODE=hw_emu

check: all
ifeq ($(TARGET),$(filter $(TARGET),sw_emu hw_emu))
	$(CP) $(EMCONFIG_DIR)/emconfig.json .
	XCL_EMULATION_MODE=$(TARGET) ./$(EXECUTABLE) $(XCLBIN)/ederah.$(TARGET).$(DSA).xclbin
else
	 ./$(EXECUTABLE) $(XCLBIN)/ederah.$(TARGET).$(DSA).xclbin
endif
ifneq ($(TARGET),$(findstring $(TARGET), hw hw_emu))
$(warning WARNING:Application supports only hw hw_emu TARGET. Please use the target for running the application)
endif

	sdx_analyze profile -i profile_summary.csv -f html


aws_build: check-aws_repo $(BINARY_CONTAINERS)
	$(COMMON_REPO)/utility/aws/run_aws.py $(BINARY_CONTAINERS)

# Cleaning stuff
clean:
	-$(RMDIR) $(EXECUTABLE) $(XCLBIN)/{*sw_emu*,*hw_emu*} 
	-$(RMDIR) profile_* TempConfig system_estimate.xtxt *.rpt *.csv 
	-$(RMDIR) src/*.ll _xocc_* .Xil emconfig.json dltmp* xmltmp* *.log *.jou *.wcfg *.wdb

cleanall: clean
	-$(RMDIR) $(XCLBIN)
	-$(RMDIR) _x
	-$(RMDIR) ./tmp_kernel_pack* ./packaged_kernel* 
