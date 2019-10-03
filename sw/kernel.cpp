#include "libs/xcl2/xcl2.hpp"

#include <stdlib.h>
#include <vector>
#include <unistd.h>     // parameters

const unsigned char C_CACHELINE_SIZE   = 64; // in bytes

typedef uint16_t                                operands_t;

// void hexDump(void *addr, int len)
// {
//     unsigned char *pc = (unsigned char*)addr;
// 
//     // Process every byte in the data.
//     for (int i = 0; i < len; i++) {
//         printf(" %02x", pc[i]);
//     }
//     printf("\n");
// }
////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////

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
    
    char opt;
    while ((opt = getopt(argc, argv, "b:f:hi:m:n:o:r:sw:")) != -1) {
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
        case 'h':
        default: /* '?' */
            std::cerr << "Usage: " << argv[0] << "\n"
                      << "\t-b  fullpath_bitstream\n"
                      << "\t-n  nfa_data_file\n"
                      << "\t-w  fullpath_workload\n"
                      << "\t-r  result_data_file\n"
                      << "\t-o  benchmark_out_file\n"
                      << "\t-s  statistics\n"
                      << "\t-m  max_batch_size\n"
                      << "\t-f  first_batch_size\n"
                      << "\t-i  iterations\n"
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
    std::cout << "-m max_batch_size: "     << max_batch_size     << std::endl;
    std::cout << "-f first_batch_size: "   << min_batch_size     << std::endl;
    std::cout << "-i iterations: "         << iterations         << std::endl;

    // TODO print engine (bitstream) parameters for structure check!

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
    char* fileBuf = xcl::read_binary_file(fullpath_bitstream, fileBufSize);
    cl::Program::Binaries bins{{fileBuf, fileBufSize}};
    devices.resize(1);

    cl_int err;
    auto start = std::chrono::high_resolution_clock::now();
    OCL_CHECK(err, cl::Program program(context, devices, bins, NULL, &err));
    auto finish = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double, std::ratio<1,1>> elapsed_s = finish - start;
    printf("Time to program FPGA: %.8f Seconds\n", elapsed_s.count()); fflush(stdout);

    cl::Kernel kernel(program, "nfabre");

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // NFA SETUP                                                                                  //
    ////////////////////////////////////////////////////////////////////////////////////////////////

    printf(">> NFA Setup\n"); fflush(stdout);
    uint32_t nfadata_size; // in bytes with padding
    uint64_t nfa_hash;

    std::vector<uint64_t, aligned_allocator<uint64_t>>* nfa_data;

    if(!load_nfa_from_file(fullpath_nfadata, &nfa_data, &nfadata_size, &nfa_hash))
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
    file_benchmark << "batch_size,overhead,nfa,queries,kernel,result" << std::endl;
    
    uint32_t queries_size;   // in bytes with padding
    uint32_t results_size;   // in bytes without padding
    uint32_t queries_cls;
    uint32_t results_cls;
    uint32_t aux = 0;

    std::chrono::duration<double, std::nano> total_ns;
    uint64_t queries_ns;
    uint64_t kernel_ns;
    uint64_t result_ns;
    uint64_t events_ns;
    uint64_t opencl_ns;

    uint32_t* gabarito;
    for (uint32_t bsize = min_batch_size; bsize < max_batch_size; bsize = bsize << 1)
    {
        queries_size = bsize * query_size;
        queries_data = new std::vector<operands_t, aligned_allocator<operands_t>>(queries_size);
        results_size = bsize * sizeof(operands_t) * ((has_statistics) ? 4 : 1);
        results = new std::vector<uint16_t, aligned_allocator<uint16_t>>(results_size);
        gabarito = (uint32_t*) calloc(bsize, sizeof(*gabarito));

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
                memcpy(point, &(workload_buff[aux * query_size]), query_size);
                for (uint32_t j = 0; j < query_size / sizeof(operands_t); j++)
                    point++;
                gabarito[k] = aux;
                aux = (aux + 1) % benchmark_size;
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

            start = std::chrono::high_resolution_clock::now();

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
            finish = std::chrono::high_resolution_clock::now();

            ////////////////////////////////////////////////////////////////////////////////////////
            // TIMING REPORT                                                                      //
            ////////////////////////////////////////////////////////////////////////////////////////

            total_ns = finish - start;
            nfadata_ns = get_duration_ns(evtNFAdata);
            queries_ns = get_duration_ns(evtQueries);
            kernel_ns = get_duration_ns(evtKernel);
            result_ns = get_duration_ns(evtResult);
            events_ns = queries_ns + kernel_ns + result_ns;
            opencl_ns = total_ns.count() - events_ns;
            file_benchmark << bsize
                         << "," << opencl_ns
                         << "," << nfadata_ns
                         << "," << queries_ns
                         << "," << kernel_ns
                         << "," << result_ns << std::endl;
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
                file_results << (results->data())[i+1] << "," << (results->data())[i] << "\n";
            }
        }
        else
        {
            file_results << "query_id,content_id\n";
            for (size_t i = 0; i < bsize; ++i)
                file_results << gabarito[i] << "," << (results->data())[i] << "\n";
        }

        delete queries_data;
        delete results;
        free(gabarito);
    }
    delete [] workload_buff;
    file_benchmark.close();
    file_results.close();

    return (1 ? EXIT_SUCCESS : EXIT_FAILURE);
}
