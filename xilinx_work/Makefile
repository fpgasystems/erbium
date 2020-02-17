.PHONY: help

help::
	$(ECHO) "Makefile Usage:"
	$(ECHO) "  make all"
	$(ECHO) "      Command to generate the design for specified Target and Device."
	$(ECHO) ""
	$(ECHO) "  make clean"
	$(ECHO) "      Command to remove the generated non-hardware files."
	$(ECHO) ""
	$(ECHO) "  make cleanall"
	$(ECHO) "      Command to remove all the generated files."
	$(ECHO) ""
	$(ECHO) "  make check"
	$(ECHO) "      Command to run application in emulation."
	$(ECHO) ""
	$(ECHO) "  make build"
	$(ECHO) "      Command to build xclbin application."
	$(ECHO) ""
	$(ECHO) "  make compile"
	$(ECHO) "      Command to compile host kernel only."
	$(ECHO) ""
	$(ECHO) "  make aws_build"
	$(ECHO) "      Command to build AWS xclbin application on AWS Cloud."
	$(ECHO) ""
	$(ECHO) "  options:"
	$(ECHO) "      TARGET=<hw_emu/hw>"
	$(ECHO) "      DEVICE=<FPGA platform> [xilinx_u250_xdma_201830_2,xilinx_u250_qdma_201920_1]"
	$(ECHO) "      KERNELS=# -- in dec"
	$(ECHO) "      ENGINES=# -- in hex"
	$(ECHO) "      HEURISTIC=<h1Asc/h1Des/h2Asc/h2Des/hRand>"
	$(ECHO) ""

# Points to SDAccel_Examples Directory
COMMON_REPO = ../../Vitis_Accel_Examples
PWD = $(shell readlink -f .)
ABS_COMMON_REPO = $(shell readlink -f $(COMMON_REPO))

TARGET := hw
HOST_ARCH := x86
SYSROOT := 
DEVICE = xilinx_u250_qdma_201920_1
KERNELS = 1# in dec
ENGINES = 1# in hex
HEURISTIC = h2Des

include ./utils.mk

ifeq ($(findstring xdma, $(DEVICE)), xdma)
	XL_SHELL := xdma
else ifeq ($(findstring qdma, $(DEVICE)), qdma)
	XL_SHELL := qdma
else ifeq ($(DEVICE),$(AWS_PLATFORM))
	XL_SHELL := xdma
else
	$(error This kernel is not supported by $(DEVICE))
endif

XSA := $(call device2xsa, $(DEVICE))
TEMP_DIR := ./_xo.$(TARGET).$(XSA).$(HEURISTIC).$(ENGINES)e
BUILD_DIR := ./_xclbin.$(TARGET).$(XSA).$(HEURISTIC).$(ENGINES)e_$(shell printf "%X" $(KERNELS))k

VPP := v++
VIVADO := $(XILINX_VIVADO)/bin/vivado

#Include Libraries
include $(ABS_COMMON_REPO)/common/includes/opencl/opencl.mk
include $(ABS_COMMON_REPO)/common/includes/xcl2/xcl2.mk
CXXFLAGS += $(xcl2_CXXFLAGS)
LDFLAGS += $(xcl2_LDFLAGS)
HOST_SRCS += $(xcl2_SRCS)

CXXFLAGS += $(opencl_CXXFLAGS) -Wall -O0 -g -std=c++11
LDFLAGS += $(opencl_LDFLAGS)

HOST_SRCS += ../sw/kernel_$(XL_SHELL).cpp
# Host compiler global settings
CXXFLAGS += -fmessage-length=0
LDFLAGS += -lrt -lstdc++ 

ifneq ($(HOST_ARCH), x86)
	LDFLAGS += --sysroot=$(SYSROOT)
endif

# Kernel compiler global settings
CLFLAGS += -t $(TARGET) --platform $(DEVICE) --save-temps 
ifneq ($(TARGET), hw)
	CLFLAGS += -g
endif

EXECUTABLE = ederah_$(XL_SHELL)
EMCONFIG_DIR = $(TEMP_DIR)
EMU_DIR = $(TEMP_DIR)/data/emulation

BINARY_CONTAINERS += $(BUILD_DIR)/ederah.xclbin
BINARY_CONTAINER_ederah_OBJS += $(TEMP_DIR)/ederah.xo

CP = cp -rf

ifeq ($(DEVICE),xilinx_u250_xdma_201830_2)
	FRIENDLY_DEVICE ?= x250
else ifeq ($(DEVICE),xilinx_u250_qdma_201920_1)
	FRIENDLY_DEVICE ?= q250
else ifeq ($(DEVICE),xilinx_u280_xdma_201920_1)
	FRIENDLY_DEVICE ?= x280
else ifeq ($(DEVICE),$(AWS_PLATFORM))
	FRIENDLY_DEVICE ?= AWS
else
	FRIENDLY_DEVICE ?= NKD# NOT A KNOWN DEVICE
endif

# Execution
ifeq ($(TARGET),hw_emu)
	DATA_INPUT_PATH ?= ../sw/build-zrh_$(HEURISTIC)
else
	DATA_INPUT_PATH ?= ../sw/build-mct_$(HEURISTIC)
