#include <cstring>
#include <string>
#include <fstream>
#include <iostream>
#include <chrono>
#include <omp.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>     // parameters

#define CFG_ENGINE_NCRITERIA 22
#define EXEC_DEBUG true

typedef uint16_t                                operands_t;

const uint16_t C_CACHE_LINE_WIDTH = 64;
const uint16_t C_EDGES_PER_CACHE_LINE = C_CACHE_LINE_WIDTH / sizeof(uint64_t);
const uint16_t C_RAW_CRITERION_SIZE = sizeof(uint16_t);
const uint16_t CFG_ENGINE_CRITERION_WIDTH = 13;
const uint16_t CFG_WEIGHT_WIDTH           = 20;
const uint16_t CFG_MEM_ADDR_WIDTH         = 16;  // ceil(log2(n_bram_edges_max));

const uint64_t MASK_WEIGHT     = 0xFFFFF;
const uint64_t MASK_POINTER    = 0x7FFF;
const uint64_t MASK_OPERAND_B  = 0x3FFF; // depends on CFG_ENGINE_CRITERION_WIDTH
const uint64_t MASK_OPERAND_A  = 0x3FFF; // depends on CFG_ENGINE_CRITERION_WIDTH
const uint64_t SHIFT_LAST      = CFG_WEIGHT_WIDTH+CFG_MEM_ADDR_WIDTH+2*CFG_ENGINE_CRITERION_WIDTH;
const uint64_t SHIFT_WEIGHT    = CFG_MEM_ADDR_WIDTH+2*CFG_ENGINE_CRITERION_WIDTH;
const uint64_t SHIFT_POINTER   = 2*CFG_ENGINE_CRITERION_WIDTH;
const uint64_t SHIFT_OPERAND_B = CFG_ENGINE_CRITERION_WIDTH;
const uint64_t SHIFT_OPERAND_A = 0;

enum MatchStructureType {STRCT_SIMPLE, STRCT_PAIR};
enum MatchPairFunction {FNCTR_PAIR_NOP, FNCTR_PAIR_AND, FNCTR_PAIR_OR, FNCTR_PAIR_XOR, FNCTR_PAIR_NAND, FNCTR_PAIR_NOR};
enum MatchSimpFunction {FNCTR_SIMP_NOP, FNCTR_SIMP_EQU, FNCTR_SIMP_NEQ, FNCTR_SIMP_GRT, FNCTR_SIMP_GEQ, FNCTR_SIMP_LES, FNCTR_SIMP_LEQ};
enum MatchModeType {MODE_STRICT_MATCH, MODE_FULL_ITERATION};

const uint32_t WEIGHTS[CFG_ENGINE_NCRITERIA] = {
    0, 0, 512, 524288, 256, 262144, 65536, 64, 1, 128, 131072, 16, 16384, 2, 4, 4096, 2048, 32768,
    32, 0, 8192, 8
};

const MatchStructureType STRUCT_TYPE[CFG_ENGINE_NCRITERIA] = {
    STRCT_SIMPLE, STRCT_SIMPLE, STRCT_SIMPLE, STRCT_SIMPLE, STRCT_PAIR, STRCT_PAIR, STRCT_SIMPLE,
    STRCT_SIMPLE, STRCT_PAIR, STRCT_SIMPLE, STRCT_SIMPLE, STRCT_SIMPLE, STRCT_SIMPLE, STRCT_SIMPLE,
    STRCT_SIMPLE, STRCT_SIMPLE, STRCT_SIMPLE, STRCT_SIMPLE, STRCT_SIMPLE, STRCT_SIMPLE,
    STRCT_SIMPLE, STRCT_SIMPLE
};

const MatchPairFunction FUNCT_PAIR[CFG_ENGINE_NCRITERIA] = {
   FNCTR_PAIR_NOP, FNCTR_PAIR_NOP, FNCTR_PAIR_NOP, FNCTR_PAIR_NOP, FNCTR_PAIR_AND, FNCTR_PAIR_AND,
   FNCTR_PAIR_NOP, FNCTR_PAIR_NOP, FNCTR_PAIR_AND, FNCTR_PAIR_NOP, FNCTR_PAIR_NOP, FNCTR_PAIR_NOP,
   FNCTR_PAIR_NOP, FNCTR_PAIR_NOP, FNCTR_PAIR_NOP, FNCTR_PAIR_NOP, FNCTR_PAIR_NOP, FNCTR_PAIR_NOP,
   FNCTR_PAIR_NOP, FNCTR_PAIR_NOP, FNCTR_PAIR_NOP, FNCTR_PAIR_NOP
};

