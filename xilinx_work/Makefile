.PHONY: help

help::
	$(ECHO) "Makefile Usage:"
	$(ECHO) "  make all TARGET=<hw_emu/hw> DEVICE=<FPGA platform>"
	$(ECHO) "      Command to generate the design for specified Target and Device."
	$(ECHO) ""
	$(ECHO) "  make clean "
	$(ECHO) "      Command to remove the generated non-hardware files."
	$(ECHO) ""
	$(ECHO) "  make cleanall"
	$(ECHO) "      Command to remove all the generated files."
	$(ECHO) ""
	$(ECHO) "  make check TARGET=<hw_emu/hw> DEVICE=<FPGA platform>"
	$(ECHO) "      Command to run application in emulation."
	$(ECHO) ""
	$(ECHO) "  make build TARGET=<hw_emu/hw> DEVICE=<FPGA platform>"
	$(ECHO) "      Command to build xclbin application."
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


EXECUTABLE = ederah.exe
CMD_ARGS = $(XCLBIN)/ederah.$(TARGET).$(DSA).xclbin

EMCONFIG_DIR = $(XCLBIN)/$(DSA)

BINARY_CONTAINERS += $(XCLBIN)/ederah.$(TARGET).$(DSA).xclbin
BINARY_CONTAINER_ederah_OBJS += $(XCLBIN)/ederah.$(TARGET).$(DSA).xo

CP = cp -rf

ifeq ($(DEVICE),xilinx_u250_xdma_201830_2)
	FRIENDLY_DEVICE ?= U250
else ifeq ($(DEVICE),$(AWS_PLATFORM))
	FRIENDLY_DEVICE ?= AWS
else
	FRIENDLY_DEVICE ?= NKD # NOT A KNOWN DEVICE
endif

# Execution
KERNEL_CONFIG_TAG := 1K2C
DATA_INPUT_PATH := ../sw/build-mct_PfD
DATA_OUTPUT_PATH := ~/Documents/workspace
FIRST_BATCH_SIZE := 1
MAX_BATCH_SIZE := 1000000
ITERATIONS := 1000
KERNELS_TO_RUN := 1
#
NFA_DATA_FILE := $(DATA_INPUT_PATH)/mem_edges.bin
WORKLOAD_FILE := $(DATA_INPUT_PATH)/benchmark.bin
RESULT_FILE := $(DATA_OUTPUT_PATH)/res_$(FRIENDLY_DEVICE)_PfD_$(KERNEL_CONFIG_TAG).csv
BENCHMARK_FILE := $(DATA_OUTPUT_PATH)/ben_$(FRIENDLY_DEVICE)_PfD_$(KERNEL_CONFIG_TAG).csv

.PHONY: all clean cleanall docs emconfig
all: check-devices $(EXECUTABLE) $(BINARY_CONTAINERS) emconfig

.PHONY: exe
exe: $(EXECUTABLE)

.PHONY: build
build: $(BINARY_CONTAINERS)

.PHONY: run_aws
run_aws: cp $(EXECUTABLE) ../../ederah/

# Building kernel
$(XCLBIN)/ederah.$(TARGET).$(DSA).xo: ../hw/$(XL_SHELL)/kernel.xml package_kernel.tcl gen_xo.tcl ../hw/tools/*.vhd ../hw/engine/*.vhd ../hw/$(XL_SHELL)/*.sv ../hw/$(XL_SHELL)/*.v ../hw/$(XL_SHELL)/*.vhd
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

check: all
ifeq ($(TARGET),$(filter $(TARGET),hw_emu))
	$(CP) $(EMCONFIG_DIR)/emconfig.json .
	XCL_EMULATION_MODE=$(TARGET) ./$(EXECUTABLE) -b $(XCLBIN)/ederah.$(TARGET).$(DSA).xclbin -n $(NFA_DATA_FILE) -w $(WORKLOAD_FILE) -r $(RESULT_FILE) -o $(BENCHMARK_FILE) -f $(FIRST_BATCH_SIZE) -m $(MAX_BATCH_SIZE) -i $(ITERATIONS) -k $(KERNELS_TO_RUN)
else
	 ./$(EXECUTABLE) -b $(XCLBIN)/ederah.$(TARGET).$(DSA).xclbin -n $(NFA_DATA_FILE) -w $(WORKLOAD_FILE) -r $(RESULT_FILE) -o $(BENCHMARK_FILE) -f $(FIRST_BATCH_SIZE) -m $(MAX_BATCH_SIZE) -i $(ITERATIONS) -k $(KERNELS_TO_RUN)
endif
ifneq ($(TARGET),$(findstring $(TARGET), hw hw_emu))
$(warning WARNING:Application supports only hw hw_emu TARGET. Please use the target for running the application)
endif

	sdx_analyze profile -i profile_summary.csv -f html


aws_build: check-aws_repo #$(BINARY_CONTAINERS)
	mkdir -p _aws
	(cd _aws && ../$(COMMON_REPO)/utility/aws/run_aws.py ../$(BINARY_CONTAINERS))
	-$(RMDIR) _aws/to_aws
	wait_for_afi.py --afi $(call GetFromJson,$(shell find _aws/ -name '*_afi_id.txt' | tail -1),FpgaImageId) --notify --email maschif@ethz.ch
	

# Cleaning stuff
clean:
	-$(RMDIR) $(EXECUTABLE) $(XCLBIN)/{*sw_emu*,*hw_emu*} 
	-$(RMDIR) profile_* TempConfig system_estimate.xtxt *.rpt *.csv 
	-$(RMDIR) src/*.ll _xocc_* .Xil emconfig.json dltmp* xmltmp* *.log *.jou *.wcfg *.wdb

cleanall: clean
	-$(RMDIR) $(XCLBIN)
	-$(RMDIR) _x _aws
	-$(RMDIR) ./tmp_kernel_pack* ./packaged_kernel* 
