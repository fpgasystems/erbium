NFA-BRE Repository
===========================

# Compatibility #
- XRT 2.3.1301
- Vitis 2019.2
- Ubuntu 18.04.3

Board | Shell | Software Version
------|-------|------------------
Xilinx Alveo U250|xilinx_u250_xdma_201830_2|Vitis 2019.2
Xilinx Alveo U250|xilinx_u250_qdma_201920_1|Vitis 2019.2
Xilinx Alveo U280|xilinx_u280_xdma_201920_1|Vitis 2019.2
<!--AWS VU9P|xilinx_aws-vu9p-f1-04261818_dynamic_5_0|SDx 2019.1-->

# Compilation for Xilinx #

```
    cd xilinx_work
    make all TARGET=<sw_emu|hw_emu|hw> DEVICE=<FPGA Platform>
```