const MatchSimpFunction FUNCT_A[CFG_ENGINE_NCRITERIA] = {
    FNCTR_SIMP_EQU, FNCTR_SIMP_EQU, FNCTR_SIMP_EQU, FNCTR_SIMP_EQU, FNCTR_SIMP_GEQ, FNCTR_SIMP_GEQ,
    FNCTR_SIMP_EQU, FNCTR_SIMP_EQU, FNCTR_SIMP_GEQ, FNCTR_SIMP_EQU, FNCTR_SIMP_EQU, FNCTR_SIMP_EQU,
    FNCTR_SIMP_EQU, FNCTR_SIMP_EQU, FNCTR_SIMP_EQU, FNCTR_SIMP_EQU, FNCTR_SIMP_EQU, FNCTR_SIMP_EQU,
    FNCTR_SIMP_EQU, FNCTR_SIMP_EQU, FNCTR_SIMP_EQU, FNCTR_SIMP_EQU
};

const MatchSimpFunction FUNCT_B[CFG_ENGINE_NCRITERIA] = {
    FNCTR_SIMP_NOP, FNCTR_SIMP_NOP, FNCTR_SIMP_NOP, FNCTR_SIMP_NOP, FNCTR_SIMP_LEQ, FNCTR_SIMP_LEQ,
    FNCTR_SIMP_NOP, FNCTR_SIMP_NOP, FNCTR_SIMP_LEQ, FNCTR_SIMP_NOP, FNCTR_SIMP_NOP, FNCTR_SIMP_NOP,
    FNCTR_SIMP_NOP, FNCTR_SIMP_NOP, FNCTR_SIMP_NOP, FNCTR_SIMP_NOP, FNCTR_SIMP_NOP, FNCTR_SIMP_NOP,
    FNCTR_SIMP_NOP, FNCTR_SIMP_NOP, FNCTR_SIMP_NOP, FNCTR_SIMP_NOP
};

const bool WILDCARD_EN[CFG_ENGINE_NCRITERIA] = {
    false, false, true, true, true, true, true, true, true, true, true, true, true, true, true,
    true, true, true, true, false, true, true
};

struct edge_s {
    uint16_t operand_a;
    uint16_t operand_b;
    uint16_t pointer;
    bool last;
};

struct result_s {
    uint32_t weight;
    uint16_t pointer;
};

struct level_s {
    uint32_t weight;
    uint64_t base;
};

edge_s*   the_memory[CFG_ENGINE_NCRITERIA];

bool functor(const MatchSimpFunction& G_FUNCTION,
             const bool& G_WILDCARD,
             const uint16_t& rule_i,
             const uint16_t& query_i,
             bool* wildcard_o)
{
    bool sig_result;

    switch(G_FUNCTION)
    {
      case FNCTR_SIMP_EQU:
            sig_result = query_i == rule_i;
            break;
      case FNCTR_SIMP_NEQ:
            sig_result = query_i != rule_i;
            break;
      case FNCTR_SIMP_GRT:
            sig_result = query_i > rule_i;
            break;
      case FNCTR_SIMP_GEQ:
            sig_result = query_i >= rule_i;
            break;
      case FNCTR_SIMP_LES:
            sig_result = query_i < rule_i;
            break;
      case FNCTR_SIMP_LEQ:
            sig_result = query_i <= rule_i;
            break;
      default:
            sig_result = false;
    }

    if (G_WILDCARD and G_FUNCTION != FNCTR_SIMP_NOP)
    {
        *wildcard_o = (rule_i == 0);
        sig_result = *wildcard_o or sig_result;
    }
    else
    {
        *wildcard_o = false;
        sig_result = sig_result;
    }

    return sig_result;
}

