#ifndef NFA_BRE_NFA_HANDLER_H
#define NFA_BRE_NFA_HANDLER_H

#include "definitions.h"
#include "dictionnary.h"

class NFAHandler {
  public:
    std::map<uint, std::map<uint, std::set<uint>>> m_vertexes; // per level > per value > nodes list
    graph_t m_graph(1);

    NFAHandler(const& rulePack_s, const& Dictionnary dic);


  private:
    void o();
}

#endif