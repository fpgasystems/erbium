#ifndef NFA_BRE_GRAPH_HANDLER_H
#define NFA_BRE_GRAPH_HANDLER_H

#include "definitions.h"

#include <string>

namespace nfa_bre {

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

    // export binary data for ederah engine
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

} // namespace nfa_bre

#endif // NFA_BRE_GRAPH_HANDLER_H