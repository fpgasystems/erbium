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

#include <string>
#include <exception>
#include <iostream>     // std::cout
#include <iomanip>      // std::setw
#include <chrono>       // time
#include <math.h>
#include <unistd.h>

#include "definitions.h"
#include "rule_parser.h"
#include "dictionnary.h"
#include "graph_handler.h"

enum SortOption { None, H1_Ascending, H1_Descending, H2_Ascending, H2_Descending };
std::string SortOptionTag[] = {"hRand", "h1Asc", "h1Des", "h2Asc", "h2Des"};

int main(int argc, char** argv)
{
    ////////////////////////////////////////////////////////////////////////////////////////////////
    // PARAMETERS                                                                                 //
    ////////////////////////////////////////////////////////////////////////////////////////////////
    std::cout << "# PARAMETERS" << std::endl;

    SortOption sorting_option = H2_Descending;
    std::string dest_folder = "build/";
    std::string rules_file = "../data/mct_rules.csv";
    std::string ruletype_file = "../data/mct_ruleTypeDefinition_MCT_v1.xml";

    int opt;
    while ((opt = getopt(argc, argv, "d:r:s:t:h")) != -1) {
        switch (opt) {
        case 'd':
            dest_folder = optarg;
            break;
        case 'r':
            rules_file = optarg;
            break;
        case 't':
            ruletype_file = optarg;
            break;
        case 's':
            sorting_option = static_cast<SortOption>(atoi(optarg));
            break;
        case 'h':
        default: /* '?' */
            std::cerr << "Usage: " << argv[0] << "\n"
                      << "\t-d  destination folder\n"
                      << "\t-r  rules file\n"
                      << "\t-s  sorting: 0=None 1=H1_Asc 2=H1_Desc 4=H2_Asc 5=H2_Desc\n"
                      << "\t-t  ruletype file\n"
                      << "\t-h  help\n";
            exit(EXIT_FAILURE);
        }
    }
    
    if (dest_folder.back() != '/')
        dest_folder = dest_folder + "/";

    std::cout << "-d destination folder: " << dest_folder << std::endl;
    std::cout << "-r rules file: " << rules_file << std::endl;
    printf("-s sorting: [%c]none [%c]H1_Asc [%c]H1_Desc [%c]H2_Asc [%c]H2_Desc\n",
            (sorting_option==SortOption::None)          ? 'x' : ' ',
            (sorting_option==SortOption::H1_Ascending)  ? 'x' : ' ',
            (sorting_option==SortOption::H1_Descending) ? 'x' : ' ',
            (sorting_option==SortOption::H2_Ascending)  ? 'x' : ' ',
            (sorting_option==SortOption::H2_Descending) ? 'x' : ' ');
    std::cout << "-t ruletype file: " << ruletype_file << std::endl;

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // LOAD                                                                                       //
    ////////////////////////////////////////////////////////////////////////////////////////////////

    std::cout << "# LOAD" << std::endl;
    auto start = std::chrono::high_resolution_clock::now();
    
    erbium::rulePack_s the_rulePack;
    the_rulePack.load_ruleType(ruletype_file);
    the_rulePack.load_rules(rules_file);

    auto finish = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> elapsed = finish - start;
    std::cout << the_rulePack.m_rules.size() << " rules loaded" << std::endl;
    std::cout << "# LOAD COMPLETED in " << elapsed.count() << " s\n";

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // DICTIONNARY                                                                                //
    ////////////////////////////////////////////////////////////////////////////////////////////////
    
    std::cout << "# DICTIONNARY" << std::endl;
    start = std::chrono::high_resolution_clock::now();
    
    erbium::Dictionnary the_dictionnary(the_rulePack);

    switch (sorting_option)
    {
        case SortOption::H1_Ascending:
            std::cout << "H1_Ascending sort" << std::endl;
            the_dictionnary.sort_by_n_of_values(erbium::SortOrder::Ascending);
            break;

        case SortOption::H1_Descending:
            std::cout << "H1_Descending sort" << std::endl;
            the_dictionnary.sort_by_n_of_values(erbium::SortOrder::Descending);
            break;

        case SortOption::H2_Ascending:
        {
            std::cout << "Arbitrary order H2_Ascending" << std::endl;
            std::vector<int16_t> arbitrary; // key=position; value=criteria_id
            for (auto& aux __attribute__((unused)) : the_rulePack.m_ruleType.m_criterionDefinition)
                 arbitrary.push_back(-1);
            arbitrary[ 0] = the_rulePack.m_ruleType.get_criterion_id("MCT_OFF");
            arbitrary[ 1] = the_rulePack.m_ruleType.get_criterion_id("MCT_BRD");
            arbitrary[ 2] = the_rulePack.m_ruleType.get_criterion_id("CTN_TYPE");
            arbitrary[19] = the_rulePack.m_ruleType.get_criterion_id("MCT_PRD");
            arbitrary[20] = the_rulePack.m_ruleType.get_criterion_id("OUT_FLT_RG");
            arbitrary[21] = the_rulePack.m_ruleType.get_criterion_id("IN_FLT_RG");
            the_dictionnary.sort_by_n_of_values(erbium::SortOrder::Ascending, &arbitrary);
        }
            break;

        case SortOption::H2_Descending:
        {
            std::cout << "Arbitrary order H2_Descending" << std::endl;
            std::vector<int16_t> arbitrary; // key=position; value=criteria_id
            for (auto& aux __attribute__((unused)) : the_rulePack.m_ruleType.m_criterionDefinition)
                 arbitrary.push_back(-1);
            arbitrary[ 0] = the_rulePack.m_ruleType.get_criterion_id("MCT_OFF");
            arbitrary[ 1] = the_rulePack.m_ruleType.get_criterion_id("MCT_BRD");
            arbitrary[ 2] = the_rulePack.m_ruleType.get_criterion_id("CTN_TYPE");
            arbitrary[19] = the_rulePack.m_ruleType.get_criterion_id("MCT_PRD");
            arbitrary[20] = the_rulePack.m_ruleType.get_criterion_id("OUT_FLT_RG");
            arbitrary[21] = the_rulePack.m_ruleType.get_criterion_id("IN_FLT_RG");
            the_dictionnary.sort_by_n_of_values(erbium::SortOrder::Descending, &arbitrary);
        }
            break;

        case SortOption::None:
        default:
            break;
    }

    finish = std::chrono::high_resolution_clock::now();

    the_dictionnary.dump_dictionnary(dest_folder + "dictionnary.csv");

    elapsed = finish - start;
    std::cout << "# DICTIONNARY COMPLETED in " << elapsed.count() << " s\n";

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // SANDBOX
    ////////////////////////////////////////////////////////////////////////////////////////////////

    /*std::cout.fill(' ');
    std::cout << ". Experiments on " << rules_file << " (r=" << the_rulePack.m_rules.size() << "):" << std::endl;

    start = std::chrono::high_resolution_clock::now();
    erbium::GraphHandler ticaTRE(&the_rulePack, &the_dictionnary);
    ticaTRE.consolidate_graph();
    finish = std::chrono::high_resolution_clock::now();
    elapsed = finish - start;

    std::cout << ".. Tre: s= " << std::setw(9) << ticaTRE.get_num_states()
              << ", t= " << std::setw(9) << ticaTRE.get_num_transitions()
              << " (" << elapsed.count() << ")" << std::endl;

    erbium::GraphHandler ticaDFA(&the_rulePack, &the_dictionnary);
    start = std::chrono::high_resolution_clock::now();
    ticaDFA.make_deterministic();
    ticaDFA.consolidate_graph();
    finish = std::chrono::high_resolution_clock::now();
    elapsed = finish - start;

    std::cout << ".. DFA: s= " << std::setw(9) << ticaDFA.get_num_states()
              << ", t= " << std::setw(9) << ticaDFA.get_num_transitions()
              << " (" << elapsed.count() << ")" << std::endl;

    start = std::chrono::high_resolution_clock::now();
    ticaDFA.suffix_reduction();
    ticaDFA.consolidate_graph();
    finish = std::chrono::high_resolution_clock::now();
    elapsed = finish - start;

    std::cout << ".. DFA: s= " << std::setw(9) << ticaDFA.get_num_states()
              << ", t= " << std::setw(9) << ticaDFA.get_num_transitions()
              << " (" << elapsed.count() << ")" << std::endl;

    erbium::GraphHandler ticaNFA(&the_rulePack, &the_dictionnary);
    start = std::chrono::high_resolution_clock::now();
    ticaNFA.suffix_reduction();
    ticaNFA.consolidate_graph();
    finish = std::chrono::high_resolution_clock::now();
    elapsed = finish - start;

    std::cout << ".. NFA: s= " << std::setw(9) << ticaNFA.get_num_states()
              << ", t= " << std::setw(9) << ticaNFA.get_num_transitions()
              << " (" << elapsed.count() << ")" << std::endl;

    return 0;*/
    ////////////////////////////////////////////////////////////////////////////////////////////////
    // GRAPH                                                                                      //
    ////////////////////////////////////////////////////////////////////////////////////////////////

    std::cout << "# GRAPH" << std::endl;
    start = std::chrono::high_resolution_clock::now();
    
    erbium::GraphHandler the_tree(&the_rulePack, &the_dictionnary);
    the_tree.consolidate_graph();

    finish = std::chrono::high_resolution_clock::now();
    elapsed = finish - start;

    // Stats
    std::cout << "number of states: " << the_tree.get_num_states() << std::endl;
    std::cout << "number of transitions: " << the_tree.get_num_transitions() << std::endl;
    std::cout << "# GRAPH COMPLETED in " << elapsed.count() << " s\n";

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // DFA                                                                                        //
    ////////////////////////////////////////////////////////////////////////////////////////////////

    // std::cout << "# DFA" << std::endl;
    // 
    // erbium::GraphHandler the_dfa(&the_rulePack, &the_dictionnary);
    // start = std::chrono::high_resolution_clock::now();
    //
    // /*the_dfa.make_deterministic();
    // the_dfa.suffix_reduction();*/
    // the_dfa.consolidate_graph();
    //
    // finish = std::chrono::high_resolution_clock::now();
    // elapsed = finish - start;
    //
    // // Stats
    // std::cout << "number of states: " << the_dfa.get_num_states() << std::endl;
    // std::cout << "number of transitions: " << the_dfa.get_num_transitions() << std::endl;
    // std::cout << "# DFA COMPLETED in " << elapsed.count() << " s\n";

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // NFA                                                                                        //
    ////////////////////////////////////////////////////////////////////////////////////////////////

    std::cout << "# NFA" << std::endl;
    
    erbium::GraphHandler the_nfa(&the_rulePack, &the_dictionnary);
    start = std::chrono::high_resolution_clock::now();

    the_nfa.suffix_reduction();
    the_nfa.consolidate_graph();

    finish = std::chrono::high_resolution_clock::now();
    elapsed = finish - start;

    // Stats
    std::cout << "number of states: " << the_nfa.get_num_states() << std::endl;
    std::cout << "number of transitions: " << the_nfa.get_num_transitions() << std::endl;
    std::cout << "# NFA COMPLETED in " << elapsed.count() << " s\n";

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // FINAL STATS                                                                                //
    ////////////////////////////////////////////////////////////////////////////////////////////////

    std::cout << "# NFA FINAL STATS" << std::endl;
    the_nfa.print_stats();

    std::cout << "total number of states: " << the_nfa.get_num_states() << std::endl;
    std::cout << "total number of transitions: " << the_nfa.get_num_transitions() << std::endl;

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // EXPORT CORE PARAMETERS                                                                     //
    ////////////////////////////////////////////////////////////////////////////////////////////////

    std::cout << "# EXPORT CORE PARAMETERS" << std::endl;
    erbium::RuleParser::export_vhdl_parameters(
                dest_folder + "cfg_criteria_" + SortOptionTag[sorting_option] + ".vhd",
                the_rulePack,
                &the_dictionnary,
                the_nfa.get_transitions_per_level());

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // EXPORT GRAPHVIZ DOT FILE                                                                   //
    ////////////////////////////////////////////////////////////////////////////////////////////////
    
    std::cout << "# EXPORT GRAPHVIZ DOT FILE" << std::endl;

    the_tree.export_graphviz(dest_folder + "graphviz_tree.dot");
    //the_dfa.export_graphviz(dest_folder + "graphviz_dfa.dot");
    the_nfa.export_graphviz(dest_folder + "graphviz_nfa.dot");

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // MEMORY DUMP                                                                                //
    ////////////////////////////////////////////////////////////////////////////////////////////////

    std::cout << "# MEMORY DUMP" << std::endl;

    start = std::chrono::high_resolution_clock::now();

    //the_dfa.export_memory(dest_folder + "mem_dfa_edges.bin");
    the_nfa.export_memory(dest_folder + "mem_nfa_edges.bin");
    finish = std::chrono::high_resolution_clock::now();

    //std::cout << "DFA hash: " << the_dfa.get_graph_hash() << std::endl;
    std::cout << "NFA hash: " << the_nfa.get_graph_hash() << std::endl;

    elapsed = finish - start;
    std::cout << "# MEMORY DUMP COMPLETED in " << elapsed.count() << " s\n";

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // WORKLOAD DUMP                                                                              //
    ////////////////////////////////////////////////////////////////////////////////////////////////
    std::cout << "# WORKLOAD DUMP" << std::endl;
    start = std::chrono::high_resolution_clock::now();

    erbium::RuleParser::export_benchmark_workload(dest_folder, the_rulePack, &the_dictionnary);

    finish = std::chrono::high_resolution_clock::now();
    elapsed = finish - start;
    std::cout << "# WORKLOAD DUMP COMPLETED in " << elapsed.count() << " s\n";
    
    ////////////////////////////////////////////////////////////////////////////////////////////////
    //                                                                                            //
    ////////////////////////////////////////////////////////////////////////////////////////////////

    return (1 ? EXIT_SUCCESS : EXIT_FAILURE);
} // end of main