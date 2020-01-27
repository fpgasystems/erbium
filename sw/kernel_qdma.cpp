#include <fcntl.h>
#include <stdio.h>
#include <iostream>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <assert.h>
#include <stdbool.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <CL/opencl.h>
#include <CL/cl_ext.h>
#include "xclhal2.h"

#include <fstream>
#include <vector>
#include <chrono>
#include <unistd.h>     // parameters
#include <thread>

typedef uint16_t                                operands_t;

////////////////////////////////////////////////////////////////////////////////

// This extension file is required for stream APIs
#include "CL/cl_ext_xilinx.h"
// This file is required for OpenCL C++ wrapper APIs
#include "xcl2.hpp"

// Declaration of custom stream APIs that binds to Xilinx Streaming APIs.
decltype(&clCreateStream) xcl::Stream::createStream = nullptr;
decltype(&clReleaseStream) xcl::Stream::releaseStream = nullptr;
decltype(&clReadStream) xcl::Stream::readStream = nullptr;
decltype(&clWriteStream) xcl::Stream::writeStream = nullptr;
decltype(&clPollStreams) xcl::Stream::pollStreams = nullptr;

////////////////////////////////////////////////////////////////////////////////

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

bool load_queries_from_file(const char* file_name,
    std::vector<operands_t, aligned_allocator<operands_t>>** queries_data,
    uint32_t* queries_size, uint32_t* results_size, uint32_t* restats_size, uint32_t* num_queries)
{
    std::ifstream file(file_name, std::ios::in | std::ios::binary);
    if(file.is_open())
    {
        file.seekg(0, std::ios::end);
        uint32_t raw_size = ((uint32_t)file.tellg()) - 4 * sizeof(*queries_size);

        file.seekg(0, std::ios::beg);
        file.read(reinterpret_cast<char *>(queries_size), sizeof(*queries_size));
        file.read(reinterpret_cast<char *>(results_size), sizeof(*results_size));
        file.read(reinterpret_cast<char *>(restats_size), sizeof(*restats_size));
        file.read(reinterpret_cast<char *>(num_queries),  sizeof(*num_queries));

        if (*queries_size != raw_size)
        {
            printf("[!] Corrupted queries file!\n[!]  Expected: %u bytes\n[!]  Got: %u bytes\n",
                *queries_size, raw_size);
            fflush(stdout);
            return false;
        }

        char* file_buffer = new char[raw_size];
        file.read(file_buffer, raw_size);

        *queries_data = new std::vector<operands_t, aligned_allocator<operands_t>>(raw_size);
        memcpy((*queries_data)->data(), file_buffer, raw_size);

        file.close();
        delete [] file_buffer;
        return true;
    }
    else
    {
        printf("[!] Failed to open QUERIES .bin file\n"); fflush(stdout);
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

    bool has_statistics = false;
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
    while ((opt = getopt(argc, argv, "b:f:hi:k:m:n:o:r:sw:")) != -1) {
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
        case 's':
            has_statistics = true;
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
                      << "\t-s  statistics\n"
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
    std::cout << "-s statistics: " << ((has_statistics) ? "yes" : "no") << std::endl;
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
    cl::Kernel kernel;

    auto devices = xcl::get_xil_devices();
    device = devices[0];
    devices.resize(1);

    auto fileBuf = xcl::read_binary_file(fullpath_bitstream);
    cl::Program::Binaries bins{{fileBuf.data(), fileBuf.size()}};

    OCL_CHECK(err, context = cl::Context({device}, NULL, NULL, NULL, &err));
    OCL_CHECK(err, queue = cl::CommandQueue(context, {device}, CL_QUEUE_PROFILING_ENABLE, &err));
    OCL_CHECK(err, program = cl::Program(context, devices, bins, NULL, &err));
    OCL_CHECK(err, kernel = cl::Kernel(program, "ederah:{ederah_1}", &err));
    auto platform_id = device.getInfo<CL_DEVICE_PLATFORM>(&err);

    //----------- Streaming Queues

    xcl::Stream::init(platform_id);

    cl_int ret;
    cl_mem_ext_ptr_t ext;

    cl_stream input_stream;
    cl_stream result_stream;

    // Input stream
    ext.param = kernel.get();
    ext.obj = NULL;
    ext.flags = 6;
    OCL_CHECK(ret, input_stream = xcl::Stream::createStream(
                        device.get(), CL_STREAM_WRITE_ONLY, CL_STREAM, &ext, &ret));

    // Result stream
    ext.flags = 5;
    OCL_CHECK(ret, result_stream = xcl::Stream::createStream(
                        device.get(), CL_STREAM_READ_ONLY, CL_STREAM, &ext, &ret));


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

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // WORKLOAD SETUP                                                                             //
    ////////////////////////////////////////////////////////////////////////////////////////////////

    printf(">> Workload Setup\n"); fflush(stdout);
    char* workload_buff;
    uint32_t benchmark_size; // in queries
    uint32_t query_size;     // in bytes with padding
    std::vector<operands_t, aligned_allocator<operands_t>>* queries_data;
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

    cl::Event evtKernel;
    auto start = std::chrono::high_resolution_clock::now();
    auto finish = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double, std::nano> total_ns;
    uint64_t kernel_ns;

    // Set the arguments to our compute kernel
    cl_uint d_empty = 0;
    kernel.setArg(0, sizeof(cl_uint), &d_empty); // TODO: remove them
    kernel.setArg(1, sizeof(cl_uint), &d_empty);
    kernel.setArg(2, sizeof(cl_uint), &d_empty);
    kernel.setArg(3, sizeof(cl_uint), &d_empty);
    kernel.setArg(4, sizeof(cl_uint), &nfa_hash);

    bool first_exec = true;
    for (uint32_t bsize = min_batch_size; bsize < max_batch_size; bsize = bsize << 1)
    {
        // batch workload
        queries_size = bsize * query_size;
        results_size = bsize * sizeof(operands_t) * ((has_statistics) ? 4 : 1);
        queries_data = new std::vector<operands_t, aligned_allocator<operands_t>>(queries_size);
        results = new std::vector<uint16_t, aligned_allocator<uint16_t>>(results_size);
        gabarito = (uint32_t*) calloc(bsize, sizeof(*gabarito));

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
                for (uint32_t j = 0; j < query_size / sizeof(operands_t); j++)
                    point++;
                gabarito[k] = aux;
                aux = (aux + 1) % benchmark_size;
            }

            ////////////////////////////////////////////////////////////////////////////////////////
            // KERNEL EXECUTION                                                                   //
            ////////////////////////////////////////////////////////////////////////////////////////

            start = std::chrono::high_resolution_clock::now();

            // Launch the Kernel
            OCL_CHECK(err, err = queue.enqueueTask(kernel, NULL, &evtKernel));

            if (first_exec)
            {
                // Send NFA
                cl_stream_xfer_req wr_req{0};
                wr_req.flags = CL_STREAM_EOT;
                std::thread thread_nfa(xcl::Stream::writeStream,
                                 input_stream,
                                 nfa_data->data(),
                                 nfadata_size,
                                 &wr_req,
                                 &ret);
                thread_nfa.join();
                first_exec = false;
            }
            // Send Queries
            cl_stream_xfer_req queries_wr{0};
            queries_wr.flags = CL_STREAM_EOT;
            std::thread thread_queries(xcl::Stream::writeStream,
                     input_stream,
                     queries_data->data(),
                     queries_size,
                     &queries_wr,
                     &ret);

            // Receive results
            cl_stream_xfer_req rd_req{0};
            rd_req.flags = CL_STREAM_EOT;
            std::thread thread_results(xcl::Stream::readStream,
                             result_stream,
                             results->data(),
                             results_size,
                             &rd_req,
                             &ret);

            thread_queries.join();
            thread_results.join();

            finish = std::chrono::high_resolution_clock::now();
            queue.finish();

            ////////////////////////////////////////////////////////////////////////////////////////
            // TIMING REPORT                                                                      //
            ////////////////////////////////////////////////////////////////////////////////////////

            total_ns  = finish - start;
            kernel_ns = get_duration_ns(evtKernel);

            file_benchmark << bsize
                         << "," << kernel_ns
                         << "," << total_ns.count() << std::endl;
            
            double throput = calc_throput(evtKernel, results_size);
            std::cout << "[ Case: 1 ] -> Throughput = " << throput << " GB/s\n";
        }

        ////////////////////////////////////////////////////////////////////////////////////////////
        // RESULTS                                                                                //
        ////////////////////////////////////////////////////////////////////////////////////////////

        if (has_statistics)
        {
            file_results << "query_id,content_id,clock_cycles,higher_weight,lower_weight\n";
            for (size_t i = 0; i < bsize*4; i=i+4)
            {
                file_results << gabarito[i/4] << ",";
                file_results << (results->data())[i+3] << "," << (results->data())[i+2] << ",";
                file_results << (results->data())[i+1] << "," << (results->data())[i] << std::endl;
            }
        }
        else
        {
            file_results << "query_id,content_id\n";
            for (size_t i = 0; i < bsize; ++i)
                file_results << gabarito[i] << "," << (results->data())[i] << std::endl;
        }
        printf("\n\n");

        delete queries_data;
        delete results;
        free(gabarito);
    }

    // Releasing Streams
    xcl::Stream::releaseStream(input_stream);
    xcl::Stream::releaseStream(result_stream);

    delete [] workload_buff;
    file_benchmark.close();
    file_results.close();

    return (1 ? EXIT_SUCCESS : EXIT_FAILURE);
} // end of main
