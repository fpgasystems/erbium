####################################################################################################
##  ERBium - Business Rule Engine Hardware Accelerator
##  Copyright (C) 2020 Fabio Maschi - Systems Group, ETH Zurich

##  This program is free software: you can redistribute it and/or modify it under the terms of the
##  GNU Affero General Public License as published by the Free Software Foundation, either version 3
##  of the License, or (at your option) any later version.

##  This software is provided by the copyright holders and contributors "AS IS" and any express or
##  implied warranties, including, but not limited to, the implied warranties of merchantability and
##  fitness for a particular purpose are disclaimed. In no event shall the copyright holder or
##  contributors be liable for any direct, indirect, incidental, special, exemplary, or
##  consequential damages (including, but not limited to, procurement of substitute goods or
##  services; loss of use, data, or profits; or business interruption) however caused and on any
##  theory of liability, whether in contract, strict liability, or tort (including negligence or
##  otherwise) arising in any way out of the use of this software, even if advised of the 
##  possibility of such damage. See the GNU Affero General Public License for more details.

##  You should have received a copy of the GNU Affero General Public License along with this
##  program. If not, see <http://www.gnu.org/licenses/agpl-3.0.en.html>.
####################################################################################################

help:
	$(ECHO) "Makefile Usage:"
	$(ECHO) ""
	$(ECHO) "  make all"
	$(ECHO) "      Command to generate the complete design bundle (xclbin+app)"
	$(ECHO) ""
	$(ECHO) "  make build"
	$(ECHO) "      Command to build xclbin bitstream only."
	$(ECHO) ""
	$(ECHO) "  make compile"
	$(ECHO) "      Command to compile host application only."
	$(ECHO) ""
	$(ECHO) "  make check"
	$(ECHO) "      Command to build and run application (emulation or on hw platform)"
	$(ECHO) ""
	$(ECHO) "  make run"
	$(ECHO) "      Command to run application (emulation or on hw platform)"
	$(ECHO) ""
	$(ECHO) "  options:"
	$(ECHO) "      TARGET=<hw_emu/hw>"
	$(ECHO) "      DEVICE= <$AWS_PLATFORM (default), xilinx_u250_xdma_201830_2, xilinx_u250_qdma_201920_1, xilinx_u280_xdma_201920_1>"
	$(ECHO) "      KERNELS=# -- in dec"
	$(ECHO) "      ENGINES=# -- in hex"
	$(ECHO) "      HEURISTIC=<h1Asc / h1Des / h2Asc / h2Des (default) / hRand>"
	$(ECHO) ""
	$(ECHO) "  make clean"
	$(ECHO) "      Command to remove the generated non-hardware files."
	$(ECHO) ""
	$(ECHO) "  make cleanall"
	$(ECHO) "      Command to remove all the generated files."
	$(ECHO) ""

# Points to SDAccel_Examples Directory
# !! Don't remove or rename this variable, it is reused
# into opencl/xcl2 makefiles
COMMON_REPO = ../../Vitis_Accel_Examples
PWD = $(shell readlink -f .)
ABS_COMMON_REPO = $(shell readlink -f $(COMMON_REPO))

TARGET := hw_emu
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

# Path to device platform XSA to run syn/pnr
XSA := $(call device2xsa, $(DEVICE))
# Path to build the erbium core kernel
TEMP_DIR := ./_xo.$(TARGET).$(XSA).$(HEURISTIC).$(ENGINES)e
# Path to run syn/pnr
BUILD_DIR := ./_xclbin.$(TARGET).$(XSA).$(HEURISTIC).$(ENGINES)e_$(shell printf "%X" $(KERNELS))k

# Xilinx Vivado executable
VIVADO := $(XILINX_VIVADO)/bin/vivado

# GUI or batch mode for hardware emulation
EMU_MODE = batch