endif
DATA_OUTPUT_PATH := ./benchmark
FIRST_BATCH_SIZE := 1
MAX_BATCH_SIZE := 10000
ITERATIONS := 101
KERNELS_TO_RUN := 1
KERNEL_CONFIG_TAG := $(ENGINES)e$(shell printf "%X" $(KERNELS_TO_RUN))k
#
NFA_DATA_FILE := $(DATA_INPUT_PATH)/mem_edges.bin
WORKLOAD_FILE := $(DATA_INPUT_PATH)/benchmark.bin
RESULT_FILE := $(DATA_OUTPUT_PATH)/res_$(FRIENDLY_DEVICE)_$(HEURISTIC)_$(KERNEL_CONFIG_TAG).csv
BENCHMARK_FILE := $(DATA_OUTPUT_PATH)/ben_$(FRIENDLY_DEVICE)_$(HEURISTIC)_$(KERNEL_CONFIG_TAG).csv

# SIM (HW_EMU) tag
# datetime time
# exec directory

.PHONY: all clean cleanall emconfig
all: check-devices $(EXECUTABLE) $(BINARY_CONTAINERS) emconfig

.PHONY: build
build: $(BINARY_CONTAINERS)

.PHONY: compile
compile: $(EXECUTABLE)

.PHONE: run
run:
ifeq ($(HOST_ARCH), x86)
	mkdir -p $(DATA_OUTPUT_PATH)
	./$(EXECUTABLE) -b $(BUILD_DIR)/ederah.xclbin -n $(NFA_DATA_FILE) -w $(WORKLOAD_FILE) -r $(RESULT_FILE) -o $(BENCHMARK_FILE) -f $(FIRST_BATCH_SIZE) -m $(MAX_BATCH_SIZE) -i $(ITERATIONS) -k $(KERNELS_TO_RUN)
endif

# Building bitsream
$(BUILD_DIR)/ederah.xclbin: $(BINARY_CONTAINER_ederah_OBJS)
	mkdir -p $(BUILD_DIR)
	$(VPP) $(CLFLAGS) --temp_dir $(BUILD_DIR) -l $(LDCLFLAGS) --jobs $(shell grep -c ^processor /proc/cpuinfo) --optimize 3 --nk ederah:$(KERNELS) -o'$@' $(+)

# Building kernel
$(TEMP_DIR)/ederah.xo: ../hw/$(XL_SHELL)/kernel.xml ../hw/$(XL_SHELL)/package_kernel.tcl gen_xo.tcl ../hw/tools/*.vhd ../hw/engine/*.vhd ../hw/$(XL_SHELL)/*.sv ../hw/$(XL_SHELL)/*.v ../hw/custom/cfg_engines_${ENGINES}.vhd ../hw/custom/cfg_criteria_${HEURISTIC}.vhd
	mkdir -p $(TEMP_DIR)
	$(VIVADO) -mode batch -nojournal -nolog -source gen_xo.tcl -tclargs $(TEMP_DIR)/ederah.xo ederah $(TARGET) $(XSA) $(XL_SHELL) $(ENGINES) $(HEURISTIC)

# Building Host
$(EXECUTABLE): check-xrt $(HOST_SRCS) $(HOST_HDRS)
	$(CXX) $(CXXFLAGS) $(HOST_SRCS) $(HOST_HDRS) -o '$@' $(LDFLAGS)

emconfig:$(EMCONFIG_DIR)/emconfig.json
$(EMCONFIG_DIR)/emconfig.json:
	emconfigutil --platform $(DEVICE) --od $(EMCONFIG_DIR)

check: all
ifeq ($(TARGET),$(filter $(TARGET),hw_emu))
ifeq ($(HOST_ARCH), x86)
	$(CP) $(EMCONFIG_DIR)/emconfig.json .
	XCL_EMULATION_MODE=$(TARGET) ./$(EXECUTABLE) -b $(BUILD_DIR)/ederah.xclbin -n $(NFA_DATA_FILE) -w $(WORKLOAD_FILE) -r $(RESULT_FILE) -o $(BENCHMARK_FILE) -f $(FIRST_BATCH_SIZE) -m $(MAX_BATCH_SIZE) -i $(ITERATIONS) -k $(KERNELS_TO_RUN)
endif
endif
ifneq ($(TARGET),$(findstring $(TARGET), hw hw_emu))
$(warning WARNING: Application supports only hw hw_emu TARGET. Please use the target for running the application)
endif

# ifeq ($(HOST_ARCH), x86)
# 	perf_analyze profile -i profile_summary.csv -f html
# endif


aws_build: #check-aws_repo
	mkdir -p _aws
	(cd _aws && ../$(COMMON_REPO)/utility/aws/run_aws.py ../$(BINARY_CONTAINERS))
	-$(RMDIR) _aws/to_aws
	wait_for_afi.py --afi $(call GetFromJson,$(shell find _aws/ -name '*_afi_id.txt' | tail -1),FpgaImageId) --notify --email maschif@ethz.ch
	

# Cleaning stuff
clean:
	-$(RMDIR) $(EXECUTABLE)
	-$(RMDIR) profile_* TempConfig system_estimate.xtxt *.rpt *.csv 
	-$(RMDIR) *v++* .Xil .run emconfig.json *.log *.jou *.str *.wcfg *.wdb *.protoinst

cleanall: clean
	-$(RMDIR) ./_xclbin.*
	-$(RMDIR) _xo.* *xclbin.run_summary
	-$(RMDIR) ./_xo-tmp_* ./packaged_kernel* 
