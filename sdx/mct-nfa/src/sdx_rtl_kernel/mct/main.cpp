#include "CL/cl.h"

#include <algorithm>
#include <array>
#include <chrono>
#include <cstdio>
#include <random>
#include <vector>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <iostream>
#include <fstream>
#include <math.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/time.h>

#define PATH_MAX 500

const unsigned char C_CACHELINE_SIZE   = 64; // in bytes
const unsigned char C_CRITERION_SIZE   =  4; // in bytes
const unsigned char C_RESULT_SIZE      =  2; // in bytes

////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////

typedef struct {
    char *mode;
    char *bindir;
    char *device_name;
    cl_context context;
    cl_platform_id platform_id;
    cl_device_id device_id;
    cl_command_queue command_queue;
} xcl_world;

static void* smalloc(size_t size) {
    void* ptr;

    ptr = malloc(size);

    if (ptr == NULL) {
        printf("Error: Cannot allocate memory\n");
        exit(EXIT_FAILURE);
    }

    return ptr;
}

static int load_file_to_memory(const char *filename, char **result) {
    unsigned int size;

    FILE *f = fopen(filename, "rb");
    if (f == NULL) {
        *result = NULL;
        printf("Error: Could not read file %s\n", filename);
        exit(EXIT_FAILURE);
    }

    fseek(f, 0, SEEK_END);
    size = ftell(f);
    fseek(f, 0, SEEK_SET);

    *result = (char *) smalloc(sizeof(char)*(size+1));

    if (size != fread(*result, sizeof(char), size, f)) {
        free(*result);
        printf("Error: read of kernel failed\n");
        exit(EXIT_FAILURE);
    }

    fclose(f);
    (*result)[size] = 0;

    return size;
}

char* xcl_create_and_set(const char* str) {
    size_t len = strlen(str);
    char *ret = (char*) malloc(sizeof(char)*(len+1));
    if (ret == NULL) {
        printf("ERROR: Out of Memory\n");
        exit(EXIT_FAILURE);
    }
    strcpy(ret, str);

    return ret;
}

