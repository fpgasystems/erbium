#include <boost/graph/adjacency_list.hpp>
#include <string>
#include <exception>
#include <iostream>
#include <fstream>
#include <chrono>
#include <math.h>

#include "definitions.h"
#include "dictionnary.h"
#include "nfa_handler.h"

//#define _DEBUG true

class CSVRow
{
public:
    std::string const& operator[](std::size_t index) const
    {
        return m_data[index];
    }
    std::size_t size() const
    {
        return m_data.size();
    }
    std::string get_value(std::size_t index)
    {
        // REMOVE " "
        return m_data[index].substr(1, m_data[index].size()-2);
    }
    void readNextRow(std::istream& str)
    {
        std::string         line;
        std::getline(str, line);

        std::stringstream   lineStream(line);
        std::string         cell;

        m_data.clear();
        while(std::getline(lineStream, cell, ','))
        {
            m_data.push_back(cell);
        }
        // This checks for a trailing comma with no data after it.
        if (!lineStream && cell.empty())
        {
            // If there was a trailing comma then add an empty element.
            m_data.push_back("");
        }
    }
    std::vector<std::string>    m_data;
};
std::istream& operator>>(std::istream& str, CSVRow& data)
{
    data.readNextRow(str);
    return str;
}

std::string toBinary(uint padding, uint n)
{
    std::string r;
    while(n!=0) {
        r = (n%2==0 ? "0":"1") + r;
        n/=2;
    }
    padding = padding - r.length();
    while(padding != 0)
    {
        r = "0" + r;
        padding--;
    }
    return r;
}

