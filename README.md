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

> Place `sw/<build_dir>/cfg_criteria_<heuristic>.vhd` into `./hw/custom/`

## Hardware Compilation ##
> Set the `COMMON_DIR` variable in file `xilinx_work/Makefile` to your local [Xilinx Vitis Accel Examples](https://github.com/Xilinx/Vitis_Accel_Examples) directory.

```
	cd xilinx_work
	make <all|build|compile> TARGET=<sw_emu|hw_emu|hw> DEVICE=<FPGA Platform>
```

## AWS F1 Generation ##
You first need to setup the environment and install the AWS F1 shell. More information [here](https://github.com/aws/aws-fpga/tree/master/Vitis).
```
	cd ..
	git clone https://github.com/aws/aws-fpga.git $AWS_FPGA_REPO_DIR  
	cd $AWS_FPGA_REPO_DIR                                         
	source vitis_setup.sh
```

The following script will take care of generating the bitstream, the AFI and waiting script
```
	cd erbium/xilinx_work
	make aws_build TAREGT=hw DEVICE=$AWS_PLATFORM EMAIL=<your.email@for_nofication_when.done>
```

## Execution ##
```
	cd erbium/xilinx_work
	make check TAREGT=hw DEVICE=<FPGA Platform>
```
For advanced execution, check file `sw/kernel_<shell>.cpp` and read all parameters.

## Publications ##
- Fabio Maschi, Muhsen Owaida, Gustavo Alonso, Matteo Casalino, and Anthony Hock-Koon. *Making Search Engines Faster by Lowering the Cost of Querying Business Rules Through FPGAs*. In *Proceedings of the 2020 ACM SIGMOD International Conference on Management of Data (SIGMOD’20), June 14–19, 2020, Portland, OR, USA*. ACM, New York, NY, USA, 17 pages. https://doi.org/10.1145/3318464.3386133

## Citation ##
If you find the ERBium engine useful, please consider citing the following paper:
```
@inproceedings{maschi2020erbium,
  author    = {Fabio Maschi and
               Muhsen Owaida and
               Gustavo Alonso and
               Matteo Casalino and
               Anthony Hock-Koon},
  title     = {Making Search Engines Faster by Lowering the Cost of Querying
               Business Rules Through FPGAs},
  booktitle = {Proceedings of the 2020 ACM SIGMOD International Conference on
               Management of Data (SIGMOD'20), June 14--19, 2020, Portland,
               OR, USA},
  publisher = {{ACM}},
  year      = {2020},
  url       = {https://doi.org/10.1145/3318464.3386133},
  doi       = {10.1145/3318464.3386133},
}
```