# Erbium HDL sources
HW_SRCS = ../hw/$(XL_SHELL)/kernel.xml ../hw/$(XL_SHELL)/package_kernel.tcl
HW_SRCS += gen_xo.tcl ../hw/tools/*.vhd ../hw/engine/*.vhd ../hw/$(XL_SHELL)/*.sv
HW_SRCS += ../hw/$(XL_SHELL)/*.v ../hw/custom/cfg_engines_${ENGINES}.vhd
HW_SRCS += ../hw/custom/cfg_criteria_${HEURISTIC}.vhd

#Include C++ Libraries
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

EXECUTABLE = erbium_$(XL_SHELL)
EMCONFIG_DIR = $(TEMP_DIR)
EMU_DIR = $(TEMP_DIR)/data/emulation

BINARY_CONTAINERS += $(BUILD_DIR)/erbium.xclbin
BINARY_CONTAINER_erbium_OBJS += $(TEMP_DIR)/erbium.xo

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
MAX_BATCH_SIZE := 129
ITERATIONS := 1
KERNELS_TO_RUN := 1
KERNEL_CONFIG_TAG := $(ENGINES)e$(shell printf "%X" $(KERNELS_TO_RUN))k
#
NFA_DATA_FILE := $(DATA_INPUT_PATH)/mem_nfa_edges.bin
WORKLOAD_FILE := $(DATA_INPUT_PATH)/benchmark.bin
RESULT_FILE := $(DATA_OUTPUT_PATH)/res_$(FRIENDLY_DEVICE)_$(HEURISTIC)_$(KERNEL_CONFIG_TAG).csv
BENCHMARK_FILE := $(DATA_OUTPUT_PATH)/ben_$(FRIENDLY_DEVICE)_$(HEURISTIC)_$(KERNEL_CONFIG_TAG).csv

# SIM (HW_EMU) tag
# datetime time
# exec directory

.PHONY: all clean cleanall help emconfig build compile run aws_build aws_copy

# Build all generation files (for a given target)
all: check-devices compile build emconfig

# Compile CPU application
compile: $(EXECUTABLE)
$(EXECUTABLE): check-xrt $(HOST_SRCS) $(HOST_HDRS)
	$(CXX) $(CXXFLAGS) $(HOST_SRCS) $(HOST_HDRS) -o '$@' $(LDFLAGS)

# Build FPGA bitstream
build: $(BINARY_CONTAINERS)
$(BUILD_DIR)/erbium.xclbin: $(BINARY_CONTAINER_erbium_OBJS)
	mkdir -p $(BUILD_DIR)
	v++ $(CLFLAGS) --temp_dir $(BUILD_DIR) -l $(LDCLFLAGS) \
		--jobs $(shell grep -c ^processor /proc/cpuinfo) \
		--optimize 3 --nk erbium:$(KERNELS) -o'$@' $(+)

# Build kernel
$(TEMP_DIR)/erbium.xo: $(HW_SRCS)
	mkdir -p $(TEMP_DIR)
	$(VIVADO) -mode batch -nojournal -nolog -source gen_xo.tcl -tclargs $(TEMP_DIR)/erbium.xo \
		erbium $(TARGET) $(XSA) $(XL_SHELL) $(ENGINES) $(HEURISTIC)

# HW Emulation config file
emconfig: $(EMCONFIG_DIR)/emconfig.json
$(EMCONFIG_DIR)/emconfig.json:
	emconfigutil --platform $(DEVICE) --od $(EMCONFIG_DIR)

# Build everything and run 
check: all run

# Run without generation
run:
	mkdir -p $(DATA_OUTPUT_PATH)
ifeq ($(HOST_ARCH), x86)
ifeq ($(TARGET),$(filter $(TARGET),hw))
	./$(EXECUTABLE) \
		-b $(BUILD_DIR)/erbium.xclbin \
		-n $(NFA_DATA_FILE) \
		-w $(WORKLOAD_FILE) \
		-r $(RESULT_FILE) \
		-o $(BENCHMARK_FILE) \
		-f $(FIRST_BATCH_SIZE) \
		-m $(MAX_BATCH_SIZE) \
		-i $(ITERATIONS) \
		-k $(KERNELS_TO_RUN)
endif # TARGET=hw
ifeq ($(TARGET),$(filter $(TARGET),hw_emu))
ifeq ($(EMU_MODE), gui)
	sed -i 's/batch/gui/' xrt.ini
ifeq ($(EMU_MODE), batch)
	sed -i 's/gui/batch/' xrt.ini
endif # EMU_MODE
	$(CP) $(EMCONFIG_DIR)/emconfig.json .
	XCL_EMULATION_MODE=$(TARGET) ./$(EXECUTABLE) \
		-b $(BUILD_DIR)/erbium.xclbin \
		-n $(NFA_DATA_FILE) \
		-w $(WORKLOAD_FILE) \
		-r $(RESULT_FILE) \
		-o $(BENCHMARK_FILE) \
		-f $(FIRST_BATCH_SIZE) \
		-m $(MAX_BATCH_SIZE) \
		-i $(ITERATIONS) \
		-k $(KERNELS_TO_RUN)
endif # TARGET=hw_emu
	make -C ../cpu run
	diff -y --suppress-common-lines $(RESULT_FILE) ../cpu/benchmark/res*.csv
endif # HOST_ARCH

# Build FPGA bitstream and trigger AWS AFI creation
aws_build: build
	mkdir -p _aws
	-$(RMDIR) $(BUILD_DIR)/erbium.awsxclbin
	-$(RMDIR) _aws/to_aws
	(cd _aws && ../aws_create_afi.py .$(BINARY_CONTAINERS))
	wait_for_afi.py --afi $(call GetFromJson,$(shell find _aws/ -name '*_afi_id.txt' | sort -d | tail -1),FpgaImageId) --notify --email $(EMAIL)

# Copy locally generated bitstream to AWS instance
aws_copy:
	ssh -i ../keys/fpga_aws.pem centos@$(AWS_VM_IP) "mkdir -p /home/centos/gitlab/erbium/xilinx_work/$(BUILD_DIR)/"
	#scp -rpq -i ../keys/fpga_aws.pem ../sw/build-* centos@$(AWS_VM_IP):/home/centos/erbium
	scp -rqp -i ../keys/fpga_aws.pem $(BUILD_DIR)/erbium.awsxclbin centos@$(AWS_VM_IP):/home/centos/gitlab/erbium/xilinx_work/$(BUILD_DIR)/erbium.awsxclbin

# Cleaning stuff
clean:
	-$(RMDIR) $(EXECUTABLE)
	-$(RMDIR) profile_* TempConfig system_estimate.xtxt *.rpt *.csv *xclbin.run_summary
	-$(RMDIR) *v++* .Xil .run emconfig.json *.log *.jou *.str *.wcfg *.wdb *.protoinst

cleanall: clean
	-$(RMDIR) ./_xclbin.* ./_aws
	-$(RMDIR) _xo.*
	-$(RMDIR) ./_xo-tmp_* ./packaged_kernel*