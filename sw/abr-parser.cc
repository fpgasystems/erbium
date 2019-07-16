#include <boost/graph/adjacency_list.hpp>
#include <boost/property_tree/ptree.hpp>
#include <boost/property_tree/xml_parser.hpp>
#include <boost/foreach.hpp>
#include <string>
#include <set>
#include <map>
#include <exception>
#include <iostream>
#include <fstream>
#include <chrono>
#include <math.h>

#include "definitions.h"
#include "dictionnary.h"
#include "nfa_handler.h"

//#define _DEBUG true

void write_longlongint(std::ofstream* outfile, unsigned long long int value)
{
    uintptr_t addr = (uintptr_t)&value;
    for (short i = sizeof(value)-1; i >= 0; i--)
        outfile->write((char*)(addr + i), 1);
}

void nfa_bre::abr_dataset_s::load(const std::string &filename)
{
    // Create empty property tree object
    boost::property_tree::ptree tree;

    // Parse the XML into the property tree.
    boost::property_tree::read_xml(filename, tree);

    m_organization = tree.get<std::string>("ABR.<xmlattr>.organization");
    m_application = tree.get<std::string>("ABR.<xmlattr>.application");

    BOOST_FOREACH(boost::property_tree::ptree::value_type &aux, tree.get_child("ABR.RUL"))
    {
        //printf("[%s]\n", aux.first.c_str());

        // RULE PACK
        rulePack_s aux_rulePack;

        if (!strcmp(aux.first.c_str(), "rules"))
        {
            BOOST_FOREACH(boost::property_tree::ptree::value_type &aux_a, aux.second.get_child(""))
            {
                //printf("\t[%s]\n", aux_a.first.c_str());

                if (!strcmp(aux_a.first.c_str(), "RTD"))
                {
                    // RULE TYPE
                    ruleType_s aux_ruleType;
                    aux_ruleType.m_organization = aux_a.second.get<std::string>("<xmlattr>.organization");
                    aux_ruleType.m_code = aux_a.second.get<std::string>("<xmlattr>.ruleTypeCode");
                    aux_ruleType.m_release = aux_a.second.get<int>("<xmlattr>.release");
                    BOOST_FOREACH(boost::property_tree::ptree::value_type &aux_b, aux_a.second.get_child(""))
                    {
                        //printf("\t\t[%s]\n", aux_b.first.c_str());
                        if (!strcmp(aux_b.first.c_str(), "criterionDefinition"))
                        {
                            criterionDefinition_s aux_criterionDef;
                            aux_criterionDef.m_index = aux_b.second.get<int>("<xmlattr>.index");
                            aux_criterionDef.m_code = aux_b.second.get<std::string>("<xmlattr>.code");
                            aux_criterionDef.m_isMandatory = aux_b.second.get("<xmlattr>.isMandatory",false);
                            aux_criterionDef.m_supertag = aux_b.second.get<std::string>("criterionType.<xmlattr>.supertag");
                            aux_criterionDef.m_weight = aux_b.second.get<int>("criterionWeight.<xmlattr>.weight");
                            aux_ruleType.m_criterionDefinition.push_back(aux_criterionDef);
                        }
                        //printf("[%s] %s\n", aux_b.first.c_str(), aux_b.second.data().c_str());
                        //boost::property_tree::ptree::value_type &aux_c = aux_b.second.get_child("<xmlattr>");
                    }
                    aux_rulePack.m_ruleType = aux_ruleType;
                }
                else if (!strcmp(aux_a.first.c_str(), "rule"))
                {
                    // RULE
                    rule_s aux_rule;
                    aux_rule.m_ruleId = aux_a.second.get<int>("<xmlattr>.ruleId");
                    aux_rule.m_weight = aux_a.second.get<int>("weight");
                    aux_rule.m_content = aux_a.second.get<std::string>("content");
                    BOOST_FOREACH(boost::property_tree::ptree::value_type &aux_b, aux_a.second.get_child("criteria"))
                    {
                        //printf("[%s]\n", aux_b.first.c_str());

                        criterion_s aux_criterion;
                        aux_criterion.m_index = aux_b.second.get<int>("<xmlattr>.index");
                        aux_criterion.m_code = aux_b.second.get<std::string>("<xmlattr>.code");
                        aux_criterion.m_value = aux_b.second.get<std::string>("value");
                        aux_rule.m_criteria.insert(aux_criterion);
                    }
                    
                    aux_rulePack.m_rules.insert(aux_rule);
                }
            }
            m_rulePacks.insert(aux_rulePack);
        }
    }
}

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
    //std::ifstream       file("../../../Documents/amadeus-share/mct_rules.csv");
    //std::ifstream       file("../data/demo_02.csv");
    std::ifstream       file("../data/demo_01.csv");

    ////////////////////////////////////////////////////////////////////////////////////////
    std::cout << "# LOAD" << std::endl;
    auto start = std::chrono::high_resolution_clock::now();
    CSVRow              row;
    row.readNextRow(file);
    nfa_bre::abr_dataset_s ds;
    nfa_bre::rulePack_s rp;
    ds.m_organization = "Amadeus";
    ds.m_application = "MCT";

    rp.m_ruleType.m_organization = "Amadeus";
    rp.m_ruleType.m_code = "MINCT";
    rp.m_ruleType.m_release = 0;

    for (uint i=6; i<row.m_data.size()-4; i++)
    {
        nfa_bre::criterionDefinition_s cd;
        cd.m_index = i-6;
        cd.m_code = row.m_data[i];
        cd.m_isMandatory = false;
        cd.m_supertag = "";
        cd.m_weight = 0;
        rp.m_ruleType.m_criterionDefinition.push_back(cd);
    }

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
        //if (row.m_data[8] != "\"ZRH\"" && row.m_data[9] != "\"ZRH\"" && row.m_data[8] != "\"CDG\"" && row.m_data[9] != "\"CDG\"" && row.m_data[8] != "\"GRU\"" && row.m_data[9] != "\"GRU\"")
        //    continue;
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
                ct.m_code = rp.m_ruleType.m_criterionDefinition[i-6].m_code;
                ct.m_value = row.get_value(i);
                rl.m_criteria.insert(ct);
            }
            else
            {
                // IF NO VALUE, USE "*"
                nfa_bre::criterion_s ct;
                ct.m_index = i-6;
                ct.m_code = rp.m_ruleType.m_criterionDefinition[i-6].m_code;
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
    //rp.m_ruleType.print("");
    //ds.m_rulePacks.insert(rp);

    auto finish = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> elapsed = finish - start;
    std::cout << rp.m_rules.size() << " rules loaded" << std::endl;
    std::cout << "# LOAD COMPLETED in " << elapsed.count() << " s\n";

////////////////////////////////////////////////////////////////////////////////////////////////////
// DICTIONNARY                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////
    
    std::cout << "# DICTIONNARY" << std::endl;
    start = std::chrono::high_resolution_clock::now();
    
    nfa_bre::Dictionnary the_dictionnary(rp);

    // arbitrary criteria order
    std::vector<int> arbitrary;
    for (auto& aux : rp.m_ruleType.m_criterionDefinition)
        arbitrary.push_back(-1);
    arbitrary[0] = rp.m_ruleType.get_criterium_id("MCT_OFF");
    arbitrary[1] = rp.m_ruleType.get_criterium_id("MCT_BRD");
    arbitrary[arbitrary.size()-3] = rp.m_ruleType.get_criterium_id("IN_FLT_RG");
    arbitrary[arbitrary.size()-2] = rp.m_ruleType.get_criterium_id("OUT_FLT_RG");
    arbitrary[arbitrary.size()-1] = rp.m_ruleType.get_criterium_id("MCT_PRD");

    the_dictionnary.sort_by_n_of_values(nfa_bre::SortOrder::Descending, &arbitrary);
    
    finish = std::chrono::high_resolution_clock::now();

    uint key = 0;
    for (auto& aux : the_dictionnary.m_sorting_map)
    {
        std::cout << "[" << key++ << "] " << rp.m_ruleType.m_criterionDefinition[aux].m_code;
        std::cout <<  " #" << the_dictionnary.m_dic_criteria[aux].size() << std::endl;
    }

    elapsed = finish - start;
    std::cout << "# DICTIONNARY COMPLETED in " << elapsed.count() << " s\n";

////////////////////////////////////////////////////////////////////////////////////////////////////
// NFA                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////

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
        std::cout << "level " << level.first << " has " << aux << " nodes" << std::endl;
    }
    #endif

    // Stats
    std::cout << "total number of nodes: " << boost::num_vertices(the_nfa.m_graph) << std::endl;
    std::cout << "total number of transitions: " << boost::num_edges(the_nfa.m_graph) << std::endl;
    std::cout << "# GRAPH COMPLETED in " << elapsed.count() << " s\n";

