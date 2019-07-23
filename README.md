
# Run in F1 #

After generating the bitstream successfully follow this steps to run on AWS F1:

1. Generate the AFI using: ```./create_sdaccel_afi.sh -xclbin=PATH/TO/*.xclbin -o=AFI-NAME -s3_bucket=sgf1 -s3_dcp_key=mydcp -s3_logs_key=logs```

This generates the following files: 
- Generates a <timestamp>_afi_id.txt which contains the identifiers for your AFI
- Creates an AWS FPGA Binary file with an *.awsxclbin extension that is composed of: Metadata and AGFI-ID.

__This *.awsxclbin is the AWS FPGA Binary file that will need to be loaded by your host application to the FPGA__

2. Check if the AFI is ready: 
```$aws ec2 describe-fpga-images --fpga-image-ids <AFI ID>```
when the AFI is ready then the output of this command includes this line:
```...```
```"State": {```
```        "Code": "available"```
```         },```
```...```

more details at: (https://github.com/aws/aws-fpga/tree/master/SDAccel)

3. Once the AFI is ready then: 
- Copy the *.awsxclbin file and software executable to your F1. 
- Clone the aws github repository to the new F1 instance and run source aws-fpga/sdaccel_setup.sh
- Clone the Xilinx XRT (https://github.com/Xilinx/XRT) and install drivers: 
```sudo sh``` 
```source /opt/xilinx/xrt/setup.sh```
- This makes the environment ready to test: ./myapp
Note that any input files and the awsxclbin file should be in the same directory of ./myapp

# Access to F1 Instance #
- Login: After launching the F1 instance from the AWS console you can log into it.
```ssh -i keys/fpgakey.pem centos@INSTANCE-IP```

- Copy files to it: ```scp -i keys/fpgakey.pem /PATH/TO/FILE centos@INSTANCE-IP:/home/centos/DEST-FILE```