bool matcher(const MatchStructureType& G_STRUCTURE,
             const MatchSimpFunction& G_FUNCTION_A,
             const MatchSimpFunction& G_FUNCTION_B,
             const MatchPairFunction& G_FUNCTION_PAIR,
             const bool& G_WILDCARD,
             const uint16_t& op_query_i,
             const uint16_t& opA_rule_i,
             const uint16_t& opB_rule_i,
             bool* wildcard_o)
{
    bool sig_functorA;
    bool sig_functorB;
    bool sig_wildcard_a;
    bool sig_wildcard_b;
    bool sig_mux_pair;

    sig_functorA = functor(G_FUNCTION_A, G_WILDCARD, opA_rule_i, op_query_i, &sig_wildcard_a);

    bool match_result_o;
    switch (G_STRUCTURE)
    {
      case STRCT_SIMPLE:
            *wildcard_o = sig_wildcard_a;
            match_result_o = sig_functorA;
            break;
      case STRCT_PAIR:
            sig_functorB = functor(G_FUNCTION_B, G_WILDCARD, opB_rule_i, op_query_i, &sig_wildcard_b);

            *wildcard_o = sig_wildcard_a or sig_wildcard_b;

            switch (G_FUNCTION_PAIR)
            {
              case FNCTR_PAIR_AND:
                    sig_mux_pair = sig_functorA && sig_functorB;
                    break;
              case FNCTR_PAIR_OR:
                    sig_mux_pair = sig_functorA || sig_functorB;
                    break;
              case FNCTR_PAIR_XOR:
                    sig_mux_pair = sig_functorA ^ sig_functorB;
                    break;
              case FNCTR_PAIR_NAND:
                    sig_mux_pair = !(sig_functorA && sig_functorB);
                    break;
              case FNCTR_PAIR_NOR:
                    sig_mux_pair = !(sig_functorA || sig_functorB);
                    break;
              default:
                    sig_mux_pair = false;
            }
            match_result_o = sig_mux_pair;
            break;
      default:
            match_result_o = false;;
    }

    return match_result_o;
}

void compute(const uint16_t* query, const uint16_t level, uint16_t pointer, const uint32_t interim,
             result_s* result)
{
    uint32_t aux_interim;
    bool wildcard;
    do
    {
        bool match =  matcher(STRUCT_TYPE[level], FUNCT_A[level], FUNCT_B[level], FUNCT_PAIR[level],
            WILDCARD_EN[level], *query, 
            the_memory[level][pointer].operand_a,
            the_memory[level][pointer].operand_b,
            &wildcard);

        if (!match)
            continue;

        // weight
        if (wildcard)
            aux_interim = interim;
        else
            aux_interim = interim + WEIGHTS[level];

        // check pointer or result
        if (level == CFG_ENGINE_NCRITERIA - 1)
        {
            if (aux_interim >= result->weight)
            {
                //if ((aux_interim == result->weight) && (result->pointer != the_memory[level][pointer].pointer))
                //    std::cout << "Weird\n";
                result->weight = aux_interim;
                result->pointer = the_memory[level][pointer].pointer;
                #ifdef EXEC_DEBUG
                std::cout << " level=" << level << "query=" << *query
                          << " opA=" << the_memory[level][pointer].operand_a
                          << " opB=" << the_memory[level][pointer].operand_b
                          << " pointer=" << the_memory[level][pointer].pointer
                          << " weight=" << aux_interim << std::endl;
                #endif
            }
        }
        else
        {
            #ifdef EXEC_DEBUG
            std::cout << " level=" << level << "query=" << *query
                      << " opA=" << the_memory[level][pointer].operand_a
                      << " opB=" << the_memory[level][pointer].operand_b
                      << " pointer=" << the_memory[level][pointer].pointer
                      << " weight=" << aux_interim << std::endl;
            #endif
            compute(query+1, level+1, the_memory[level][pointer].pointer, aux_interim, result);
        }
    } while(!the_memory[level][pointer++].last);
}

