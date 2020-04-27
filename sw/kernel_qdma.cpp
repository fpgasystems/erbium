////////////////////////////////////////////////////////////////////////////////////////////////////
//  ERBium - Business Rule Engine Hardware Accelerator
//  Copyright (C) 2020 Fabio Maschi - Systems Group, ETH Zurich

//  This program is free software: you can redistribute it and/or modify it under the terms of the
//  GNU Affero General Public License as published by the Free Software Foundation, either version 3
//  of the License, or (at your option) any later version.

//  This software is provided by the copyright holders and contributors "AS IS" and any express or
//  implied warranties, including, but not limited to, the implied warranties of merchantability and
//  fitness for a particular purpose are disclaimed. In no event shall the copyright holder or
//  contributors be liable for any direct, indirect, incidental, special, exemplary, or
//  consequential damages (including, but not limited to, procurement of substitute goods or
//  services; loss of use, data, or profits; or business interruption) however caused and on any
//  theory of liability, whether in contract, strict liability, or tort (including negligence or
//  otherwise) arising in any way out of the use of this software, even if advised of the 
//  possibility of such damage. See the GNU Affero General Public License for more details.

//  You should have received a copy of the GNU Affero General Public License along with this
//  program. If not, see <http://www.gnu.org/licenses/agpl-3.0.en.html>.
////////////////////////////////////////////////////////////////////////////////////////////////////

#include <iostream>
#include <string>

#include <fstream>
#include <vector>
#include <chrono>
#include <unistd.h>     // parameters
#include <stdlib.h>     // srand, rand
#include <time.h>       // time

// This extension file is required for stream APIs
#include "CL/cl_ext_xilinx.h"
// This file is required for OpenCL C++ wrapper APIs
#include "xcl2.hpp"

////////////////////////////////////////////////////////////////////////////////////////////////////
// SW / HW CONSTRAINTS                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////

// raw criterion value (must be consistent with kernel_<shell>.cpp and engine_pkg.vhd)
typedef uint16_t  operand_t;

// raw cacheline size (must be consistent with kernel_<shell>.cpp and erbium_wrapper.vhd)
const unsigned char C_CACHELINE_SIZE = 64; // in bytes


////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////

// Declaration of custom stream APIs that binds to Xilinx Streaming APIs.
decltype(&clCreateStream) xcl::Stream::createStream = nullptr;
decltype(&clReleaseStream) xcl::Stream::releaseStream = nullptr;
decltype(&clReadStream) xcl::Stream::readStream = nullptr;
decltype(&clWriteStream) xcl::Stream::writeStream = nullptr;
decltype(&clPollStreams) xcl::Stream::pollStreams = nullptr;

////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////

double calc_throput(cl::Event &wait_event, size_t vector_size_bytes) {
    unsigned long start, stop;
    cl_int err;

    OCL_CHECK(err,
              err = wait_event.getProfilingInfo<unsigned long>(
                  CL_PROFILING_COMMAND_START, &start));
    OCL_CHECK(err,
              err = wait_event.getProfilingInfo<unsigned long>(
                  CL_PROFILING_COMMAND_END, &stop));
    unsigned long duration = stop - start;
    double throput = (double)vector_size_bytes / (double)duration * 1E0 * 2;
    return throput;
}

uint64_t get_duration_ns (const cl::Event &event) {
    uint64_t nstimestart, nstimeend;
    event.getProfilingInfo<uint64_t>(CL_PROFILING_COMMAND_START, &nstimestart);
    event.getProfilingInfo<uint64_t>(CL_PROFILING_COMMAND_END, &nstimeend);
    return (nstimeend - nstimestart);
}

struct kernel_pkg_s {
    uint32_t num_queries;
    uint32_t queries_size; // in bytes with padding
    uint32_t results_size; // in bytes with padding
    cl::Kernel krnl;
    cl::Event  evtKernel;

    bool first_exec = true;

    uint offset_queries;
    uint offset_results;

    cl_stream input_stream;
    cl_stream result_stream;

    char tag_nfa[32];
    char tag_query[32];
    char tag_result[32];
};

////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////

