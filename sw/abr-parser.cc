#include <boost/graph/adjacency_list.hpp>
#include <string>
#include <exception>
#include <iostream>
#include <fstream>
#include <chrono>
#include <math.h>
#include <unistd.h>
#include <filesystem>

#include "definitions.h"
#include "dictionnary.h"
#include "nfa_handler.h"

enum SortOption { None, Ascending, Descending, MCT_DESC, MCT_PERF };

//#define _DEBUG true

int main(int argc, char** argv)
{
    ////////////////////////////////////////////////////////////////////////////////////////////////
    // PARAMETERS                                                                                 //
    ////////////////////////////////////////////////////////////////////////////////////////////////
    std::cout << "# PARAMETERS" << std::endl;
    // -d destination folder
    // -r rules file
    // -s sorting: 0=none 1=asc 2=desc 3=mct_asc 4=mct_perf
    // -z [ZRH workload]
    // -h help

    SortOption sorting_option = MCT_DESC;
    std::string dest_folder = "build/";
    std::string rules_file = "../../../Documents/amadeus-share/mct_rules.csv";

    int opt;
    while ((opt = getopt(argc, argv, "d:r:zs:h")) != -1) {
        switch (opt) {
        case 'd':
            dest_folder = optarg;
            break;
        case 'r':
            rules_file = optarg;
            break;
        case 't':
            printf("option t with value '%s'\n", optarg);
            break;
        case 's':
            sorting_option = static_cast<SortOption>(atoi(optarg));
            break;
        case 'z':
            dest_folder = "build-zrh/";
            rules_file = "../../../Documents/amadeus-share/zrh_rules.csv";
            break;
        case 'h':
        default: /* '?' */
            std::cerr << "Usage: " << argv[0] << "\n"
                      << "\t-d  destination folder\n"
                      << "\t-r  rules file\n"
                      << "\t-s  sorting: 0=none 1=asc 2=desc 3=mct_asc 4=mct_perf\n"
                      << "\t-z  [ZRH workload]\n"
                      << "\t-h  help\n";
            exit(EXIT_FAILURE);
        }
    }
    
    if (dest_folder.back() != '/')
        dest_folder = dest_folder + "/";
    if (!std::filesystem::exists(dest_folder))
        std::filesystem::create_directory(dest_folder);

    std::cout << "-d destination folder: " << dest_folder << std::endl;
    std::cout << "-r rules file: " << rules_file << std::endl;
    printf("-s sorting: [%c]none [%c]asc [%c]desc [%c]mct_asc [%c]mct_perf\n",
            (sorting_option==SortOption::None)       ? 'x' : ' ',
            (sorting_option==SortOption::Ascending)  ? 'x' : ' ',
            (sorting_option==SortOption::Descending) ? 'x' : ' ',
            (sorting_option==SortOption::MCT_DESC)   ? 'x' : ' ',
            (sorting_option==SortOption::MCT_PERF)   ? 'x' : ' ');
    

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // LOAD                                                                                       //
    ////////////////////////////////////////////////////////////////////////////////////////////////

    std::cout << "# LOAD" << std::endl;
    auto start = std::chrono::high_resolution_clock::now();
    
    nfa_bre::rulePack_s rp;
    rp.load_ruleType("../../../Documents/amadeus-share/ruleTypeDefinition_MINCT_1-0_Template1.xml");
    rp.load_rules(rules_file);

    auto finish = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> elapsed = finish - start;
    std::cout << rp.m_rules.size() << " rules loaded" << std::endl;
    std::cout << "# LOAD COMPLETED in " << elapsed.count() << " s\n";

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // DICTIONNARY                                                                                //
    ////////////////////////////////////////////////////////////////////////////////////////////////
    
    std::cout << "# DICTIONNARY" << std::endl;
    start = std::chrono::high_resolution_clock::now();
    
    nfa_bre::Dictionnary the_dictionnary(rp);

    switch (sorting_option) // todo enum
    {
        case SortOption::Ascending:
            std::cout << "Ascending sort" << std::endl;
            the_dictionnary.sort_by_n_of_values(nfa_bre::SortOrder::Ascending);
            break;

        case SortOption::Descending:
            std::cout << "Descending sort" << std::endl;
            the_dictionnary.sort_by_n_of_values(nfa_bre::SortOrder::Descending);
            break;

        case SortOption::MCT_DESC:
        {
            std::cout << "Arbitrary order MCT_DESC" << std::endl;
            nfa_bre::sorting_map_t sorting_map(22);
            sorting_map[ 0] = rp.m_ruleType.get_criterion_id("MCT_OFF");
            sorting_map[ 1] = rp.m_ruleType.get_criterion_id("MCT_BRD");
            sorting_map[ 2] = rp.m_ruleType.get_criterion_id("IN_FLT_NB");
            sorting_map[ 3] = rp.m_ruleType.get_criterion_id("OUT_FLT_NB");
            sorting_map[ 4] = rp.m_ruleType.get_criterion_id("IN_FLT_RG");
            sorting_map[ 5] = rp.m_ruleType.get_criterion_id("OUT_FLT_RG");
            sorting_map[ 6] = rp.m_ruleType.get_criterion_id("NXT_APT");
            sorting_map[ 7] = rp.m_ruleType.get_criterion_id("PRV_APT");
            sorting_map[ 8] = rp.m_ruleType.get_criterion_id("MCT_PRD");
            sorting_map[ 9] = rp.m_ruleType.get_criterion_id("IN_CRR");
            sorting_map[10] = rp.m_ruleType.get_criterion_id("OUT_CRR");
            sorting_map[11] = rp.m_ruleType.get_criterion_id("PRV_CTRY");
            sorting_map[12] = rp.m_ruleType.get_criterion_id("NXT_CTRY");
            sorting_map[13] = rp.m_ruleType.get_criterion_id("IN_EQP");
            sorting_map[14] = rp.m_ruleType.get_criterion_id("IN_TER");
            sorting_map[15] = rp.m_ruleType.get_criterion_id("OUT_TER");
            sorting_map[16] = rp.m_ruleType.get_criterion_id("OUT_EQP");
            sorting_map[17] = rp.m_ruleType.get_criterion_id("NXT_STATE");
            sorting_map[18] = rp.m_ruleType.get_criterion_id("PRV_STATE");
            sorting_map[19] = rp.m_ruleType.get_criterion_id("CTN_TYPE");
            sorting_map[20] = rp.m_ruleType.get_criterion_id("NXT_AREA");
            sorting_map[21] = rp.m_ruleType.get_criterion_id("PRV_AREA");
            the_dictionnary.m_sorting_map = sorting_map;
        }
            break;

        case SortOption::MCT_PERF:
        {
            std::cout << "Arbitrary order MCT_PERF" << std::endl;
            std::vector<int16_t> arbitrary; // key=position; value=criteria_id
            for (auto& aux __attribute__((unused)) : rp.m_ruleType.m_criterionDefinition)
                 arbitrary.push_back(-1);
            arbitrary[0] = rp.m_ruleType.get_criterion_id("MCT_OFF");
            arbitrary[1] = rp.m_ruleType.get_criterion_id("MCT_BRD");
            arbitrary[arbitrary.size()-3] = rp.m_ruleType.get_criterion_id("MCT_PRD");
            arbitrary[arbitrary.size()-2] = rp.m_ruleType.get_criterion_id("OUT_FLT_RG");
            arbitrary[arbitrary.size()-1] = rp.m_ruleType.get_criterion_id("IN_FLT_RG");
            the_dictionnary.sort_by_n_of_values(nfa_bre::SortOrder::Descending, &arbitrary);
        }
            break;

        case SortOption::None:
        default:
            break;
    }

    finish = std::chrono::high_resolution_clock::now();

    the_dictionnary.dump_dictionnary(dest_folder + "dictionnary.csv");

    // uint key = 0;
    // for (auto& aux : the_dictionnary.m_sorting_map)
    // {
    //     std::cout << "[" << key++ << "] ";
    //     std::cout << std::next(rp.m_ruleType.m_criterionDefinition.begin(), aux)->m_code;
    //     std::cout <<  " #" << the_dictionnary.m_dic_criteria[aux].size() << std::endl;
    // }

    elapsed = finish - start;
    std::cout << "# DICTIONNARY COMPLETED in " << elapsed.count() << " s\n";

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // NFA                                                                                        //
    ////////////////////////////////////////////////////////////////////////////////////////////////

    std::cout << "# NFA" << std::endl;
    start = std::chrono::high_resolution_clock::now();
    
    nfa_bre::NFAHandler the_nfa(rp, &the_dictionnary);

    finish = std::chrono::high_resolution_clock::now();
    elapsed = finish - start;
    
    #ifdef _DEBUG
    for (auto& level : the_nfa.m_vertexes)
    {
        aux=0;
        for (auto& value : level.second)
            aux += value.second.size();
        std::cout << "level " << level.first << " has " << aux << " states" << std::endl;
    }
    #endif

    // Stats
    std::cout << "initial number of states: " << boost::num_vertices(the_nfa.m_graph) << std::endl;
    //std::cout << "initial number of transitions: " << boost::num_edges(the_nfa.m_graph) << std::endl;
    std::cout << "# NFA COMPLETED in " << elapsed.count() << " s\n";
    
    ////////////////////////////////////////////////////////////////////////////////////////////////
    // OPTIMISATIONS                                                                              //
    ////////////////////////////////////////////////////////////////////////////////////////////////

    std::cout << "# OPTIMISATIONS" << std::endl;
    start = std::chrono::high_resolution_clock::now();

    uint n_merged_nodes = the_nfa.optimise();
    
    finish = std::chrono::high_resolution_clock::now();
    elapsed = finish - start;
    std::cout << "# OPTIMISATIONS COMPLETED in " << elapsed.count() << " s\n";

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // DELETION                                                                                   //
    ////////////////////////////////////////////////////////////////////////////////////////////////

    std::cout << "# DELETION" << std::endl;
    std::cout << "deleting " << n_merged_nodes << " states" << std::endl;
    start = std::chrono::high_resolution_clock::now();

    the_nfa.deletion();

    finish = std::chrono::high_resolution_clock::now();
    elapsed = finish - start;
    std::cout << "# DELETING COMPLETED in " << elapsed.count() << " s\n";

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // FINAL STATS                                                                                //
    ////////////////////////////////////////////////////////////////////////////////////////////////

    std::cout << "# FINAL STATS" << std::endl;
    uint n_bram_edges_max = the_nfa.print_stats();

    std::cout << "total number of states: " << boost::num_vertices(the_nfa.m_graph) << std::endl;
    std::cout << "total number of transitions: " << boost::num_edges(the_nfa.m_graph) << std::endl;

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // EXPORT CORE PARAMETERS                                                                     //
    ////////////////////////////////////////////////////////////////////////////////////////////////

    std::cout << "# EXPORT CORE PARAMETERS" << std::endl;
    the_nfa.dump_core_parameters(dest_folder + "core_param.txt", rp);

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // DROOLS                                                                                     //
    ////////////////////////////////////////////////////////////////////////////////////////////////

    std::cout << "# DROOLS" << std::endl;
    the_nfa.dump_drools_rules(dest_folder, rp);

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // EXPORT DOT FILE                                                                            //
    ////////////////////////////////////////////////////////////////////////////////////////////////

    std::cout << "# EXPORT DOT FILE" << std::endl;
    the_nfa.export_dot_file(dest_folder + "automaton.dot");

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // MEMORY DUMP                                                                                //
    ////////////////////////////////////////////////////////////////////////////////////////////////

    std::cout << "# MEMORY DUMP" << std::endl;

    // const uint CFG_ENGINE_NCRITERIA       = rp.m_ruleType.m_criterionDefinition.size();
    // const uint CFG_EDGE_BUFFERS_DEPTH     = 5;
    // const uint CFG_EDGE_BRAM_DEPTH        = (1 << (nfa_bre::CFG_MEM_ADDR_WIDTH + 1)) - 1;
    // const uint BRAM_USED_BITS             = nfa_bre::CFG_WEIGHT_WIDTH + nfa_bre::CFG_MEM_ADDR_WIDTH + 2*nfa_bre::CFG_ENGINE_CRITERION_WIDTH + 1;
    // const uint CFG_EDGE_BRAM_WIDTH        = 1 << ((uint)ceil(log2(BRAM_USED_BITS)));

    // std::cout << "constant CFG_ENGINE_NCRITERIA         : integer := " << CFG_ENGINE_NCRITERIA << "; -- Number of criteria\n";
    // std::cout << "constant CFG_ENGINE_CRITERION_WIDTH   : integer := " << nfa_bre::CFG_ENGINE_CRITERION_WIDTH << "; -- Number of bits of each criterion value\n";
    // std::cout << "constant CFG_WEIGHT_WIDTH             : integer := " << nfa_bre::CFG_WEIGHT_WIDTH << "; -- integer from 0 to 2^CFG_WEIGHT_WIDTH-1\n";
    // std::cout << "--\n";
    // std::cout << "constant CFG_MEM_ADDR_WIDTH           : integer := " << nfa_bre::CFG_MEM_ADDR_WIDTH << ";\n";
    // std::cout << "--\n";
    // std::cout << "constant CFG_EDGE_BUFFERS_DEPTH       : integer := " << CFG_EDGE_BUFFERS_DEPTH << ";\n";
    // std::cout << "constant CFG_EDGE_BRAM_DEPTH          : integer := " << CFG_EDGE_BRAM_DEPTH << ";\n";
    // std::cout << "constant CFG_EDGE_BRAM_WIDTH          : integer := " << CFG_EDGE_BRAM_WIDTH << ";\n";
    // std::cout << "BRAM_USED_BITS                        : integer := " << BRAM_USED_BITS << ";\n";

    if (ceil(log2(n_bram_edges_max)) > nfa_bre::CFG_MEM_ADDR_WIDTH)
    {
        std::cout << "[!] Required address space for " << n_bram_edges_max << " is ";
        std::cout << ceil(log2(n_bram_edges_max)) << " bits (CFG_MEM_ADDR_WIDTH = ";
        std::cout << nfa_bre::CFG_MEM_ADDR_WIDTH << " bits;\n";
    }

    start = std::chrono::high_resolution_clock::now();

    the_nfa.memory_dump(dest_folder + "mem_edges.bin", rp);

    finish = std::chrono::high_resolution_clock::now();

    elapsed = finish - start;
    std::cout << "# MEMORY DUMP COMPLETED in " << elapsed.count() << " s\n";

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // WORKLOAD DUMP                                                                              //
    ////////////////////////////////////////////////////////////////////////////////////////////////
    std::cout << "# WORKLOAD DUMP" << std::endl;
    start = std::chrono::high_resolution_clock::now();

    the_nfa.dump_mirror_workload(dest_folder + "workload", rp);

    finish = std::chrono::high_resolution_clock::now();
    elapsed = finish - start;
    std::cout << "# WORKLOAD DUMP COMPLETED in " << elapsed.count() << " s\n";
    
    ////////////////////////////////////////////////////////////////////////////////////////////////
    //                                                                                            //
    ////////////////////////////////////////////////////////////////////////////////////////////////

    return (1 ? EXIT_SUCCESS : EXIT_FAILURE);
}