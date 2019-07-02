// This is a generated file. Use and modify at your own risk.
////////////////////////////////////////////////////////////////////////////////

//-----------------------------------------------------------------------------
// kernel: mct
//
// Purpose: This kernel example shows a basic vector add +1 (constant) by
//          manipulating memory inplace.
//-----------------------------------------------------------------------------
#define BUFFER_SIZE 8192
#include <string.h>
#include <stdbool.h>
#include "hls_half.h"

// Do not modify function declaration
extern "C" void mct (
    unsigned char numCriteria,
    unsigned int queriesNumCLs,
    unsigned int edgesNumCLs,
    unsigned int resultNumCLs,
    unsigned int extraParam1,
    unsigned int extraParam2,
    int* nfaPtr,
    int* queryPtr,
    int* resultPtr
) {

    #pragma HLS INTERFACE m_axi port=nfaPtr offset=slave bundle=m00_axi
    #pragma HLS INTERFACE m_axi port=queryPtr offset=slave bundle=m00_axi
    #pragma HLS INTERFACE m_axi port=resultPtr offset=slave bundle=m00_axi
    #pragma HLS INTERFACE s_axilite port=numCriteria bundle=control
    #pragma HLS INTERFACE s_axilite port=queriesNumCLs bundle=control
    #pragma HLS INTERFACE s_axilite port=edgesNumCLs bundle=control
    #pragma HLS INTERFACE s_axilite port=resultNumCLs bundle=control
    #pragma HLS INTERFACE s_axilite port=extraParam1 bundle=control
    #pragma HLS INTERFACE s_axilite port=extraParam2 bundle=control
    #pragma HLS INTERFACE s_axilite port=nfaPtr bundle=control
    #pragma HLS INTERFACE s_axilite port=queryPtr bundle=control
    #pragma HLS INTERFACE s_axilite port=resultPtr bundle=control
    #pragma HLS INTERFACE s_axilite port=return bundle=control

// Modify contents below to match the function of the RTL Kernel
    int i = 0;

    // Create input and output buffers for interface m00_axi
    int m00_axi_input_buffer[BUFFER_SIZE];
    int m00_axi_output_buffer[BUFFER_SIZE];


    // length is specified in number of words.
    unsigned int m00_axi_length = 4096;


    // Assign input to a buffer
    memcpy(m00_axi_input_buffer, (int*) nfaPtr, m00_axi_length*sizeof(int));

    // Add 1 to input buffer and assign to output buffer.
    for (i = 0; i < m00_axi_length; i++) {
      m00_axi_output_buffer[i] = m00_axi_input_buffer[i]  + 1;
    }

    // assign output buffer out to memory
    memcpy((int*) nfaPtr, m00_axi_output_buffer, m00_axi_length*sizeof(int));


}

