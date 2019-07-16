#ifndef NFA_BRE_NFA_HANDLER_H
#define NFA_BRE_NFA_HANDLER_H

#include "definitions.h"
#include "dictionnary.h"

#include <string>

namespace nfa_bre {

class NFAHandler {
  public:
    std::map<uint, std::map<uint, std::set<uint>>> m_vertexes; // per level > per value > nodes list
    graph_t m_graph;

    NFAHandler(const rulePack_s, Dictionnary* dic);
    uint optimise();
    void deletion();
    uint print_stats(); // returns n_bram_edges_max
    void export_dot_file(const std::string filename);

  private:
    Dictionnary* m_dic;
};

} // namespace nfa_bre

#endif // NFA_BRE_NFA_HANDLER_H