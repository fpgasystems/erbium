#include "libs/xcl2/xcl2.hpp"

#include <stdlib.h>
#include <vector>
#include <sys/time.h>
#include <unistd.h>     // parameters

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

static double get_time()
{
    struct timeval t;
    gettimeofday(&t, NULL);
    return t.tv_sec + t.tv_usec*1e-6;
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
        *raw_size = file.tellg();

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
        *nfa_data = new std::vector<uint64_t, aligned_allocator<uint64_t>>(*raw_size);
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

bool load_workload_from_file(const char* workload_file, uint32_t* benchmark_size, char** benchmark_buff,
    uint32_t* query_size)
{
    std::ifstream file(workload_file, std::ios::in | std::ios::binary);
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

        *benchmark_buff = new char[raw_size];
        file.read(*benchmark_buff, raw_size);
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

    bool has_statistics;
    char* bitstream_file = NULL;
    char* workload_file = NULL;
    char* nfadata_file = NULL;
    char* results_file = NULL;
    char* bnchmrk_out = NULL;
    uint32_t max_batch_size = 1<<10;
    uint32_t iterations = 100;
    
    char opt;
    while ((opt = getopt(argc, argv, "b:n:w:r:o:s:m:i:h")) != -1) {
        switch (opt) {
        case 'b':
            bitstream_file = (char*) malloc(strlen(optarg)+1);
            strcpy(bitstream_file, optarg);
            break;
        case 'n':
            nfadata_file = (char*) malloc(strlen(optarg)+1);
            strcpy(nfadata_file, optarg);
            break;
        case 'w':
            workload_file = (char*) malloc(strlen(optarg)+1);
            strcpy(workload_file, optarg);
            break;
        case 'r':
            results_file = (char*) malloc(strlen(optarg)+1);
            strcpy(results_file, optarg);
            break;
        case 'o':
            bnchmrk_out = (char*) malloc(strlen(optarg)+1);
            strcpy(bnchmrk_out, optarg);
            break;
        case 's':
            has_statistics = true;
            break;
        case 'm':
            max_batch_size = atoi(optarg);
            break;
        case 'i':
            iterations = atoi(optarg);
            break;
        case 'h':
        default: /* '?' */
            std::cerr << "Usage: " << argv[0] << "\n"
                      << "\t-b  bitstream_file\n"
                      << "\t-n  nfa_data_file\n"
                      << "\t-w  workload_file\n"
                      << "\t-r  result_data_file\n"
                      << "\t-o  benchmark_out_file\n"
                      << "\t-s  statistics\n"
                      << "\t-m  max_batch_size\n"
                      << "\t-i  iterations\n"
                      << "\t-h  help\n";
            return EXIT_FAILURE;
        }
    }

    printf("-b bitstream_file: %s\n", bitstream_file);
    printf("-n nfa_data_file: %s\n", nfadata_file);
    printf("-w workload_file: %s\n", workload_file);
    printf("-r result_data_file: %s\n", results_file);
    printf("-o benchmark_out_file: %s\n", bnchmrk_out);
    printf("-s statistics: %s\n", (has_statistics) ? "yes" : "no");
    printf("-m max_batch_size: %u\n", max_batch_size);
    printf("-i iterations: %u\n", iterations);

    // TODO print parameters for structure check!

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // HARDWARE SETUP                                                                             //
    ////////////////////////////////////////////////////////////////////////////////////////////////

    printf(">> Hardware Setup\n"); fflush(stdout);

    //The get_xil_devices will return vector of Xilinx Devices
    std::vector<cl::Device> devices = xcl::get_xil_devices();
    cl::Device device = devices[0];

    //Creating Context and Command Queue for selected Device
    cl::Context context(device);
    cl::CommandQueue queue(context, device, CL_QUEUE_PROFILING_ENABLE);
    std::string device_name = device.getInfo<CL_DEVICE_NAME>();

    unsigned fileBufSize;
    char* fileBuf = xcl::read_binary_file(bitstream_file, fileBufSize);
    cl::Program::Binaries bins{{fileBuf, fileBufSize}};
    devices.resize(1);

    cl_int err;
    double stamp_p0 = get_time();
    OCL_CHECK(err, cl::Program program(context, devices, bins, NULL, &err));
    double stamp_p1 = get_time();
    printf("Time to program FPGA: %.8f Seconds\n", stamp_p1-stamp_p0); fflush(stdout);

    cl::Kernel kernel(program, "nfabre");

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // NFA SETUP                                                                                  //
    ////////////////////////////////////////////////////////////////////////////////////////////////

    printf(">> NFA Setup\n"); fflush(stdout);
    uint32_t nfadata_size; // in bytes with padding
    uint64_t nfa_hash;

    std::vector<uint64_t, aligned_allocator<uint64_t>>* nfa_data;

    if(!load_nfa_from_file(nfadata_file, &nfa_data, &nfadata_size, &nfa_hash))
        return EXIT_FAILURE;

    uint32_t nfadata_cls = nfadata_size / C_CACHELINE_SIZE;
    cl::Event evtNFAdata;
    cl::Buffer buffer_nfadata(context, CL_MEM_USE_HOST_PTR | CL_MEM_READ_ONLY,  nfadata_size, nfa_data->data());
    queue.enqueueMigrateMemObjects({buffer_nfadata}, 0/* 0 means from host*/, NULL, &evtNFAdata);
    queue.finish();

    uint64_t nfadata_ns = get_duration_ns(evtNFAdata);
    printf("> NFA size: %u bytes\n", nfadata_size);
    printf("> NFA hash: %lu\n", nfa_hash);
    printf("> Static data overhead (NFA to DDR):  %9lu ns\n", nfadata_ns); fflush(stdout);

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // QUERIES DATA                                                                               //
    ////////////////////////////////////////////////////////////////////////////////////////////////    

    printf(">> Queries Setup\n"); fflush(stdout);
    char* benchmark_buff;
    uint32_t benchmark_size; // in queries
    uint32_t query_size;     // in bytes with padding
    uint32_t queries_size;   // in bytes with padding
    uint32_t results_size;   // in bytes without padding
    uint32_t aux;
    std::vector<operands_t, aligned_allocator<operands_t>>* queries_data;
    std::vector<uint16_t, aligned_allocator<uint16_t>>* results;

    uint32_t queries_cls;
    uint32_t results_cls;

    if(!load_workload_from_file(workload_file, &benchmark_size, &benchmark_buff, &query_size))
        return EXIT_FAILURE;

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // MULTIPLE BATCH SIZES 2^N                                                                   //
    ////////////////////////////////////////////////////////////////////////////////////////////////

    std::ofstream file_bnchout(bnchmrk_out);
    file_bnchout << "batch_size,overhead,data,kernel,result,total_ns" << std::endl;

    double stamp00, stamp01;
    uint64_t total_ns;
    uint64_t queries_ns;
    uint64_t kernel_ns;
    uint64_t result_ns;
    uint64_t events_ns;
    uint64_t opencl_ns;
    for (uint32_t bsize = 1; bsize < max_batch_size; bsize = bsize << 1)
    {
        queries_size = bsize * query_size;
        queries_data = new std::vector<operands_t, aligned_allocator<operands_t>>(queries_size);
        results_size = bsize * sizeof(operands_t) * ((has_statistics) ? 4 : 1);
        results = new std::vector<uint16_t, aligned_allocator<uint16_t>>(results_size);

        queries_cls = queries_size / C_CACHELINE_SIZE;
        results_cls = (results_size / C_CACHELINE_SIZE) + (((results_size % C_CACHELINE_SIZE)==0)?0:1);

        printf("> # of queries: %9u\n", bsize);
        printf("> Queries size: %9u bytes\n", queries_size);
        printf("> Results size: %9u bytes\n", results_size); fflush(stdout);

        for (uint32_t i = 0; i < iterations; i++)
        {
            auto point = queries_data->data();
            for (uint32_t k = 0; k < bsize; k++)
            {
                aux = (rand() % benchmark_size) * query_size;
                memcpy(point, &(benchmark_buff[aux]), query_size);
                for (uint32_t j = 0; j < query_size / sizeof(operands_t); j++)
                    point++;
            }

            ////////////////////////////////////////////////////////////////////////////////////////
            // KERNEL EXECUTION                                                                   //
            ////////////////////////////////////////////////////////////////////////////////////////
            
            // allocate memory on the FPGA
            cl::Buffer buffer_queries(context, CL_MEM_USE_HOST_PTR | CL_MEM_READ_ONLY,  
                queries_size, queries_data->data());
            cl::Buffer buffer_results(context, CL_MEM_USE_HOST_PTR | CL_MEM_WRITE_ONLY,
                results_size, results->data());
            
            // events
            cl::Event evtQueries;
            cl::Event evtKernel;
            cl::Event evtResult;

            stamp00 = get_time();

            // load data via PCIe to the FPGA on-board DDR
            queue.enqueueMigrateMemObjects({buffer_queries}, 0/* 0 means from host*/, NULL, &evtQueries);

            // kernel arguments
            kernel.setArg(0, nfadata_cls);
            kernel.setArg(1, queries_cls);
            kernel.setArg(2, results_cls);
            kernel.setArg(3, (has_statistics) ? 1 : 0);
            kernel.setArg(4, nfa_hash);
            kernel.setArg(5, buffer_nfadata);
            kernel.setArg(6, buffer_queries);
            kernel.setArg(7, buffer_results);
            kernel.setArg(8, buffer_results);
            queue.enqueueTask(kernel, NULL, &evtKernel);

            // load results via PCIe from FPGA on-board DDR
            queue.enqueueMigrateMemObjects({buffer_results}, CL_MIGRATE_MEM_OBJECT_HOST, NULL, &evtResult);
            queue.finish();
            stamp01 = get_time();

            ////////////////////////////////////////////////////////////////////////////////////////
            // TIMING REPORT                                                                      //
            ////////////////////////////////////////////////////////////////////////////////////////

            total_ns = (stamp01-stamp00)*1000*1000*1000;
            nfadata_ns = get_duration_ns(evtNFAdata);
            queries_ns = get_duration_ns(evtQueries);
            kernel_ns = get_duration_ns(evtKernel);
            result_ns = get_duration_ns(evtResult);
            events_ns = queries_ns + kernel_ns + result_ns;
            opencl_ns = total_ns - events_ns;
            //double nfadata_pct = ((double) nfadata_ns) / total_ns * 100;
            //double queries_pct = ((double) queries_ns) / total_ns * 100;
            //double kernel_pct = ((double) kernel_ns) / total_ns * 100;
            //double result_pct = ((double) result_ns) / total_ns * 100;
            //double opencl_pct = ((double) opencl_ns) / total_ns * 100;

            file_bnchout << bsize
                         << "," << opencl_ns
                         << "," << nfadata_ns
                         << "," << queries_ns
                         << "," << kernel_ns
                         << "," << result_ns << std::endl;

            // printf(">> Timing report: \n");
            // printf("> Invocation overhead (opencl calls): %9lu ns (%5.2f%%)\n", opencl_ns, opencl_pct);
            // printf("> Static data overhead (NFA to DDR):  %9lu ns (%5.2f%%)\n", nfadata_ns, nfadata_pct);
            // printf("> Data transfer (Queries to DDR):     %9lu ns (%5.2f%%)\n", queries_ns, queries_pct);
            // printf("> Wall Clock Time (Kernel execution): %9lu ns (%5.2f%%)\n", kernel_ns, kernel_pct);
            // printf("> Results transfer (back from DDR):   %9lu ns (%5.2f%%)\n", result_ns, result_pct);
            // printf("> Total execution and retrieval time: %9.4f ms\n", (stamp01-stamp00)*1000);
            // printf("> Query latancy (wall clock): %2.4f us\n", ((double) kernel_ns) / 1000 / num_queries);
            // printf("> Query latency (total exec): %2.4f us\n", ((double) total_ns) / 1000 / num_queries);

        }
        delete queries_data;
        delete results;
    }
    delete [] benchmark_buff;

/*
    ////////////////////////////////////////////////////////////////////////////////////////////////
    // KERNEL EXECUTION                                                                           //
    ////////////////////////////////////////////////////////////////////////////////////////////////

    // allocate memory on the FPGA
    cl::Buffer buffer_queries(context, CL_MEM_USE_HOST_PTR | CL_MEM_READ_ONLY,  queries_size, queries->data());
    cl::Buffer buffer_results(context, CL_MEM_USE_HOST_PTR | CL_MEM_WRITE_ONLY, results_size, results.data());

    // events
    cl::Event evtQueries;
    cl::Event evtKernel;
    cl::Event evtResult;
    file_bnchout.close();

    double stamp00 = get_time();

    // load data via PCIe to the FPGA on-board DDR
    queue.enqueueMigrateMemObjects({buffer_queries}, 0, NULL, &evtQueries);

    // kernel arguments
    kernel.setArg(0, nfadata_cls);
    kernel.setArg(1, queries_cls);
    kernel.setArg(2, results_cls);
    kernel.setArg(3, (has_statistics) ? 1 : 0);
    kernel.setArg(4, nfa_hash);
    kernel.setArg(5, buffer_nfadata);
    kernel.setArg(6, buffer_queries);
    kernel.setArg(7, buffer_results);
    kernel.setArg(8, buffer_results);
    queue.enqueueTask(kernel, NULL, &evtKernel);
   
    // load results via PCIe from FPGA on-board DDR
    queue.enqueueMigrateMemObjects({buffer_results}, CL_MIGRATE_MEM_OBJECT_HOST, NULL, &evtResult);

    queue.finish();
   
    double stamp01 = get_time();

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // TIMING REPORT                                                                              //
    ////////////////////////////////////////////////////////////////////////////////////////////////

    uint64_t total_ns = (stamp01-stamp00)*1000*1000*1000;
    uint64_t nfadata_ns = get_duration_ns(evtNFAdata);
    uint64_t queries_ns = get_duration_ns(evtQueries);
    uint64_t kernel_ns = get_duration_ns(evtKernel);
    uint64_t result_ns = get_duration_ns(evtResult);
    uint64_t events_ns = nfadata_ns + queries_ns + kernel_ns + result_ns;
    uint64_t opencl_ns = total_ns - events_ns;
    double nfadata_pct = ((double) nfadata_ns) / total_ns * 100;
    double queries_pct = ((double) queries_ns) / total_ns * 100;
    double kernel_pct = ((double) kernel_ns) / total_ns * 100;
    double result_pct = ((double) result_ns) / total_ns * 100;
    double opencl_pct = ((double) opencl_ns) / total_ns * 100;

    printf(">> Timing report: \n");
    printf("> Invocation overhead (opencl calls): %9lu ns (%5.2f%%)\n", opencl_ns, opencl_pct);
    printf("> Static data overhead (NFA to DDR):  %9lu ns (%5.2f%%)\n", nfadata_ns, nfadata_pct);
    printf("> Data transfer (Queries to DDR):     %9lu ns (%5.2f%%)\n", queries_ns, queries_pct);
    printf("> Wall Clock Time (Kernel execution): %9lu ns (%5.2f%%)\n", kernel_ns, kernel_pct);
    printf("> Results transfer (back from DDR):   %9lu ns (%5.2f%%)\n", result_ns, result_pct);
    printf("> Total execution and retrieval time: %9.4f ms\n", (stamp01-stamp00)*1000);
    printf("> Query latancy (wall clock): %2.4f us\n", ((double) kernel_ns) / 1000 / num_queries);
    printf("> Query latency (total exec): %2.4f us\n", ((double) total_ns) / 1000 / num_queries);

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // RESULTS                                                                                    //
    ////////////////////////////////////////////////////////////////////////////////////////////////

    std::ofstream file;
    file.open(results_file);

    if (has_statistics)
    {
        file << "value_id,clock_cycles,higher_weight,lower_weight\n";
        for (size_t i = 0; i < num_queries*4; i=i+4)
        {
            file << (results.data())[i+3] << "," << (results.data())[i+2] << ",";
            file << (results.data())[i+1] << "," << (results.data())[i] << "\n";
        }   
    }
    else
    {
        for (size_t i = 0; i < num_queries; ++i)
            file << (results.data())[i] << "\n";
    }
    file.close();
    
    // TODO detele and release memory allocations!*/

    return (1 ? EXIT_SUCCESS : EXIT_FAILURE);
}
