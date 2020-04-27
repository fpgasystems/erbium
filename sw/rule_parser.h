#ifndef ERBIUM_RULE_PARSER_H
#define ERBIUM_RULE_PARSER_H
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

#include <vector>
#include <fstream>  // file read/write

#include "definitions.h"

namespace erbium {

class Dictionnary;

class RuleParser {
  public:

    // parse operand_a and operand_b according to the criterion
    static void parse_value(const std::string& value,
                            const operand_t& value_id,
                            operand_t* operand_a,
                            operand_t* operand_b,
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
    static operand_t date_check(const uint16_t& d, uint16_t m, uint16_t y);

    static void parse_pairOfDates(const std::string& value, operand_t* operand_a, operand_t* operand_b);
    static void parse_pairOfFlights(std::string value_raw, operand_t* operand_a, operand_t* operand_b);

    static std::fstream dump_csv_raw_workload(const std::string& filename, const rulePack_s& rulepack, const Dictionnary* dic);
};

} // namespace erbium

#endif // ERBIUM_RULE_PARSER_H