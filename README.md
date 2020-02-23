ERBium Business Rule Engine Hardware Accelerator
===========================

## Compatibility ##
- [XRT 2.3.1301](https://github.com/Xilinx/XRT/tree/2019.2.0.3)
- Vitis 2019.2
- Ubuntu 18.04.3 LTS

Board | Shell 
------|-------
Xilinx Alveo U250|xilinx_u250_xdma_201830_2
Xilinx Alveo U250|xilinx_u250_qdma_201920_1
Xilinx Alveo U280|xilinx_u280_xdma_201920_1
AWS F1 VU9P|xilinx_aws-vu9p-f1_shell-v04261818_201920_1


## NFA Generation ##
Two files are required;
 - Rules data set, formatted as `data/demo_01.csv`; and
 - Rule structure file, formatted as `data/demo_ruletype.csv`.

```
	cd sw
	make <demo|benchmarks>
```

For advanced compilation, check file `sw/erbium.cc` and read all parameters.

> Place `build_dir/cfg_criteria_<heuristic>.vhd` into `./hw/custom/`

## Hardware Compilation ##

```
    cd xilinx_work
    make <all|build|compile|check> TARGET=<sw_emu|hw_emu|hw> DEVICE=<FPGA Platform>
```

## AWS F1 Generation ##
You first need to setup the environment and install the AWS F1 shell. More information [here](https://github.com/aws/aws-fpga/tree/master/Vitis).
```
 	cd ..
	git clone https://github.com/aws/aws-fpga.git $AWS_FPGA_REPO_DIR  
    $ cd $AWS_FPGA_REPO_DIR                                         
    $ source vitis_setup.sh
```

The following script will take care of generating the bitstream, the AFI and waiting script
```
	cd erbium/xilinx_work
	make aws_build TAREGT=hw DEVICE=$AWS_PLATFORM EMAIL=<your.email@for_nofication_when.done>
```

## Execution ##
For advanced execution, check file `sw/kernel_<shell>.cpp` and read all parameters.

## Publications ##

## Citation ##