////////////////////////////////////////////////////////////////////////////////////////////////////
// OPTIMISATIONS                                                                                  //
////////////////////////////////////////////////////////////////////////////////////////////////////

    std::cout << "# OPTIMISATIONS" << std::endl;
    start = std::chrono::high_resolution_clock::now();

    uint n_merged_nodes = the_nfa.optimise();
    
    finish = std::chrono::high_resolution_clock::now();
    elapsed = finish - start;
    std::cout << "# OPTIMISATIONS COMPLETED in " << elapsed.count() << " s\n";

////////////////////////////////////////////////////////////////////////////////////////////////////
// DELETION                                                                                       //
////////////////////////////////////////////////////////////////////////////////////////////////////

    std::cout << "# DELETION" << std::endl;
    std::cout << "deleting " << n_merged_nodes << " nodes" << std::endl;
    start = std::chrono::high_resolution_clock::now();

    the_nfa.deletion();

    finish = std::chrono::high_resolution_clock::now();
    elapsed = finish - start;
    std::cout << "# DELETING COMPLETED in " << elapsed.count() << " s\n";

////////////////////////////////////////////////////////////////////////////////////////////////////
// FINAL STATS                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////

    uint n_bram_edges_max = the_nfa.print_stats();

    std::cout << "total number of nodes: " << boost::num_vertices(the_nfa.m_graph) << std::endl;
    std::cout << "total number of transitions: " << boost::num_edges(the_nfa.m_graph) << std::endl;

