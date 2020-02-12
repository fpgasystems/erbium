#ifndef NFA_BRE_RULE_PARSER_H
#define NFA_BRE_RULE_PARSER_H

#include <vector>
#include <fstream>  // file read/write

#include "definitions.h"

namespace nfa_bre {

class Dictionnary;

class RuleParser {
  public:

    // parse operand_a and operand_b according to the criterion
    static void parse_value(const std::string& value,
                            const valueid_t& value_id,
                            valueid_t* operand_a,
                            valueid_t* operand_b,
                            const criterionDefinition_s* criterion_def);

    // export benchmark workload based on rules
    static void export_benchmark_workload(const std::string& path, const rulePack_s& rulepack, const Dictionnary* dic);

    // export criteria parameters for core.vhd
    static void export_vhdl_parameters(const std::string& filename,
                                       const rulePack_s& rulepack,
                                       const Dictionnary* dic,
                                       const std::vector<uint> edges_per_level);

  private:
    RuleParser();

    static uint16_t get_month_number(const std::string& month_code);
    static uint32_t full_rata_die_day(const uint16_t& d, uint16_t m, uint16_t y);
    static valueid_t date_check(const uint16_t& d, uint16_t m, uint16_t y);

    static void parse_pairOfDates(const std::string& value, valueid_t* operand_a, valueid_t* operand_b);
    static void parse_pairOfFlights(std::string value_raw, valueid_t* operand_a, valueid_t* operand_b);

    static std::fstream dump_csv_raw_workload(const std::string& filename, const rulePack_s& rulepack, const Dictionnary* dic);
};

} // namespace nfa_bre

#endif // NFA_BRE_RULE_PARSER_H