xcl_world xcl_world_single_vendor(const char* vendor_name) {
    int err;
    xcl_world world;
    cl_uint num_platforms;

    char *xcl_mode = getenv("XCL_EMULATION_MODE");
    char *xcl_target = getenv("XCL_TARGET");

    /* Fall back mode if XCL_EMULATION_MODE is not set is "hw" */
    if(xcl_mode == NULL) {
        world.mode = xcl_create_and_set("hw");
    } else {
        /* if xcl_mode is set then check if it's equal to true*/
        if(strcmp(xcl_mode,"true") == 0) {
            /* if it's true, then check if xcl_target is set */
            if(xcl_target == NULL) {
                /* default if emulation but not specified is software emulation */
                world.mode = xcl_create_and_set("sw_emu");
            } else {
                /* otherwise, it's what ever is specified in XCL_TARGET */
                world.mode = xcl_create_and_set(xcl_target);
            }
        } else {
            /* if it's not equal to true then it should be whatever
             * XCL_EMULATION_MODE is set to */
            world.mode = xcl_create_and_set(xcl_mode);
        }
    }

    err = clGetPlatformIDs(0, NULL, &num_platforms);
    if (err != CL_SUCCESS) {
        printf("Error: no platforms available or OpenCL install broken\n");
        exit(EXIT_FAILURE);
    }

    cl_platform_id *platform_ids = (cl_platform_id *) malloc(sizeof(cl_platform_id) * num_platforms);

    if (platform_ids == NULL) {
        printf("Error: Out of Memory\n");
        exit(EXIT_FAILURE);
    }

    err = clGetPlatformIDs(num_platforms, platform_ids, NULL);
    if (err != CL_SUCCESS) {
        printf("Error: Failed to find an OpenCL platform!\n");
        exit(EXIT_FAILURE);
    }

    size_t i;
    for(i = 0; i < num_platforms; i++) {
        size_t platform_name_size;
        err = clGetPlatformInfo(platform_ids[i], CL_PLATFORM_NAME,
                                0, NULL, &platform_name_size);
        if( err != CL_SUCCESS) {
            printf("Error: Could not determine platform name!\n");
            exit(EXIT_FAILURE);
        }

        char *platform_name = (char*) malloc(sizeof(char)*platform_name_size);
        if(platform_name == NULL) {
            printf("Error: out of memory!\n");
            exit(EXIT_FAILURE);
        }

        err = clGetPlatformInfo(platform_ids[i], CL_PLATFORM_NAME,
                                platform_name_size, platform_name, NULL);
        if(err != CL_SUCCESS) {
            printf("Error: could not determine platform name!\n");
            exit(EXIT_FAILURE);
        }

        if (!strcmp(platform_name, vendor_name)) {
            free(platform_name);
            world.platform_id = platform_ids[i];
            break;
        }

        free(platform_name);
    }

    free(platform_ids);

    if (i == num_platforms) {
        printf("Error: Failed to find Xilinx platform\n");
        exit(EXIT_FAILURE);
    }

    err = clGetDeviceIDs(world.platform_id, CL_DEVICE_TYPE_ALL,
                         1, &world.device_id, NULL);
    if (err != CL_SUCCESS) {
        printf("Error: could not get device ids\n");
        exit(EXIT_FAILURE);
    }

    size_t device_name_size;
    err = clGetDeviceInfo(world.device_id, CL_DEVICE_NAME,
                          0, NULL, &device_name_size);
    if(err != CL_SUCCESS) {
        printf("Error: could not determine device name\n");
        exit(EXIT_FAILURE);
    }

    world.device_name = (char*) malloc(sizeof(char)*device_name_size);

    if(world.device_name == NULL) {
        printf("Error: Out of Memory!\n");
        exit(EXIT_FAILURE);
    }

    err = clGetDeviceInfo(world.device_id, CL_DEVICE_NAME,
                          device_name_size, world.device_name, NULL);
    if(err != CL_SUCCESS) {
        printf("Error: could not determine device name\n");
        exit(EXIT_FAILURE);
    }

    world.context = clCreateContext(0, 1, &world.device_id,
                                    NULL, NULL, &err);
    if (err != CL_SUCCESS) {
        printf("Error: Failed to create a compute context!\n");
        exit(EXIT_FAILURE);
    }

    world.command_queue = clCreateCommandQueue(world.context,
                                               world.device_id,
                                               CL_QUEUE_PROFILING_ENABLE,
                                               &err);
    if (err != CL_SUCCESS) {
        printf("Error: Failed to create a command queue!\n");
        exit(EXIT_FAILURE);
    }

    return world;
}

xcl_world xcl_world_single() {
    return xcl_world_single_vendor("Xilinx");
}

void xcl_release_world(xcl_world world) {
    clReleaseCommandQueue(world.command_queue);
    clReleaseContext(world.context);
    free(world.device_name);
    free(world.mode);
}

cl_program xcl_import_binary_file(xcl_world world, const char *xclbin_file_name) {
    int err;

    printf("INFO: Importing %s\n", xclbin_file_name);

    /*if(access(xclbin_file_name, R_OK) != 0) {
        return NULL;
        printf("ERROR: %s xclbin not available please build\n", xclbin_file_name);
        exit(EXIT_FAILURE);
    }*/

    char *krnl_bin;
    const size_t krnl_size = load_file_to_memory(xclbin_file_name, &krnl_bin);
    printf("INFO: Loaded file\n");

    cl_program program = clCreateProgramWithBinary(world.context, 1,
                                        &world.device_id, &krnl_size,
                                        (const unsigned char**) &krnl_bin,
                                        NULL, &err);
    if ((!program) || (err!=CL_SUCCESS)) {
        printf("Error: Failed to create compute program from binary %d!\n",
               err);
        printf("Test failed\n");
        exit(EXIT_FAILURE);
    }

    printf("INFO: Created Binary\n");

    err = clBuildProgram(program, 0, NULL, NULL, NULL, NULL);
    if (err != CL_SUCCESS) {
        size_t len;
        char buffer[2048];

        clGetProgramBuildInfo(program, world.device_id, CL_PROGRAM_BUILD_LOG,
                              sizeof(buffer), buffer, &len);
        printf("%s\n", buffer);
        printf("Error: Failed to build program executable!\n");
        exit(EXIT_FAILURE);
    }

    printf("INFO: Built Program\n");

    free(krnl_bin);

    return program;
}