////////////////////////////////////////////////////////////////////////////////////////////////////
// EXPORT FILE                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////

    the_nfa.export_dot_file("automaton.dot");

////////////////////////////////////////////////////////////////////////////////////////////////////
// MEMORY DUMP                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////


    std::cout << "# MEMORY DUMP" << std::endl;
    std::ofstream outfile("mem_edges.bin", std::ios::binary | std::ios::out | std::ios::trunc);

    const uint CFG_ENGINE_NCRITERIA       = rp.m_ruleType.m_criterionDefinition.size();
    const uint CFG_ENGINE_CRITERIUM_WIDTH = 12;
    const uint CFG_WEIGHT_WIDTH           = 19;
    const uint CFG_MEM_ADDR_WIDTH         = ceil(log2(n_bram_edges_max));
    const uint CFG_EDGE_BUFFERS_DEPTH     = 5;
    const uint CFG_EDGE_BRAM_DEPTH        = n_bram_edges_max;
    const uint BRAM_USED_BITS             = CFG_WEIGHT_WIDTH + CFG_MEM_ADDR_WIDTH + CFG_ENGINE_CRITERIUM_WIDTH + CFG_ENGINE_CRITERIUM_WIDTH + 1;
    const uint CFG_EDGE_BRAM_WIDTH        = 1 << ((uint)ceil(log2(BRAM_USED_BITS)));    
    
    std::cout << "constant CFG_ENGINE_NCRITERIA         : integer := " << CFG_ENGINE_NCRITERIA << "; -- Number of criteria\n";
    std::cout << "constant CFG_ENGINE_CRITERIUM_WIDTH   : integer := " << CFG_ENGINE_CRITERIUM_WIDTH << "; -- Number of bits of each criterium value\n";
    std::cout << "constant CFG_WEIGHT_WIDTH             : integer := " << CFG_WEIGHT_WIDTH << "; -- integer from 0 to 2^CFG_WEIGHT_WIDTH-1\n";
    std::cout << "--\n";
    std::cout << "constant CFG_MEM_ADDR_WIDTH           : integer := " << CFG_MEM_ADDR_WIDTH << ";\n";
    std::cout << "--\n";
    std::cout << "constant CFG_EDGE_BUFFERS_DEPTH       : integer := " << CFG_EDGE_BUFFERS_DEPTH << ";\n";
    std::cout << "constant CFG_EDGE_BRAM_DEPTH          : integer := " << CFG_EDGE_BRAM_DEPTH << ";\n";
    std::cout << "constant CFG_EDGE_BRAM_WIDTH          : integer := " << CFG_EDGE_BRAM_WIDTH << ";\n";

    start = std::chrono::high_resolution_clock::now();

    const unsigned long int MASK_WEIGHT     = 0x7FFFF;
    const unsigned long int MASK_POINTER    = 0x7FFF;
    const unsigned long int MASK_OPERAND_B  = 0xFFF;
    const unsigned long int MASK_OPERAND_A  = 0xFFF;
    const unsigned long int SHIFT_LAST      = CFG_WEIGHT_WIDTH+CFG_MEM_ADDR_WIDTH+2*CFG_ENGINE_CRITERIUM_WIDTH;
    const unsigned long int SHIFT_WEIGHT    = CFG_MEM_ADDR_WIDTH+2*CFG_ENGINE_CRITERIUM_WIDTH;
    const unsigned long int SHIFT_POINTER   = 2*CFG_ENGINE_CRITERIUM_WIDTH;
    const unsigned long int SHIFT_OPERAND_B = CFG_ENGINE_CRITERIUM_WIDTH;
    const unsigned long int SHIFT_OPERAND_A = 0;

    // POINTERS
    uint edges_per_level[the_nfa.m_vertexes.size()];
    uint n_edges;
    uint n_edges_max;
    for (auto level = the_nfa.m_vertexes.rbegin(); level != the_nfa.m_vertexes.rend(); ++level)
    {
        n_edges = 0;

        for (auto& value : the_nfa.m_vertexes[level->first])
        {
            for (auto& vert : the_nfa.m_vertexes[level->first][value.first])
            {
                if (the_nfa.m_graph[vert].parents.size() != 0)
                {

                    the_nfa.m_graph[vert].dump_pointer = n_edges;
                    n_edges_max = the_nfa.m_graph[vert].children.size();

                    if (n_edges_max == 0)
                        n_edges++;
                    else
                        n_edges += n_edges_max;
                }
            }
        }
        edges_per_level[level->first] = n_edges;
    }

    // before-last-criterium nodes point to the result directly
    for (auto& value : the_nfa.m_vertexes[the_nfa.m_vertexes.size()-2])
    {
        for (auto& vert : the_nfa.m_vertexes[the_nfa.m_vertexes.size()-2][value.first])
        {
            auto element = the_nfa.m_graph[vert];
            if (element.parents.size() != 0)
            {
                auto result = element.children.begin();
                element.dump_pointer = the_nfa.m_graph[*result].dump_pointer;
            }
        }
    }


    unsigned long long int mem_int;
    uint SLICES_PER_LINE = 512 / 64;
    // origin
    aux = 1;
    n_edges_max = the_nfa.m_graph[0].children.size();

    write_longlongint(&outfile, n_edges_max);

    for (auto& vert : the_nfa.m_graph[0].children)
    {
        mem_int = (aux++ == n_edges_max);
        mem_int = mem_int << SHIFT_LAST;
        mem_int |= ((unsigned long long int)256 & MASK_WEIGHT) << SHIFT_WEIGHT;
        mem_int |= ((unsigned long long int)the_nfa.m_graph[vert].dump_pointer & MASK_POINTER) << SHIFT_POINTER;
        mem_int |= ((unsigned long long int)the_dictionnary.get_criterium_dic(0)[the_nfa.m_graph[vert].label] & MASK_OPERAND_B) << SHIFT_OPERAND_B;
        mem_int |= ((unsigned long long int)the_dictionnary.get_criterium_dic(0)[the_nfa.m_graph[vert].label] & MASK_OPERAND_A) << SHIFT_OPERAND_A;
        write_longlongint(&outfile, mem_int);
    }
    // padding
    n_edges = (n_edges_max+1) % SLICES_PER_LINE;
    n_edges = (n_edges == 0) ? 0 : SLICES_PER_LINE - n_edges;
    for (uint pad = n_edges; pad != 0; pad--)
        write_longlongint(&outfile, 0);
    std::cout << "level=0 edges=" << n_edges_max << " padding=" << n_edges << std::endl;


    uint the_order = 1;
    std::map<std::string, uint> dic;
    for (auto level : the_nfa.m_vertexes)
    {
        if (level.second == the_nfa.m_vertexes[the_nfa.m_vertexes.size()-2])
            break;  // skip content

        dic = the_dictionnary.get_criterium_dic(the_order++);

        // number of edges
        mem_int = edges_per_level[level.first];
        write_longlongint(&outfile, mem_int);

        // write 
        for (auto& value : the_nfa.m_vertexes[level.first])
        {
            for (auto& vert : the_nfa.m_vertexes[level.first][value.first])
            {
                if (the_nfa.m_graph[vert].parents.size() != 0)
                {
                    aux=1;
                    n_edges_max = the_nfa.m_graph[vert].children.size();
                    for (auto& itr : the_nfa.m_graph[vert].children)
                    {
                        mem_int = (unsigned long long int)(aux++ == n_edges_max) << SHIFT_LAST;
                        mem_int |= ((unsigned long long int)256 & MASK_WEIGHT) << SHIFT_WEIGHT;
                        mem_int |= ((unsigned long long int)(the_nfa.m_graph[itr].dump_pointer) & MASK_POINTER) << SHIFT_POINTER;
                        mem_int |= ((unsigned long long int)(dic[the_nfa.m_graph[itr].label] & MASK_OPERAND_B)) << SHIFT_OPERAND_B;
                        mem_int |= ((unsigned long long int)(dic[the_nfa.m_graph[itr].label] & MASK_OPERAND_A)) << SHIFT_OPERAND_A;
                        write_longlongint(&outfile, mem_int);
                    }
                }
            }
        }
        // padding
        n_edges = (edges_per_level[level.first]+1) % SLICES_PER_LINE;
        n_edges = (n_edges == 0) ? 0 : SLICES_PER_LINE - n_edges;
        for (uint pad = n_edges; pad != 0; pad--)
            write_longlongint(&outfile, 0);

        std::cout << "level=" << level.first+1 << " edges=" << edges_per_level[level.first] << " padding=" << n_edges << std::endl;
    }

    outfile.close();

    finish = std::chrono::high_resolution_clock::now();

    elapsed = finish - start;
    std::cout << "# MEMORY DUMP COMPLETED in " << elapsed.count() << " s\n";

    ////////////////////////////////////////////////////////////////////////////////////////

    return 0;
}