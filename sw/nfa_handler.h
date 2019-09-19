#ifndef NFA_BRE_NFA_HANDLER_H
#define NFA_BRE_NFA_HANDLER_H

#include "definitions.h"
#include "dictionnary.h"

#include <string>
#include <iterator>
#include <algorithm>
#include <fstream>
#include <cstdint>

namespace nfa_bre {

class NFAHandler {
  public:
    vertexes_t m_vertexes; // per level > per value_id > nodes list
    graph_t    m_graph;

    NFAHandler(const rulePack_s&, Dictionnary* dic);
    uint optimise();
    void deletion();
    uint print_stats(); // returns n_bram_edges_max
    void export_dot_file(const std::string& filename);
    void memory_dump(const std::string& filename, const rulePack_s& rulepack);
    void dump_core_parameters(const std::string& filename, const rulePack_s& rulepack);
    void dump_mirror_workload(const std::string& filename, const rulePack_s& rulepack);
    void dump_benchmark_workload(const std::string& filename, const rulePack_s& rulepack);

    void dump_drools_rules(const std::string& filename, const rulePack_s& rulepack);
    
    bool import_parameters(const std::string& filename);
    bool export_parameters(const std::string& filename);

  private:
    Dictionnary* m_dic;
    bool m_imported_param;

    void dump_nfa_state(std::fstream* outfile,
                        const vertex_id_t& vertex_id,
                        dictionnary_t* dic,
                        const criterionDefinition_s* criterion_def);
    void dump_padding(std::fstream* outfile, const size_t& slices);
    void parse_value(const std::string& value,
                     const valueid_t& value_id,
                     valueid_t* operand_a,
                     valueid_t* operand_b,
                     const criterionDefinition_s* criterion_def);

    std::fstream dump_workload(const std::string& filename, const rulePack_s& rulepack);
    void dump_partial_workload(const std::string& filename, const rulePack_s& rulepack,
                               std::fstream* fileaux, const uint32_t& size,const uint16_t& mult);

    std::size_t hash(vertexes_t& the_map, graph_t const& the_graph);

    uint16_t get_month_number(const std::string& month_code) const;
    uint32_t full_rata_die_day(const uint16_t& d, uint16_t m, uint16_t y) const;
    valueid_t date_check(const uint16_t& d, uint16_t m, uint16_t y) const;

    void parse_pairOfDates(const std::string& value, valueid_t* operand_a, valueid_t* operand_b) const;
    void parse_pairOfFlights(std::string value_raw, valueid_t* operand_a, valueid_t* operand_b) const;
};

} // namespace nfa_bre

#endif // NFA_BRE_NFA_HANDLER_H