char *xcl_get_xclbin_name(xcl_world world, const char *xclbin_name) {
    char *xcl_bindir = getenv("XCL_BINDIR");

    // typical locations of directory containing xclbin files
    const char *dirs[] = {
        xcl_bindir, // $XCL_BINDIR-specified
        "xclbin",   // command line build
        "..",       // gui build + run
        ".",        // gui build, run in build directory
        NULL
    };
    const char **search_dirs = dirs;
    if (xcl_bindir == NULL) {
        search_dirs++;
    }

    char *device_name = strdup(world.device_name);
    if (device_name == NULL) {
        printf("Error: Out of Memory\n");
        exit(EXIT_FAILURE);
    }

    // fix up device name to avoid colons and dots.
    // xilinx:xil-accel-rd-ku115:4ddr-xpr:3.2 -> xilinx_xil-accel-rd-ku115_4ddr-xpr_3_2
    for (char *c = device_name; *c != 0; c++) {
        if (*c == ':' || *c == '.') {
            *c = '_';
        }
    }

    char *device_name_versionless = strdup(world.device_name);
    if (device_name_versionless == NULL) {
        printf("Error: Out of Memory\n");
        exit(EXIT_FAILURE);
    }

    unsigned short colons = 0;
    bool colon_exist = false;
    for (char *c = device_name_versionless; *c != 0; c++) {
        if (*c == ':') {
            colons++;
            *c = '_';
            colon_exist = true;
        }
        /* Zero out version area */
        if (colons == 3) {
            *c = '\0';
        }
    }

    // versionless support if colon doesn't exist in device_name
    if(!colon_exist) {
        int len = strlen(device_name_versionless);
        device_name_versionless[len - 4] = '\0';
    }

    const char *aws_file_patterns[] = {
        "%1$s/%2$s.%3$s.%4$s.awsxclbin",     // <kernel>.<target>.<device>.awsxclbin
        "%1$s/%2$s.%3$s.%5$s.awsxclbin",     // <kernel>.<target>.<device_versionless>.awsxclbin
        "%1$s/binary_container_1.awsxclbin", // default for gui projects
        "%1$s/%2$s.awsxclbin",               // <kernel>.awsxclbin
        NULL
    };

    const char *file_patterns[] = {
        "%1$s/%2$s.%3$s.%4$s.xclbin",     // <kernel>.<target>.<device>.xclbin
        "%1$s/%2$s.%3$s.%5$s.xclbin",     // <kernel>.<target>.<device_versionless>.xclbin
        "%1$s/binary_container_1.xclbin", // default for gui projects
        "%1$s/%2$s.xclbin",               // <kernel>.xclbin
        NULL
    };
    char *xclbin_file_name = (char*) malloc(sizeof(char)*PATH_MAX);
    memset(xclbin_file_name, 0, PATH_MAX);
    ino_t aws_ino = 0; // used to avoid errors if an xclbin found via multiple/repeated paths
    for (const char **dir = search_dirs; *dir != NULL; dir++) {
        struct stat sb;
        if (stat(*dir, &sb) == 0 && S_ISDIR(sb.st_mode)) {
            for (const char **pattern = aws_file_patterns; *pattern != NULL; pattern++) {
                char file_name[PATH_MAX];
                memset(file_name, 0, PATH_MAX);
                snprintf(file_name, PATH_MAX, *pattern, *dir, xclbin_name, world.mode, device_name, device_name_versionless);
                if (stat(file_name, &sb) == 0 && S_ISREG(sb.st_mode)) {
                    world.bindir = strdup(*dir);
                    if (world.bindir == NULL) {
                        printf("Error: Out of Memory\n");
                        exit(EXIT_FAILURE);
                    }
                    if (*xclbin_file_name && sb.st_ino != aws_ino) {
                        printf("Error: multiple xclbin files discovered:\n %s\n %s\n", file_name, xclbin_file_name);
                        exit(EXIT_FAILURE);
                    }
                    aws_ino = sb.st_ino;
                    strncpy(xclbin_file_name, file_name, PATH_MAX);
                }
            }
        }
    }
    ino_t ino = 0; // used to avoid errors if an xclbin found via multiple/repeated paths
    // if no awsxclbin found, check for xclbin
    if (*xclbin_file_name == '\0') {
        for (const char **dir = search_dirs; *dir != NULL; dir++) {
            struct stat sb;
            if (stat(*dir, &sb) == 0 && S_ISDIR(sb.st_mode)) {
                for (const char **pattern = file_patterns; *pattern != NULL; pattern++) {
                    char file_name[PATH_MAX];
                    memset(file_name, 0, PATH_MAX);
                    snprintf(file_name, PATH_MAX, *pattern, *dir, xclbin_name, world.mode, device_name, device_name_versionless);
                    if (stat(file_name, &sb) == 0 && S_ISREG(sb.st_mode)) {
                        world.bindir = strdup(*dir);
                        if (world.bindir == NULL) {
                            printf("Error: Out of Memory\n");
                            exit(EXIT_FAILURE);
                        }
                        if (*xclbin_file_name && sb.st_ino != ino) {
                            printf("Error: multiple xclbin files discovered:\n %s\n %s\n", file_name, xclbin_file_name);
                            exit(EXIT_FAILURE);
                        }
                        ino = sb.st_ino;
                        strncpy(xclbin_file_name, file_name, PATH_MAX);
                    }
                }
            }
        }

    }
    // if no xclbin found, preferred path for error message from xcl_import_binary_file()
    if (*xclbin_file_name == '\0') {
        snprintf(xclbin_file_name, PATH_MAX, file_patterns[0], *search_dirs, xclbin_name, world.mode, device_name);
    }

    free(device_name);

    return xclbin_file_name;
}