bool load_nfa_from_file(const char* file_name,
    std::vector<uint64_t, aligned_allocator<uint64_t>>** nfa_data, uint32_t* raw_size, uint64_t* nfa_hash)
{
    std::ifstream file(file_name, std::ios::in | std::ios::binary);
    if(file.is_open())
    {
        file.seekg(0, std::ios::end);
        *raw_size = ((uint32_t)file.tellg()) - sizeof(*nfa_hash);

        char* file_buffer = new char[*raw_size];

        file.seekg(0, std::ios::beg);
        file.read(reinterpret_cast<char *>(nfa_hash), sizeof(*nfa_hash));
        file.read(file_buffer, *raw_size);

        *nfa_data = new std::vector<uint64_t, aligned_allocator<uint64_t>>(*raw_size);
        memcpy((*nfa_data)->data(), file_buffer, *raw_size);

        file.close();
        delete [] file_buffer;
        return true;
    }
    else
    {
        *raw_size = 0;
        printf("[!] Failed to open NFA .bin file\n"); fflush(stdout);
        return false;
    }
}

bool load_workload_from_file(const char* fullpath_workload, uint32_t* benchmark_size, char** workload_buff,
    uint32_t* query_size)
{
    std::ifstream file(fullpath_workload, std::ios::in | std::ios::binary);
    if(file.is_open())
    {
        file.seekg(0, std::ios::end);
        const uint32_t raw_size = ((uint32_t)file.tellg()) - 2 * sizeof(*query_size);

        file.seekg(0, std::ios::beg);
        file.read(reinterpret_cast<char *>(query_size), sizeof(*query_size));
        file.read(reinterpret_cast<char *>(benchmark_size), sizeof(*benchmark_size));

        if (*benchmark_size * *query_size != raw_size)
        {
            printf("[!] Corrupted benchmark file!\n[!]  Expected: %u bytes\n[!]  Got: %u bytes\n",
                *benchmark_size * *query_size, raw_size);
            fflush(stdout);
            return false;
        }

        *workload_buff = new char[raw_size];
        file.read(*workload_buff, raw_size);
        file.close();
    }
    else
    {
        printf("[!] Failed to open BENCHMARK .bin file\n"); fflush(stdout);
        return false;
    }
    return true;
}

