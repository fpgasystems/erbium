#ifndef ERBIUM_GRAPH_HANDLER_H
#define ERBIUM_GRAPH_HANDLER_H
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

#include "definitions.h"

#include <string>

namespace erbium {

class Dictionnary;

class GraphHandler {
  public:

    GraphHandler(const rulePack_s* rulepack, const Dictionnary* dic);

    // backward optimisation
    uint suffix_reduction();

    // build transitions and states, eliminating orphans
    void consolidate_graph();

    // fuses wildcard paths to non-wildcard paths
    void make_deterministic();

    // returns n_bram_edges_max
    uint print_stats();

    // a sort of graph ID
    uint64_t get_graph_hash();

    // number of states/vertices/nodes in the graph
    uint32_t get_num_states();

    // number of transitions/edges in the graph
    uint32_t get_num_transitions();

    // returns the number of edges per level of the graph
    std::vector<uint> get_transitions_per_level();

    // export dot file (for visualisation)
    void export_graphviz(const std::string& filename);

    // export binary data for erbium engine
    void export_memory(const std::string& filename);

  private:
    vertexes_t   m_vertexes; // per level > per value_id > nodes list
    graph_t      m_graph;    // graph and NFA
    //
    const rulePack_s*  m_rulePack;
    const Dictionnary* m_dic;

    // DFA-only
    void dfa_merge_paths(const vertex_id_t& orgi_state, const vertex_id_t& dest_state);
    void dfa_append_path(const vertex_id_t& orgi_state, const vertex_id_t& dest_state);

    void dump_binary_state(std::fstream* outfile,
                           const vertex_id_t& vertex_id,
                           dictionnary_t* dic,
                           const criterionDefinition_s* criterion_def);
    void dump_binary_padding(std::fstream* outfile, const size_t& slices);
};

} // namespace erbium

#endif // ERBIUM_GRAPH_HANDLER_H