cl_program xcl_import_binary(xcl_world world, const char *xclbin_name) {
    char* xclbin_file_name = xcl_get_xclbin_name(world, xclbin_name);

    cl_program program = xcl_import_binary_file(world, xclbin_file_name);

    if(program == NULL) {
        printf("ERROR: %s xclbin not available please build\n", xclbin_file_name);
        exit(EXIT_FAILURE);
    }

    free(xclbin_file_name);

    return program;
}

cl_program xcl_import_source(xcl_world world, const char *krnl_file) {
    int err;

    char *krnl_bin;
    load_file_to_memory(krnl_file, &krnl_bin);

    cl_program program = clCreateProgramWithSource(world.context, 1,
                                                   (const char**) &krnl_bin,
                                                   0, &err);
    if ((err!=CL_SUCCESS) || (!program))  {
        printf("Error: Failed to create compute program from binary %d!\n",
               err);
        printf("Test failed\n");
        exit(EXIT_FAILURE);
    }

    err = clBuildProgram(program, 0, NULL, NULL, NULL, NULL);
    if (err != CL_SUCCESS) {
        size_t len;
        char buffer[2048];

        printf("Error: Failed to build program executable!\n");
        clGetProgramBuildInfo(program, world.device_id, CL_PROGRAM_BUILD_LOG,
                              sizeof(buffer), buffer, &len);
        printf("%s\n", buffer);
        printf("Test failed\n");
        exit(EXIT_FAILURE);
    }

    free(krnl_bin);

    return program;
}

cl_kernel xcl_get_kernel(cl_program program, const char *krnl_name) {
    int err;

    cl_kernel kernel = clCreateKernel(program, krnl_name, &err);
    if (!kernel || err != CL_SUCCESS) {
        printf("Error: Failed to create kernel for %s: %d\n", krnl_name, err);
        exit(EXIT_FAILURE);
    }

    return kernel;
}

void xcl_free_kernel(cl_kernel krnl) {
    int err = clReleaseKernel(krnl);

    if (err != CL_SUCCESS) {
        printf("Error: Could not free kernel\n");
        exit(EXIT_FAILURE);
    }
}

void xcl_set_kernel_arg(cl_kernel krnl, cl_uint num, size_t size, const void *ptr) {
    int err = clSetKernelArg(krnl, num, size, ptr);

    if(err != CL_SUCCESS) {
        printf("Error: Failed to set kernel arg\n");
        exit(EXIT_FAILURE);
    }
}