int main()
{
    std::ifstream       file("../../../Documents/amadeus-share/mct_rules.csv");
    //std::ifstream       file("../data/demo_02.csv");
    //std::ifstream       file("../data/demo_01.csv");

    ////////////////////////////////////////////////////////////////////////////////////////
    std::cout << "# LOAD" << std::endl;
    auto start = std::chrono::high_resolution_clock::now();
    CSVRow              row;
    row.readNextRow(file);

    nfa_bre::rulePack_s rp;
    rp.load("../../../Documents/amadeus-share/ruleTypeDefinition_MINCT_1-0_Template1.xml");

    int aux = row.m_data.size()-4;
    while(file >> row)
    {
        // NOT PRODUCTION
        // JUST TO FILTER WHILE IN DEV
        //if (row.m_data[8] != "\"ZRH\"" && row.m_data[9] != "\"ZRH\"")
        //    continue;
        //if (row.m_data[8] != "\"CDG\"" && row.m_data[9] != "\"CDG\"")
        //    continue;
        //if (row.m_data[8] != "\"GRU\"" && row.m_data[9] != "\"GRU\"")
        //    continue;
        if (row.m_data[8] != "\"ZRH\"" && row.m_data[9] != "\"ZRH\"" && row.m_data[8] != "\"CDG\"" && row.m_data[9] != "\"CDG\"" && row.m_data[8] != "\"GRU\"" && row.m_data[9] != "\"GRU\"")
            continue;
        //if (row.m_data[aux+3] != "\"35\"")
        //    continue;
        //if (row.m_data[8] != "\"FIR\"" && row.m_data[9] != "\"FIR\"" && row.m_data[8] != "\"IBT\"" && row.m_data[9] != "\"IBT\"")
        //    continue;

        nfa_bre::rule_s rl;
        rl.m_ruleId = std::stoi(row.m_data[0].substr(1));
        rl.m_weight = std::stoi(row.m_data[1]);
        for (int i=6; i<aux; i++)
        {
            if (!row.m_data[i].empty())
            {
                nfa_bre::criterion_s ct;
                ct.m_index = i-6;
                ct.m_value = row.get_value(i);
                rl.m_criteria.insert(ct);
            }
            else
            {
                // IF NO VALUE, USE "*"
                nfa_bre::criterion_s ct;
                ct.m_index = i-6;
                ct.m_value = "*";
                rl.m_criteria.insert(ct);
            }
        }
        if (row.m_data[aux+2] == "\"TRUE\"")
            rl.m_content = "999";
        else
            rl.m_content = std::to_string(std::stoi(row.get_value(aux+1))*60 + 
                                          std::stoi(row.get_value(aux+3)));

        rp.m_rules.insert(rl);
    }

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

    // // arbitrary criteria order
    // std::vector<int> arbitrary;
    // for (auto& aux : rp.m_ruleType.m_criterionDefinition)
    //     arbitrary.push_back(-1);
    // arbitrary[0] = rp.m_ruleType.get_criterion_id("MCT_OFF");
    // arbitrary[1] = rp.m_ruleType.get_criterion_id("MCT_BRD");
    // arbitrary[arbitrary.size()-3] = rp.m_ruleType.get_criteriON_id("MCT_PRD");
    // arbitrary[arbitrary.size()-2] = rp.m_ruleType.get_criteriON_id("OUT_FLT_RG");
    // arbitrary[arbitrary.size()-1] = rp.m_ruleType.get_criteriON_id("IN_FLT_RG");
    // the_dictionnary.sort_by_n_of_values(nfa_bre::SortOrder::Descending, &arbitrary);

    the_dictionnary.sort_by_n_of_values(nfa_bre::SortOrder::Descending);
    
    finish = std::chrono::high_resolution_clock::now();

    uint key = 0;
    for (auto& aux : the_dictionnary.m_sorting_map)
    {
        std::cout << "[" << key++ << "] ";
        std::cout << std::next(rp.m_ruleType.m_criterionDefinition.begin(), aux)->m_code;
        std::cout <<  " #" << the_dictionnary.m_dic_criteria[aux].size() << std::endl;
    }

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
    std::cout << "total number of states: " << boost::num_vertices(the_nfa.m_graph) << std::endl;
    std::cout << "total number of transitions: " << boost::num_edges(the_nfa.m_graph) << std::endl;
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
    // EXPORT DOT FILE                                                                            //
    ////////////////////////////////////////////////////////////////////////////////////////////////

    std::cout << "# EXPORT DOT FILE" << std::endl;
    the_nfa.export_dot_file("automaton.dot");

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // MEMORY DUMP                                                                                //
    ////////////////////////////////////////////////////////////////////////////////////////////////

    std::cout << "# MEMORY DUMP" << std::endl;

    const uint CFG_ENGINE_NCRITERIA       = rp.m_ruleType.m_criterionDefinition.size();
    const uint CFG_ENGINE_CRITERION_WIDTH = 12;
    const uint CFG_WEIGHT_WIDTH           = 19;
    const uint CFG_MEM_ADDR_WIDTH         = ceil(log2(n_bram_edges_max));
    const uint CFG_EDGE_BUFFERS_DEPTH     = 5;
    const uint CFG_EDGE_BRAM_DEPTH        = n_bram_edges_max;
    const uint BRAM_USED_BITS             = CFG_WEIGHT_WIDTH + CFG_MEM_ADDR_WIDTH + CFG_ENGINE_CRITERION_WIDTH + CFG_ENGINE_CRITERION_WIDTH + 1;
    const uint CFG_EDGE_BRAM_WIDTH        = 1 << ((uint)ceil(log2(BRAM_USED_BITS)));    
    
    std::cout << "constant CFG_ENGINE_NCRITERIA         : integer := " << CFG_ENGINE_NCRITERIA << "; -- Number of criteria\n";
    std::cout << "constant CFG_ENGINE_CRITERION_WIDTH   : integer := " << CFG_ENGINE_CRITERION_WIDTH << "; -- Number of bits of each criterion value\n";
    std::cout << "constant CFG_WEIGHT_WIDTH             : integer := " << CFG_WEIGHT_WIDTH << "; -- integer from 0 to 2^CFG_WEIGHT_WIDTH-1\n";
    std::cout << "--\n";
    std::cout << "constant CFG_MEM_ADDR_WIDTH           : integer := " << CFG_MEM_ADDR_WIDTH << ";\n";
    std::cout << "--\n";
    std::cout << "constant CFG_EDGE_BUFFERS_DEPTH       : integer := " << CFG_EDGE_BUFFERS_DEPTH << ";\n";
    std::cout << "constant CFG_EDGE_BRAM_DEPTH          : integer := " << CFG_EDGE_BRAM_DEPTH << ";\n";
    std::cout << "constant CFG_EDGE_BRAM_WIDTH          : integer := " << CFG_EDGE_BRAM_WIDTH << ";\n";

    start = std::chrono::high_resolution_clock::now();

    the_nfa.memory_dump("mem_edges.bin");

    finish = std::chrono::high_resolution_clock::now();

    elapsed = finish - start;
    std::cout << "# MEMORY DUMP COMPLETED in " << elapsed.count() << " s\n";

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // WORKLOAD DUMP                                                                              //
    ////////////////////////////////////////////////////////////////////////////////////////////////
    std::cout << "# WORKLOAD DUMP" << std::endl;
    start = std::chrono::high_resolution_clock::now();

    the_nfa.dump_mirror_workload("workload.bin", rp);

    finish = std::chrono::high_resolution_clock::now();
    elapsed = finish - start;
    std::cout << "# WORKLOAD DUMP COMPLETED in " << elapsed.count() << " s\n";
    ////////////////////////////////////////////////////////////////////////////////////////////////
    //                                                                                            //
    ////////////////////////////////////////////////////////////////////////////////////////////////

    return 0;
}