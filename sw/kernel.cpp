#include "libs/xcl2/xcl2.hpp"

#include <vector>
#include <sys/time.h>

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

bool load_nfa_from_file(char* file_name,
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

bool load_queries_from_file(char* file_name,
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

int main(int argc, char** argv)
{
    setlocale(LC_NUMERIC, ""); // printf with thousand comma separator

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // PARAMETERS                                                                                 //
    ////////////////////////////////////////////////////////////////////////////////////////////////

    // #include <unistd.h>
    // int opt;
    // while ((opt = getopt(argc, argv, "nt:")) != -1) {
    //     switch (opt) {
    //     case 'n':
    //         printf("option n with value '%s'\n", optarg);
    //         break;
    //     case 't':
    //         printf("option t with value '%s'\n", optarg);
    //         break;
    //     default: /* '?' */
    // std::cerr << "Usage: " << argv[0] << " <option(s)> SOURCES"
    //           << "Options:\n"
    //           << "\t-h,--help\t\tShow this help message\n"
    //           << "\t-d,--destination DESTINATION\tSpecify the destination path"
    //           << std::endl;
    //         exit(EXIT_FAILURE);
    //     }
    // }
    // return 0;

    char *nfadata_file;
    char *queries_file;
    char *results_file;
    bool stats_on;

    if (argc < 6)
    {
        printf("Usage: BITSTREAM_FILE NFA.BIN QUERIES.BIN RESULTS.TXT STATS_ON\n");
        for (int i=0; i<argc; i++)
            printf("[%u] %s\n", i, argv[i]);
        return EXIT_FAILURE;
    }

    nfadata_file = (char*) malloc(strlen(argv[2])+1);
    queries_file = (char*) malloc(strlen(argv[3])+1);
    results_file = (char*) malloc(strlen(argv[4])+1);
    strcpy(nfadata_file, argv[2]);
    strcpy(queries_file, argv[3]);
    strcpy(results_file, argv[4]);
    stats_on = (std::string(argv[5]) == "yes");

    // TODO print parameters for structure check!

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // HARDWARE SETUP                                                                             //
    ////////////////////////////////////////////////////////////////////////////////////////////////

    printf(">> Setup FPGA\n"); fflush(stdout);

    //The get_xil_devices will return vector of Xilinx Devices
    std::vector<cl::Device> devices = xcl::get_xil_devices();
    cl::Device device = devices[0];

    //Creating Context and Command Queue for selected Device
    cl::Context context(device);
    cl::CommandQueue queue(context, device, CL_QUEUE_PROFILING_ENABLE);
    std::string device_name = device.getInfo<CL_DEVICE_NAME>();

    unsigned fileBufSize;
    char* fileBuf = xcl::read_binary_file(argv[1], fileBufSize);
    cl::Program::Binaries bins{{fileBuf, fileBufSize}};
    //cl::Program::Binaries bins = xcl::import_binary_file(argv[1]);
    devices.resize(1);

    cl_int err;
    double stamp_p0 = get_time();
    OCL_CHECK(err, cl::Program program(context, devices, bins, NULL, &err));
    double stamp_p1 = get_time();
    printf("Time to program FPGA: %.8f Seconds\n", stamp_p1-stamp_p0); fflush(stdout);

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // DATA SETUP                                                                                 //
    ////////////////////////////////////////////////////////////////////////////////////////////////

    printf(">> Setup data\n"); fflush(stdout);
    uint32_t nfadata_size; // in bytes with padding
    uint32_t queries_size; // in bytes with padding
    uint32_t results_size; // in bytes without padding
    uint32_t restats_size; // in bytes without padding
    uint32_t num_queries;
    uint64_t nfa_hash;

    std::vector<uint64_t, aligned_allocator<uint64_t>>* nfa_data;
    std::vector<operands_t, aligned_allocator<operands_t>>* queries;

    bool suc;
    suc = load_nfa_from_file(nfadata_file, &nfa_data, &nfadata_size, &nfa_hash);
    suc = suc & load_queries_from_file(queries_file,
        &queries, &queries_size, &results_size, &restats_size, &num_queries);

    if(!suc)
        return EXIT_FAILURE;

    printf("> # of queries: %'9u\n", num_queries);
    printf("> NFA size:     %'9u bytes\n", nfadata_size);
    printf("> Queries size: %'9u bytes\n", queries_size);
    printf("> Results size: %'9u bytes\n", results_size);
    printf("> Stats size:   %'9u bytes\n", restats_size);
    if (stats_on)
    {
        results_size = restats_size;
        printf("Statistics report enabled\n");
    }
    else
        printf("No statistics report\n");
    fflush(stdout);

    std::vector<uint16_t, aligned_allocator<uint16_t>> results(results_size);


    // cache lines
    uint32_t nfadata_cls = nfadata_size / C_CACHELINE_SIZE;
    uint32_t queries_cls = queries_size / C_CACHELINE_SIZE;
    uint32_t results_cls = results_size / C_CACHELINE_SIZE; // TODO it will ignore the last cacheline!
    //uint32_t results_cls = number_of_lines(results_size, C_CACHELINE_SIZE);
    // must create a mask then


    ////////////////////////////////////////////////////////////////////////////////////////////////
    // KERNEL EXECUTION                                                                           //
    ////////////////////////////////////////////////////////////////////////////////////////////////

    cl::Kernel kernel(program, "nfabre");

    // allocate memory on the FPGA
    cl::Buffer buffer_nfadata(context, CL_MEM_USE_HOST_PTR | CL_MEM_READ_ONLY,  nfadata_size, nfa_data->data());
    cl::Buffer buffer_queries(context, CL_MEM_USE_HOST_PTR | CL_MEM_READ_ONLY,  queries_size, queries->data());
    cl::Buffer buffer_results(context, CL_MEM_USE_HOST_PTR | CL_MEM_WRITE_ONLY, results_size, results.data());

    // events
    cl::Event evtNFAdata;
    cl::Event evtQueries;
    cl::Event evtKernel;
    cl::Event evtResult;

    double stamp00 = get_time();

    // load data via PCIe to the FPGA on-board DDR
    queue.enqueueMigrateMemObjects({buffer_nfadata}, 0/* 0 means from host*/, NULL, &evtNFAdata);
    queue.enqueueMigrateMemObjects({buffer_queries}, 0/* 0 means from host*/, NULL, &evtQueries);

    // kernel arguments
    kernel.setArg(0, nfadata_cls);
    kernel.setArg(1, queries_cls);
    kernel.setArg(2, results_cls);
    kernel.setArg(3, (stats_on) ? 1 : 0);
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
    printf("> Invocation overhead (opencl calls): %'11lu ns (%5.2f%%)\n", opencl_ns, opencl_pct);
    printf("> Static data overhead (NFA to DDR):  %'11lu ns (%5.2f%%)\n", nfadata_ns, nfadata_pct);
    printf("> Data transfer (Queries to DDR):     %'11lu ns (%5.2f%%)\n", queries_ns, queries_pct);
    printf("> Wall Clock Time (Kernel execution): %'11lu ns (%5.2f%%)\n", kernel_ns, kernel_pct);
    printf("> Results transfer (back from DDR):   %'11lu ns (%5.2f%%)\n", result_ns, result_pct);
    printf("> Total execution and retrieval time: %'11.4f ms\n", (stamp01-stamp00)*1000);
    printf("> Query latancy (wall clock): %2.4f us\n", ((double) kernel_ns) / 1000 / num_queries);
    printf("> Query latency (total exec): %2.4f us\n", ((double) total_ns) / 1000 / num_queries);

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // RESULTS                                                                                    //
    ////////////////////////////////////////////////////////////////////////////////////////////////

    std::ofstream file;
    file.open(results_file);

    if (stats_on)
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


    // second call!
    // kernel arguments
    kernel.setArg(0, nfadata_cls);
    kernel.setArg(1, queries_cls);
    kernel.setArg(2, results_cls);
    kernel.setArg(3, (stats_on) ? 1 : 0);
    kernel.setArg(4, nfa_hash);
    kernel.setArg(5, buffer_nfadata);
    kernel.setArg(6, buffer_queries);
    kernel.setArg(7, buffer_results);
    kernel.setArg(8, buffer_results);
    queue.enqueueTask(kernel, NULL, &evtKernel);
   
    // load results via PCIe from FPGA on-board DDR
    queue.enqueueMigrateMemObjects({buffer_results}, CL_MIGRATE_MEM_OBJECT_HOST, NULL, &evtResult);

    queue.finish();

    total_ns = (stamp01-stamp00)*1000*1000*1000;
    nfadata_ns = get_duration_ns(evtNFAdata);
    queries_ns = get_duration_ns(evtQueries);
    kernel_ns = get_duration_ns(evtKernel);
    result_ns = get_duration_ns(evtResult);
    events_ns = nfadata_ns + queries_ns + kernel_ns + result_ns;
    opencl_ns = total_ns - events_ns;
    nfadata_pct = ((double) nfadata_ns) / total_ns * 100;
    queries_pct = ((double) queries_ns) / total_ns * 100;
    kernel_pct = ((double) kernel_ns) / total_ns * 100;
    result_pct = ((double) result_ns) / total_ns * 100;
    opencl_pct = ((double) opencl_ns) / total_ns * 100;

    printf(">> Timing report: \n");
    printf("> Invocation overhead (opencl calls): %'11lu ns (%5.2f%%)\n", opencl_ns, opencl_pct);
    printf("> Static data overhead (NFA to DDR):  %'11lu ns (%5.2f%%)\n", nfadata_ns, nfadata_pct);
    printf("> Data transfer (Queries to DDR):     %'11lu ns (%5.2f%%)\n", queries_ns, queries_pct);
    printf("> Wall Clock Time (Kernel execution): %'11lu ns (%5.2f%%)\n", kernel_ns, kernel_pct);
    printf("> Results transfer (back from DDR):   %'11lu ns (%5.2f%%)\n", result_ns, result_pct);
    printf("> Total execution and retrieval time: %'11.4f ms\n", (stamp01-stamp00)*1000);
    printf("> Query latancy (wall clock): %2.4f us\n", ((double) kernel_ns) / 1000 / num_queries);
    printf("> Query latency (total exec): %2.4f us\n", ((double) total_ns) / 1000 / num_queries);

    file.open("/home/maschif/gitlab/nfa-bre/data/results2.csv");

    if (stats_on)
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
    // TODO detele and release memory allocations!

    return (1 ? EXIT_SUCCESS : EXIT_FAILURE);
}
