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

#include "libs/xcl2/xcl2.hpp"

#include <stdlib.h>
#include <vector>
#include <unistd.h>     // parameters

#include <iomanip> // print hex

const unsigned char C_CACHELINE_SIZE   = 64; // in bytes

typedef uint16_t                                operands_t;

////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////

uint64_t get_duration_ns (const cl::Event &event) {
    uint64_t nstimestart, nstimeend;
    event.getProfilingInfo<uint64_t>(CL_PROFILING_COMMAND_START, &nstimestart);
    event.getProfilingInfo<uint64_t>(CL_PROFILING_COMMAND_END, &nstimeend);
    return (nstimeend - nstimestart);
}

struct kernel_pkg_s {
    uint32_t num_queries;
    uint32_t queries_size; // in bytes with padding
    uint32_t results_size; // in bytes without padding
    uint32_t queries_cls;
    uint32_t results_cls;
    cl::Kernel krnl;
    cl::Event  evtKernel;
    cl::Event  evtQueries;
    cl::Event  evtResults;
    cl::Buffer buffer_queries;
    cl::Buffer buffer_results;
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

    // validation
    if (n_kernels != 1)
    {
        std::cout << "[!] Multiple kernels no longer supported (-k 1)" << std::endl;
        n_kernels = 1;
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

    // TODO print engine (bitstream) parameters for structure check!

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // HARDWARE SETUP                                                                             //
    ////////////////////////////////////////////////////////////////////////////////////////////////
    std::cout << ">> Hardware Setup" << std::endl;

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
    auto start = std::chrono::high_resolution_clock::now();
    OCL_CHECK(err, program = cl::Program(context, devices, bins, NULL, &err));
    auto finish = std::chrono::high_resolution_clock::now();

    std::chrono::duration<double, std::ratio<1,1>> elapsed_s = finish - start;
    std::cout << "Time to program FPGA: " << elapsed_s.count() << "seconds" << std::endl;

    //Creating Kernel object
    kernel_pkg_s kernel;
    OCL_CHECK(err, kernel.krnl = cl::Kernel(program, "erbium", &err));

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // NFA SETUP                                                                                  //
    ////////////////////////////////////////////////////////////////////////////////////////////////
    std::cout << ">> NFA Setup" << std::endl;

    uint32_t nfadata_size; // in bytes with padding
    uint64_t nfa_hash;

    std::vector<uint64_t, aligned_allocator<uint64_t>>* nfa_data;

    if(!load_nfa_from_file(fullpath_nfadata, &nfa_data, &nfadata_size, &nfa_hash))
        return EXIT_FAILURE;

    uint32_t nfadata_cls = nfadata_size / C_CACHELINE_SIZE;
    cl::Event evtNFAdata;
    OCL_CHECK(err,
              cl::Buffer buffer_nfadata(context,
                                        CL_MEM_USE_HOST_PTR | CL_MEM_READ_ONLY,
                                        nfadata_size,
                                        nfa_data->data(),
                                        &err));
    /*OCL_CHECK(err,
              err = queue.enqueueMigrateMemObjects({buffer_nfadata},
                                                   0,
                                                   NULL,
                                                   &evtNFAdata));*/

    //queue.finish();

    uint64_t nfadata_ns = get_duration_ns(evtNFAdata);
    std::cout << "> NFA size: " << nfadata_size << " bytes" << std::endl;
    std::cout << "> NFA hash: " << nfa_hash << std::endl;
    std::cout << "> Static data overhead (NFA to DDR): " << nfadata_ns << " ns" << std::endl;

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // WORKLOAD SETUP                                                                             //
    ////////////////////////////////////////////////////////////////////////////////////////////////
    std::cout << ">> Workload Setup" << std::endl;
    
    char* workload_buff;
    uint32_t benchmark_size; // in queries
    uint32_t query_size;     // in bytes with padding
    std::vector<operands_t, aligned_allocator<operands_t>>* queries_data;
    std::vector<uint16_t, aligned_allocator<uint16_t>>* results;

    if(!load_workload_from_file(fullpath_workload, &benchmark_size, &workload_buff, &query_size))
        return EXIT_FAILURE;

    std::cout << "> Benchmark: " << benchmark_size << " queries" << std::endl;
    std::cout << "> Total size: " << query_size * benchmark_size << " bytes" << std::endl;

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // MULTIPLE BATCH SIZES 2^N                                                                   //
    ////////////////////////////////////////////////////////////////////////////////////////////////

    std::ofstream file_benchmark(fullpath_benchmark);
    std::ofstream file_results(fullpath_results);
    file_benchmark << "batch_size,overhead,nfa,queries,kernel,result,total_ns" << std::endl;
    
    uint32_t aux = 0; // circular iterator over all the queries from benchmark.bin

    std::chrono::duration<double, std::nano> total_ns;
    uint64_t queries_ns;
    uint64_t kernel_ns;
    uint64_t result_ns;
    uint64_t events_ns;
    uint64_t opencl_ns;

    uint32_t* gabarito;
    for (uint32_t bsize = min_batch_size; bsize < max_batch_size; bsize = bsize << 1)
    {
        kernel.num_queries = bsize;
        kernel.queries_size = kernel.num_queries * query_size;
        kernel.results_size = kernel.num_queries * sizeof(operands_t);
        kernel.queries_cls  = kernel.queries_size / C_CACHELINE_SIZE;
        kernel.results_cls  = (kernel.results_size / C_CACHELINE_SIZE) + (((kernel.results_size % C_CACHELINE_SIZE)==0)?0:1);

        // batch workload
        queries_data = new std::vector<operands_t, aligned_allocator<operands_t>>(kernel.queries_size);
        results = new std::vector<uint16_t, aligned_allocator<uint16_t>>(kernel.results_size);
        gabarito = (uint32_t*) calloc(bsize, sizeof(*gabarito));


        printf("> # of queries: %9u\n", kernel.num_queries);
        printf("> Queries size: %9u bytes\n", kernel.queries_size);
        printf("> Results size: %9u bytes\n", kernel.results_size);
        printf("> queries_cls:  %9u\n", kernel.queries_cls);
        printf("> results_cls:  %9u\n", kernel.results_cls); fflush(stdout);
            
        // allocate memory
        OCL_CHECK(err,
                  kernel.buffer_queries =
                      cl::Buffer(context,
                                 CL_MEM_USE_HOST_PTR | CL_MEM_READ_ONLY,
                                 kernel.queries_size,
                                 queries_data->data(),
                                 &err));
        OCL_CHECK(err,
                  kernel.buffer_results =
                      cl::Buffer(context,
                                 CL_MEM_USE_HOST_PTR | CL_MEM_WRITE_ONLY,
                                 kernel.results_size,
                                 results->data(),
                                 &err));

        // kernel arguments
        kernel.krnl.setArg(0, nfadata_cls);            // # of cache-lines of NFA data
        kernel.krnl.setArg(1, kernel.queries_cls);     // # of cache-lines of queries
        kernel.krnl.setArg(2, kernel.results_cls);     // # of cache-lines of results
        kernel.krnl.setArg(3, nfa_hash);               // hash per NFA version
        kernel.krnl.setArg(4, buffer_nfadata);         // @pointer to NFA data in FPGA
        kernel.krnl.setArg(5, kernel.buffer_queries);  // @pointer to queries data
        kernel.krnl.setArg(6, kernel.buffer_results);  // @pointer to results data

        for (uint32_t i = 0; i < iterations; i++)
        {
            printf("\rIteration #%d", i); fflush(stdout);

            // Prepare queries to be processed
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

            // load data via PCIe to the FPGA on-board DDR
            queue.enqueueMigrateMemObjects({buffer_nfadata, kernel.buffer_queries},
                                           0 /* 0 means from host*/, NULL, &kernel.evtQueries);

            // kernel launch
            queue.enqueueTask(kernel.krnl, NULL, &kernel.evtKernel);
            
            //queue.finish();

            // load results via PCIe from FPGA on-board DDR
            queue.enqueueMigrateMemObjects({kernel.buffer_results},
                                           CL_MIGRATE_MEM_OBJECT_HOST, NULL, &kernel.evtResults);

            queue.finish();
            finish = std::chrono::high_resolution_clock::now();
            //queue.flush();

            /*for (size_t i = 0; i < bsize; ++i)
                std::cout << gabarito[i] << "," << (results->data())[i] << std::endl;*/
            
            ////////////////////////////////////////////////////////////////////////////////////////
            // TIMING REPORT                                                                      //
            ////////////////////////////////////////////////////////////////////////////////////////

            total_ns = finish - start;
            queries_ns = get_duration_ns(kernel.evtQueries);
            result_ns  = get_duration_ns(kernel.evtResults);
            kernel_ns  = get_duration_ns(kernel.evtKernel);
            events_ns  = queries_ns + kernel_ns + result_ns;            
            opencl_ns  = (total_ns.count() >= events_ns) ? total_ns.count() - events_ns : 0;
            file_benchmark << bsize
                         << "," << opencl_ns
                         << "," << nfadata_ns
                         << "," << queries_ns
                         << "," << kernel_ns
                         << "," << result_ns
                         << "," << total_ns.count() << std::endl;
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
    delete [] workload_buff;
    file_benchmark.close();
    file_results.close();

    return (1 ? EXIT_SUCCESS : EXIT_FAILURE);
} // end of main