cl_mem xcl_malloc(xcl_world world, cl_mem_flags flags, size_t size) {
    cl_mem mem = clCreateBuffer(world.context, flags, size, NULL, NULL);

    if (!mem) {
        printf("Error: Failed to allocate device memory!\n");
        exit(EXIT_FAILURE);
    }

    return mem;
}

void xcl_free(cl_mem mem) {
    int err = clReleaseMemObject(mem);

    if (err != CL_SUCCESS) {
        printf("Error: Failed to free device memory!\n");
        exit(EXIT_FAILURE);
    }
}

void xcl_memcpy_to_device(xcl_world world, cl_mem dest, void* src, size_t size) {
    int err = clEnqueueWriteBuffer(world.command_queue, dest, CL_TRUE, 0, size,
                                   src, 0, NULL, NULL);
    if (err != CL_SUCCESS) {
        printf("Error: Failed to write to source array! %d\n", err);
        exit(EXIT_FAILURE);
    }
}

void xcl_memcpy_from_device(xcl_world world, void* dest, cl_mem src, size_t size) {
    int err = clEnqueueReadBuffer(world.command_queue, src, CL_TRUE, 0, size,
                                  dest, 0, NULL, NULL);
    if (err != CL_SUCCESS) {
        printf("Error: Failed to read output array! %d\n", err);
        exit(EXIT_FAILURE);
    }
}

unsigned long xcl_get_event_duration(cl_event event) {
    unsigned long start, stop;

    clGetEventProfilingInfo(event, CL_PROFILING_COMMAND_START,
                            sizeof(unsigned long), &start, NULL);
    clGetEventProfilingInfo(event, CL_PROFILING_COMMAND_END,
                            sizeof(unsigned long), &stop, NULL);

    return stop - start;
}

unsigned long xcl_run_kernel3d(xcl_world world, cl_kernel krnl, size_t x, size_t y, size_t z) {
    size_t size[3] = {x, y, z};
    cl_event event;

    int err = clEnqueueNDRangeKernel(world.command_queue, krnl, 3,
                                     NULL, size, size, 0, NULL, &event);
    if( err != CL_SUCCESS) {
        printf("Error: failed to execute kernel! %d\n", err);
        exit(EXIT_FAILURE);
    }

    clFinish(world.command_queue);
    unsigned long exec_time =xcl_get_event_duration(event);
    clReleaseEvent(event);
    return exec_time;
}

void xcl_run_kernel3d_nb(xcl_world world, cl_kernel krnl, cl_event *event, size_t x, size_t y, size_t z) {
    size_t size[3] = {x, y, z};

    int err = clEnqueueNDRangeKernel(world.command_queue, krnl, 3,
                                     NULL, size, size, 0, NULL, event);
    if( err != CL_SUCCESS) {
        printf("Error: failed to execute kernel! %d\n", err);
        printf("Test failed\n");
        exit(EXIT_FAILURE);
    }
}