int main(int argc, char** argv)
{
    ////////////////////////////////////////////////////////////////////////////////////////////////
    // PARAMETERS                                                                                 //
    ////////////////////////////////////////////////////////////////////////////////////////////////

    std::cout << "# PARAMETERS" << std::endl;

    char* fullpath_workload = NULL;
    char* fullpath_nfadata = NULL;
    char* fullpath_results = NULL;
    char* fullpath_benchmark = NULL;
    uint32_t max_batch_size = 1<<10;
    uint32_t min_batch_size = 1;
    uint32_t iterations = 100;
    uint16_t cores_number = 1;

    char opt;
    while ((opt = getopt(argc, argv, "c:f:hi:m:n:o:r:w:")) != -1) {
        switch (opt) {
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
        case 'c':
            cores_number = atoi(optarg);
            break;
        case 'h':
        default: /* '?' */
            std::cerr << "Usage: " << argv[0] << "\n"
                      << "\t-n  nfa_data_file\n"
                      << "\t-w  fullpath_workload\n"
                      << "\t-r  result_data_file\n"
                      << "\t-o  benchmark_out_file\n"
                      << "\t-m  max_batch_size\n"
                      << "\t-f  first_batch_size\n"
                      << "\t-i  iterations\n"
                      << "\t-c  cores_number\n"
                      << "\t-h  help\n";
            return EXIT_FAILURE;
        }
    }

    std::cout << "-n nfa_data_file: "      << fullpath_nfadata   << std::endl;
    std::cout << "-w fullpath_workload: "  << fullpath_workload  << std::endl;
    std::cout << "-r result_data_file: "   << fullpath_results   << std::endl;
    std::cout << "-o benchmark_out_file: " << fullpath_benchmark << std::endl;
    std::cout << "-m max_batch_size: "     << max_batch_size     << std::endl;
    std::cout << "-f first_batch_size: "   << min_batch_size     << std::endl;
    std::cout << "-i iterations: "         << iterations         << std::endl;
    std::cout << "-c cores_number: "       << cores_number       << std::endl;

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // NFA SETUP                                                                                  //
    ////////////////////////////////////////////////////////////////////////////////////////////////
    
    std::cout << "# NFA SETUP" << std::endl;

    std::ifstream file_nfadata(fullpath_nfadata, std::ios::in | std::ios::binary);
    if(file_nfadata.is_open())
    {
        uint32_t num_edges;
        uint64_t raw_edge;
        uint16_t padding;
        uint64_t nfa_hash;

        file_nfadata.read(reinterpret_cast<char *>(&nfa_hash), sizeof(nfa_hash));

        for (uint16_t level=0; level<CFG_ENGINE_NCRITERIA; level++)
        {
            file_nfadata.read(reinterpret_cast<char *>(&raw_edge), sizeof(raw_edge));
            num_edges = raw_edge;
            the_memory[level] = (edge_s*) malloc(num_edges * sizeof(edge_s));
            // std::cout << " level=" << level << " edges=" << num_edges << std::endl;

            for (uint32_t i=0; i<num_edges; i++)
            {
                file_nfadata.read(reinterpret_cast<char *>(&raw_edge), sizeof(raw_edge));
                the_memory[level][i].operand_a = (raw_edge >> SHIFT_OPERAND_A) & MASK_OPERAND_A;
                the_memory[level][i].operand_b = (raw_edge >> SHIFT_OPERAND_B) & MASK_OPERAND_B;
                the_memory[level][i].pointer = (raw_edge >> SHIFT_POINTER) & MASK_POINTER;
                the_memory[level][i].last = (raw_edge >> SHIFT_LAST) & 1;
                #ifdef EXEC_DEBUG
                std::cout << "level=" << level << " edge=" << i << " data=" << raw_edge << std::endl;
                #endif
            }
            // Padding
            padding = (num_edges + 1) % C_EDGES_PER_CACHE_LINE;
            padding = (padding == 0) ? 0 : C_EDGES_PER_CACHE_LINE - padding;
            file_nfadata.seekg(padding * sizeof(raw_edge), std::ios::cur);
            #ifdef EXEC_DEBUG
            std::cout << std::endl;
            #endif
        }
        file_nfadata.seekg(0, std::ios::end);
        const uint32_t raw_size = ((uint32_t)file_nfadata.tellg()) - sizeof(nfa_hash);
        printf("> NFA size: %u bytes\n", raw_size);
        printf("> NFA hash: %lu\n", nfa_hash);
        file_nfadata.close();
    }
    else
    {
        std::cerr << "[!] Failed to open NFA .bin file\n";
        return EXIT_FAILURE;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // WORKLOAD SETUP                                                                             //
    ////////////////////////////////////////////////////////////////////////////////////////////////
    std::cout << "# WORKLOAD SETUP" << std::endl;

    char*    workload_buff;
    uint32_t workload_size; // in queries
    uint32_t query_size;    // in bytes with padding

    std::ifstream queries_file(fullpath_workload, std::ios::in | std::ios::binary);
    if(queries_file.is_open())
    {
        queries_file.seekg(0, std::ios::end);
        const uint32_t raw_size = ((uint32_t)queries_file.tellg()) - 2 * sizeof(query_size);

        queries_file.seekg(0, std::ios::beg);
        queries_file.read(reinterpret_cast<char *>(&query_size), sizeof(query_size));
        queries_file.read(reinterpret_cast<char *>(&workload_size), sizeof(workload_size));

        if (workload_size * query_size != raw_size)
        {
            std::cerr << "[!] Corrupted benchmark file!\n[!]  Expected: "
                      <<  workload_size * query_size << " bytes\n[!]  Got: "
                      << raw_size << " bytes\n";
            return EXIT_FAILURE;
        }

        workload_buff = new char[raw_size];
        queries_file.read(workload_buff, raw_size);
        queries_file.close();
    }
    else
    {
        std::cerr << "[!] Failed to open WORKLOAD .bin file\n";
        return EXIT_FAILURE;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // MULTIPLE BATCH SIZES 2^N                                                                   //
    ////////////////////////////////////////////////////////////////////////////////////////////////

    std::ofstream file_benchmark(fullpath_benchmark);
    std::ofstream file_results(fullpath_results);
    file_benchmark << "batch_size,total_ns" << std::endl;
    file_results << "query_id,content_id\n";

    operands_t* the_queries;
    uint32_t* gabarito;
    result_s* results;
    uint32_t aux = 0;
    std::chrono::time_point<std::chrono::high_resolution_clock> start, finish;
    std::chrono::duration<double, std::nano> elapsed;
    for (uint32_t bsize = min_batch_size; bsize < max_batch_size; bsize = bsize << 1)
    {
        the_queries = (operands_t*) malloc(bsize * CFG_ENGINE_NCRITERIA * sizeof(operands_t));
        results = (result_s*) calloc(bsize, sizeof(*results));
        gabarito = (uint32_t*) calloc(bsize, sizeof(*gabarito));
        
        printf("> # of queries: %9u\n", bsize);
        printf("> Queries size: %9u bytes\n", bsize * query_size);
        printf("> Results size: %9u bytes\n", bsize * (uint)sizeof(operands_t));

        for (uint32_t i = 0; i < iterations; i++)
        {
            for (uint32_t k = 0; k < bsize; k++)
            {
                memcpy(&the_queries[k*CFG_ENGINE_NCRITERIA], &(workload_buff[aux * query_size]),
                    CFG_ENGINE_NCRITERIA * sizeof(operands_t));
                gabarito[k] = aux;
                aux = (aux + 1) % workload_size;
            }
            std::memset(results, 0, bsize * sizeof(*results));

            ////////////////////////////////////////////////////////////////////////////////////////
            // KERNEL EXECUTION                                                                   //
            ////////////////////////////////////////////////////////////////////////////////////////

            start = std::chrono::high_resolution_clock::now();
            #pragma omp parallel for num_threads(cores_number)
            for (uint32_t query=0; query < bsize; query++)
            {
                compute(&the_queries[query * CFG_ENGINE_NCRITERIA],
                        0, // level
                        the_queries[query * CFG_ENGINE_NCRITERIA], // pointer
                        0, // interim
                        &results[query]);
                // std::cout << gabarito[query] << " " << results[query].pointer << std::endl
            }
            finish = std::chrono::high_resolution_clock::now();
            elapsed = finish - start;

            file_benchmark << bsize << "," << elapsed.count() << std::endl;
        }

        ////////////////////////////////////////////////////////////////////////////////////////////
        // RESULTS                                                                                //
        ////////////////////////////////////////////////////////////////////////////////////////////

        for (uint vtc = 0; vtc < bsize; ++vtc)
            file_results << gabarito[vtc] << "," << results[vtc].pointer << std::endl;

        free(the_queries);
        free(results);
        free(gabarito);
    }   
    delete [] workload_buff;
    file_benchmark.close();
    file_results.close();

    for (uint16_t level=0; level<CFG_ENGINE_NCRITERIA; level++)
        free(the_memory[level]);

    return EXIT_SUCCESS;
}