int main(int argc, char** argv)
{
    ////////////////////////////////////////////////////////////////////////////////////////////////
    // PARAMETERS                                                                                 //
    ////////////////////////////////////////////////////////////////////////////////////////////////
    printf(">> Parameters\n"); fflush(stdout);

    char* fullpath_bitstream = NULL;
    char* fullpath_workload = NULL;
    char* fullpath_nfadata = NULL;
    char* fullpath_results = NULL;
    char* fullpath_benchmark = NULL;
    uint32_t max_batch_size = 1<<10;
    uint32_t min_batch_size = 1;
    uint32_t iterations = 100;
    uint16_t n_kernels = 1;
    
    char opt;
    while ((opt = getopt(argc, argv, "b:f:hi:k:m:n:o:r:w:")) != -1) {
        switch (opt) {
        case 'b':
            fullpath_bitstream = (char*) malloc(strlen(optarg)+1);
            strcpy(fullpath_bitstream, optarg);
            break;
        case 'n':
            fullpath_nfadata = (char*) malloc(strlen(optarg)+1);
            strcpy(fullpath_nfadata, optarg);
            break;
        case 'w':
            fullpath_workload = (char*) malloc(strlen(optarg)+1);
            strcpy(fullpath_workload, optarg);
            break;
        case 'r':
            fullpath_results = (char*) malloc(strlen(optarg)+1);
            strcpy(fullpath_results, optarg);
            break;
        case 'o':
            fullpath_benchmark = (char*) malloc(strlen(optarg)+1);
            strcpy(fullpath_benchmark, optarg);
            break;
        case 'm':
            max_batch_size = atoi(optarg);
            break;
        case 'f':
            min_batch_size = atoi(optarg);
            break;
        case 'i':
            iterations = atoi(optarg);
            break;
        case 'k':
            n_kernels = atoi(optarg);
            break;
        case 'h':
        default: /* '?' */
            std::cerr << "Usage: " << argv[0] << "\n"
                      << "\t-b  fullpath_bitstream\n"
                      << "\t-n  nfa_data_file\n"
                      << "\t-w  fullpath_workload\n"
                      << "\t-r  result_data_file\n"
                      << "\t-o  benchmark_out_file\n"
                      << "\t-f  first_batch_size\n"
                      << "\t-m  max_batch_size\n"
                      << "\t-i  iterations\n"
                      << "\t-k  # of kernels\n"
                      << "\t-h  help\n";
            return EXIT_FAILURE;
        }
    }

    std::cout << "-b fullpath_bitstream: " << fullpath_bitstream << std::endl;
    std::cout << "-n nfa_data_file: "      << fullpath_nfadata   << std::endl;
    std::cout << "-w fullpath_workload: "  << fullpath_workload  << std::endl;
    std::cout << "-r result_data_file: "   << fullpath_results   << std::endl;
    std::cout << "-o benchmark_out_file: " << fullpath_benchmark << std::endl;
    std::cout << "-f first_batch_size: "   << min_batch_size     << std::endl;
    std::cout << "-m max_batch_size: "     << max_batch_size     << std::endl;
    std::cout << "-i iterations: "         << iterations         << std::endl;
    std::cout << "-k # of kernels: "       << n_kernels          << std::endl;


    ////////////////////////////////////////////////////////////////////////////////////////////////
    // HARDWARE SETUP                                                                             //
    ////////////////////////////////////////////////////////////////////////////////////////////////
    printf(">> Hardware Setup\n");

    // OpenCL objects
    cl_int err;
    cl::Device device;
    cl::Context context;
    cl::CommandQueue queue;
    cl::Program program;

    auto devices = xcl::get_xil_devices();
    device = devices[0];
    devices.resize(1);

    auto fileBuf = xcl::read_binary_file(fullpath_bitstream);
    cl::Program::Binaries bins{{fileBuf.data(), fileBuf.size()}};

    OCL_CHECK(err, context = cl::Context({device}, NULL, NULL, NULL, &err));
    OCL_CHECK(err, queue = cl::CommandQueue(context, {device}, CL_QUEUE_PROFILING_ENABLE, &err));
    OCL_CHECK(err, program = cl::Program(context, devices, bins, NULL, &err));
    auto platform_id = device.getInfo<CL_DEVICE_PLATFORM>(&err);

    //Creating Kernel objects
    std::vector<kernel_pkg_s> krnls(n_kernels);
    for (int i = 0; i < n_kernels; i++) {
        auto krnl_name_full = "erbium:{erbium_" + std::to_string(i + 1) + "}";
        OCL_CHECK(err, krnls[i].krnl = cl::Kernel(program, krnl_name_full.c_str(), &err));
        sprintf(krnls[i].tag_nfa, "tag_nfa_%da", i);
        sprintf(krnls[i].tag_query, "tag_query_%da", i);
        sprintf(krnls[i].tag_result, "tag_result_%da", i);
    }

    //----------- Streaming Queues

    xcl::Stream::init(platform_id);

    cl_int ret;
    for (int i = 0; i < n_kernels; i++)
    {
        cl_mem_ext_ptr_t ext;
        ext.param = krnls[i].krnl.get();
        ext.obj = NULL;

        // Input stream
        ext.flags = 6;
        OCL_CHECK(ret,
                krnls[i].input_stream = xcl::Stream::createStream(
                    device.get(), CL_STREAM_WRITE_ONLY, CL_STREAM, &ext, &ret));

        // Result stream
        ext.flags = 5;
        OCL_CHECK(ret,
                krnls[i].result_stream = xcl::Stream::createStream(
                    device.get(), CL_STREAM_READ_ONLY, CL_STREAM, &ext, &ret));
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // NFA SETUP                                                                                  //
    ////////////////////////////////////////////////////////////////////////////////////////////////

    printf(">> NFA Setup\n"); fflush(stdout);
    uint32_t nfadata_size; // in bytes with padding
    uint64_t nfa_hash;

    std::vector<uint64_t, aligned_allocator<uint64_t>>* nfa_data;

    if(!load_nfa_from_file(fullpath_nfadata, &nfa_data, &nfadata_size, &nfa_hash))
        return EXIT_FAILURE;

    printf("> NFA size: %u bytes\n", nfadata_size);
    printf("> NFA hash: %lu\n", nfa_hash);

    srand(time(NULL));
    nfa_hash = nfa_hash + rand();

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // WORKLOAD SETUP                                                                             //
    ////////////////////////////////////////////////////////////////////////////////////////////////

    printf(">> Workload Setup\n"); fflush(stdout);
    char* workload_buff;
    uint32_t benchmark_size; // in queries
    uint32_t query_size;     // in bytes with padding
    std::vector<operand_t, aligned_allocator<operand_t>>* queries_data;
    std::vector<uint16_t, aligned_allocator<uint16_t>>* results;

    if(!load_workload_from_file(fullpath_workload, &benchmark_size, &workload_buff, &query_size))
        return EXIT_FAILURE;

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // MULTIPLE BATCH SIZES 2^N                                                                   //
    ////////////////////////////////////////////////////////////////////////////////////////////////

    std::ofstream file_benchmark(fullpath_benchmark);
    std::ofstream file_results(fullpath_results);
    file_benchmark << "batch_size,kernel,total" << std::endl;
    
    uint32_t queries_size;
    uint32_t results_size;
    uint32_t aux = 0;
    uint32_t* gabarito;

    auto start = std::chrono::high_resolution_clock::now();
    auto finish = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double, std::nano> total_ns;
    uint64_t kernel_ns;

    // Set the arguments to our compute kernel
    cl_uint d_empty = 0;
    int kid = 0;
    for (kid = 0; kid < n_kernels; kid++)
    {
        krnls[kid].krnl.setArg(0, sizeof(cl_uint), &d_empty); // not in use
        krnls[kid].krnl.setArg(1, sizeof(cl_uint), &d_empty); // not in use
        krnls[kid].krnl.setArg(2, sizeof(cl_uint), &d_empty); // not in use
        krnls[kid].krnl.setArg(3, sizeof(cl_uint), &d_empty); // not in use
        krnls[kid].krnl.setArg(4, sizeof(cl_uint), &nfa_hash); // hash to detect a diff. NFA version
    }

    for (uint32_t bsize = min_batch_size; bsize < max_batch_size; bsize = bsize << 1)
    {
        // Data management
        queries_size = bsize * query_size;
        queries_data = new std::vector<operand_t, aligned_allocator<operand_t>>(queries_size);
        gabarito = (uint32_t*) calloc(bsize, sizeof(*gabarito));

        ////////////////////////////////////////////////////////////////////////////////////////////
        // KERNEL PARTITIONS                                                                      //
        ////////////////////////////////////////////////////////////////////////////////////////////

        uint the_auxq = 0;
        uint the_auxr = 0;
        int  used_kernels = n_kernels;
        for (kid = 0; kid < n_kernels; kid++)
        {
            krnls[kid].num_queries  = bsize / n_kernels;
            if (kid == 0)
                krnls[kid].num_queries += bsize % n_kernels;

            if (krnls[kid].num_queries == 0)
            {
                used_kernels = kid;
                break;
            }

            krnls[kid].queries_size = krnls[kid].num_queries * query_size;
            krnls[kid].results_size = krnls[kid].num_queries * sizeof(operand_t);
            krnls[kid].results_size = (krnls[kid].results_size / C_CACHELINE_SIZE + ((krnls[kid].results_size % C_CACHELINE_SIZE) ? 1 : 0)) * C_CACHELINE_SIZE; // gets full liness

            krnls[kid].offset_queries = the_auxq;
            krnls[kid].offset_results = the_auxr;
            the_auxq += krnls[kid].queries_size / sizeof(operand_t);
            the_auxr += krnls[kid].results_size / sizeof(operand_t);
        }

        results_size = the_auxr * sizeof(uint16_t);
        results = new std::vector<uint16_t, aligned_allocator<uint16_t>>(results_size);

        printf("> # of queries: %9u\n", bsize);
        printf("> Queries size: %9u bytes\n", queries_size);
        printf("> Results size: %9u bytes\n", results_size); fflush(stdout);

        for (uint32_t i = 0; i < iterations; i++)
        {
            printf("\rIteration #%d", i); fflush(stdout);
            auto point = queries_data->data();
            for (uint32_t k = 0; k < bsize; k++)
            {
                memcpy(point, &(workload_buff[aux * query_size]), query_size);
                for (uint32_t j = 0; j < query_size / sizeof(operand_t); j++)
                    point++;
                gabarito[k] = aux;
                aux = (aux + 1) % benchmark_size;
            }

            ////////////////////////////////////////////////////////////////////////////////////////
            // KERNEL EXECUTION                                                                   //
            ////////////////////////////////////////////////////////////////////////////////////////

            int n_queues = 0;
            start = std::chrono::high_resolution_clock::now();

            for (kid = 0; kid < used_kernels; kid++)
            {
                // Launch the Kernel
                OCL_CHECK(err, err = queue.enqueueTask(krnls[kid].krnl, NULL, &krnls[kid].evtKernel));

                if (krnls[kid].first_exec)
                {
                    // Send NFA
                    cl_stream_xfer_req wr_req{0};
                    wr_req.flags = CL_STREAM_EOT | CL_STREAM_NONBLOCKING;
                    wr_req.priv_data = (void *)krnls[kid].tag_nfa;
                    OCL_CHECK(ret,
                            xcl::Stream::writeStream(
                                krnls[kid].input_stream, nfa_data->data(), nfadata_size, &wr_req, &ret));
                    krnls[kid].first_exec = false;
                    n_queues++;
                }

                // Send Queries
                cl_stream_xfer_req queries_wr{0};
                queries_wr.flags = CL_STREAM_EOT | CL_STREAM_NONBLOCKING;
                queries_wr.priv_data = (void *)krnls[kid].tag_query;
                OCL_CHECK(ret,
                        xcl::Stream::writeStream(krnls[kid].input_stream,
                            queries_data->data() + krnls[kid].offset_queries, krnls[kid].queries_size, &queries_wr, &ret));

                // Receive results
                cl_stream_xfer_req rd_req{0};
                rd_req.flags = CL_STREAM_EOT | CL_STREAM_NONBLOCKING;
                rd_req.priv_data = (void *)krnls[kid].tag_result;
                OCL_CHECK(ret,
                        xcl::Stream::readStream(krnls[kid].result_stream,
                            results->data() + krnls[kid].offset_results, krnls[kid].results_size, &rd_req, &ret));

            }

            // Checking the request completion
            cl_int num_compl = n_queues + 2*used_kernels;
            cl_streams_poll_req_completions poll_req[num_compl];
            memset(poll_req, 0, sizeof(cl_streams_poll_req_completions) * num_compl);
            OCL_CHECK(ret,
                      xcl::Stream::pollStreams(
                          device.get(), poll_req, num_compl, num_compl, &num_compl, 10000, &ret));

            finish = std::chrono::high_resolution_clock::now();

            if (num_compl != (n_queues + 2*used_kernels))
            {
                // Releasing Streams
                for (kid = 0; kid < n_kernels; kid++)
                {
                    xcl::Stream::releaseStream(krnls[kid].input_stream);
                    xcl::Stream::releaseStream(krnls[kid].result_stream);
                }

                delete [] workload_buff;
                file_benchmark.close();
                file_results.close();
                exit(EXIT_FAILURE);
            }
            queue.finish();

            ////////////////////////////////////////////////////////////////////////////////////////
            // TIMING REPORT                                                                      //
            ////////////////////////////////////////////////////////////////////////////////////////

            total_ns  = finish - start;
            kernel_ns = get_duration_ns(krnls[0].evtKernel);

            file_benchmark << bsize
                         << "," << kernel_ns
                         << "," << (uint64_t) total_ns.count() << std::endl;
            
            /*double throput = calc_throput(evtKernel, results_size);
            std::cout << " -> Throughput = " << throput << " GB/s\n";*/
        }

        ////////////////////////////////////////////////////////////////////////////////////////////
        // RESULTS                                                                                //
        ////////////////////////////////////////////////////////////////////////////////////////////

        file_results << "query_id,content_id\n";
        for (size_t i = 0; i < bsize; ++i)
            file_results << gabarito[i] << "," << (results->data())[i] << std::endl;
        std::cout << std::endl << std::endl;

        delete queries_data;
        delete results;
        free(gabarito);
    }

    // Releasing Streams
    for (kid = 0; kid < n_kernels; kid++)
    {
        xcl::Stream::releaseStream(krnls[kid].input_stream);
        xcl::Stream::releaseStream(krnls[kid].result_stream);
    }
    queue.flush();

    delete [] workload_buff;
    file_benchmark.close();
    file_results.close();

    return (1 ? EXIT_SUCCESS : EXIT_FAILURE);
} // end of main