// Wrap any OpenCL API calls that return error code(cl_int) with the below macros
// to quickly check for an error
#define OCL_CHECK(call)                                                        \
    do {                                                                       \
        cl_int err = call;                                                     \
        if (err != CL_SUCCESS) {                                               \
            printf("Error calling " #call ", error code is: %d\n", err);       \
            exit(EXIT_FAILURE);                                                \
        }                                                                      \
    } while (0);

////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////

//Allocator template to align buffer to Page boundary for better data transfer
template <typename T>
struct aligned_allocator
{
    using value_type = T;
    T* allocate(std::size_t num)
    {
        void* ptr = nullptr;
        if (posix_memalign(&ptr, 4096, num*sizeof(T)))
            throw std::bad_alloc();
        return reinterpret_cast<T*>(ptr);
    }
    void deallocate(T* p, std::size_t num)
    {
        free(p);
    }
};

static double get_time()
{
    struct timeval t;
    gettimeofday(&t, NULL);
    return t.tv_sec + t.tv_usec*1e-6;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////

unsigned short int number_of_lines(const uint& data_size, const unsigned short int& line_size)
{
    return data_size / line_size + ((data_size % line_size) ? 1 : 0);
}

void load_nfa_from_file(char* file_name, 
    std::vector<unsigned long int, aligned_allocator<unsigned long int>>** nfa_data, uint* raw_size)
{
    std::ifstream* file = new std::ifstream(file_name, std::ios::in | std::ios::binary);
    if(file->is_open())
    {
        file->seekg(0, std::ios::end);
        *raw_size = file->tellg();

        char* file_buffer = new char[*raw_size];

        file->seekg(0, std::ios::beg);
        file->read(file_buffer, *raw_size);

        *nfa_data =
                new std::vector<unsigned long int, aligned_allocator<unsigned long int>>(*raw_size);
        memcpy((*nfa_data)->data(), file_buffer, *raw_size);
        delete [] file_buffer;

        printf("Opened NFA .bin file of size: %u\n", *raw_size); fflush(stdout);
    }
    else
    {
        *raw_size = 0;
        *nfa_data = new std::vector<unsigned long int, aligned_allocator<unsigned long int>>(*raw_size);
        printf("[!] Failed to open NFA .bin file\n"); fflush(stdout);
    }
}

void load_queries_from_file(char* file_name, uint* queries_data, uint& queries_size)
{
    std::ifstream* file = new std::ifstream(file_name, std::ios::in | std::ios::binary);
    if(file->is_open())
    {
        file->seekg(0, std::ios::end);
        uint raw_size = file->tellg();

        if (raw_size != queries_size)
        {
            printf("[!] QUERIES .bin file has unexpected size\n     - expected: %u\n     - actual: %u\n",
                    queries_size, raw_size); fflush(stdout);
        }
        else
        {
            char* file_buffer = new char[raw_size];
            file->seekg(0, std::ios::beg);
            file->read(file_buffer, raw_size);

            memcpy(queries_data, file_buffer, raw_size);
            delete [] file_buffer;

            printf("Opened QUERIES .bin file of size: %u\n", raw_size); fflush(stdout);
        }
    }
    else
        printf("[!] Failed to open QUERIES .bin file\n"); fflush(stdout);
}

void run_nfabre_kernel(cl_command_queue queue, xcl_world world, cl_program program, cl_kernel kernel, 
                void* nfa, void* queries, void* results, 
                unsigned char& num_criteria, uint& nfa_size, uint& queries_size, uint& results_size)
{
    printf("run_nfabre_kernel()\n"); fflush(stdout);

    unsigned short int nfadata_cls = nfa_size / C_CACHELINE_SIZE;
    unsigned short int queries_cls = queries_size / C_CACHELINE_SIZE;
    unsigned short int results_cls = number_of_lines(results_size, C_CACHELINE_SIZE);
    
    cl_mem buffer_queries, buffer_nfadata, buffer_results;
    size_t global = 1, local = 1;    

    // data buffers
    buffer_nfadata = clCreateBuffer(world.context, CL_MEM_READ_ONLY  | CL_MEM_USE_HOST_PTR, nfa_size, nfa, NULL);
    buffer_queries = clCreateBuffer(world.context, CL_MEM_READ_ONLY  | CL_MEM_USE_HOST_PTR, queries_size, queries, NULL);
    buffer_results = clCreateBuffer(world.context, CL_MEM_WRITE_ONLY | CL_MEM_USE_HOST_PTR, results_size, results, NULL);

    /*printf("Buffers created: nfa=%p, queries=%p, results=%p\n",
           buffer_nfadata, buffer_queries, buffer_results); fflush(stdout);*/

    OCL_CHECK(clEnqueueMigrateMemObjects(queue, 1, &buffer_nfadata, 0, 0, NULL, NULL));
    clFinish(queue);

    //Set the Kernel Arguments
    uint extraParam = 0;
    xcl_set_kernel_arg(kernel, 0, 1, &num_criteria);
    xcl_set_kernel_arg(kernel, 1, 4, &queries_cls);
    xcl_set_kernel_arg(kernel, 2, 4, &nfadata_cls);
    xcl_set_kernel_arg(kernel, 3, 4, &results_cls);
    xcl_set_kernel_arg(kernel, 4, 4, &extraParam);
    xcl_set_kernel_arg(kernel, 5, 4, &extraParam);
    xcl_set_kernel_arg(kernel, 6, sizeof(cl_mem), &buffer_nfadata);
    xcl_set_kernel_arg(kernel, 7, sizeof(cl_mem), &buffer_queries);
    xcl_set_kernel_arg(kernel, 8, sizeof(cl_mem), &buffer_results);

    double stamp00 = get_time();

    OCL_CHECK(clEnqueueMigrateMemObjects(queue, 1, &buffer_queries, 0 /* flags, 0 means from host */,
        0, NULL, NULL));

    OCL_CHECK(clEnqueueNDRangeKernel(queue, kernel, 1, nullptr, &global, &local, 0 , NULL, NULL));

    OCL_CHECK(clEnqueueMigrateMemObjects(queue, 1, &buffer_results, CL_MIGRATE_MEM_OBJECT_HOST, 
        0, NULL, NULL));

    clFlush(queue);
    clFinish(queue);

    double stamp01 = get_time();
    printf("Time to process queries: %.8f Seconds\n", stamp01-stamp00); fflush(stdout);

    //Releasing mem objects and events
    OCL_CHECK(clReleaseMemObject(buffer_nfadata));
    OCL_CHECK(clReleaseMemObject(buffer_queries));
    OCL_CHECK(clReleaseMemObject(buffer_results));
}

int main(int argc, char** argv)
{
    ////////////////////////////////////////////////////////////////////////////////////////////////
    // PARAMETERS                                                                                 //
    ////////////////////////////////////////////////////////////////////////////////////////////////

    // if (argc < 2) {
    //    printf("Usage: %s NUM_TUPLES NUM_TREES DEPTH TIMER_SET OVERLAP NUM_QUERIES\n", argv[0]);
    //    return EXIT_FAILURE;
    // }

    unsigned int  num_queries       = 136002; // atoi(argv[1]);
    unsigned char num_criteria      = 22; // atoi(argv[2]);
    char          nfa_file[100]     = "/home/maschif/gitlab/nfa-bre/sw/mem_edges.bin";
    char          queries_file[100] = "/home/maschif/gitlab/nfa-bre/sw/workload.bin";
    // TODO print parameters for structure check!

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // HARDWARE SETUP                                                                             //
    ////////////////////////////////////////////////////////////////////////////////////////////////

    printf(">> Setup FPGA\n"); fflush(stdout);
    double stamp_p0 = get_time();

    xcl_world  world   = xcl_world_single();
    cl_program program = xcl_import_binary(world, "mct");

    double stamp_p1 = get_time();
    printf("Time to program FPGA: %.8f Seconds\n", stamp_p1-stamp_p0); fflush(stdout);

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // DATA SETUP                                                                                 //
    ////////////////////////////////////////////////////////////////////////////////////////////////

    printf(">> Setup data\n"); fflush(stdout);
    unsigned int results_size = num_queries * C_RESULT_SIZE;
    unsigned int queries_size = number_of_lines(num_criteria * C_CRITERION_SIZE, C_CACHELINE_SIZE);
    queries_size = queries_size * num_queries * C_CACHELINE_SIZE;
    unsigned int nfa_size;

    std::vector<unsigned int, aligned_allocator<unsigned int>> queries(queries_size);
    std::vector<unsigned int, aligned_allocator<unsigned int>> results(results_size);
    std::vector<unsigned long int, aligned_allocator<unsigned long int>>* nfa_data;

    load_queries_from_file(queries_file, queries.data(), queries_size);
    load_nfa_from_file(nfa_file, &nfa_data, &nfa_size);

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // KERNEL EXECUTION                                                                           //
    ////////////////////////////////////////////////////////////////////////////////////////////////

    cl_kernel        kernel = xcl_get_kernel(program, "mct");
    cl_command_queue queue  = world.command_queue;

    run_nfabre_kernel(queue, world, program, kernel, nfa_data->data(), queries.data(), results.data(), 
                      num_criteria, nfa_size, queries_size, results_size);

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // RESULTS                                                                                    //
    ////////////////////////////////////////////////////////////////////////////////////////////////

    std::ofstream file;
    file.open("results.txt");

    for (uint i = 0; i < num_queries; ++i)
        file << (results.data())[i] << "\n";

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // MEMORY RELEASE                                                                             //
    ////////////////////////////////////////////////////////////////////////////////////////////////

    OCL_CHECK(clReleaseKernel(kernel));
    OCL_CHECK(clReleaseProgram(program));
    xcl_release_world(world);

    return 0;
}
