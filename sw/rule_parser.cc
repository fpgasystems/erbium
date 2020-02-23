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

#include "rule_parser.h"
#include "dictionnary.h"

#include <string>
#include <iostream> // std::cout
#include <random>   // std::default_random_engine

namespace erbium {

void RuleParser::parse_value(const std::string& value_raw,
                             const valueid_t& value_id,
                             valueid_t* operand_a,
                             valueid_t* operand_b,
                             const criterionDefinition_s* criterion_def)
{
    if (!criterion_def->m_isPair)
    {
        *operand_a = value_id;
        *operand_b = 0;
    }
    else if (value_raw.c_str()[0] == '*')
    {
        *operand_a = value_id;
        *operand_b = value_id;
    }
    else
    {
        switch (criterion_def->m_functor)
        {
            case 212: // criterionType_pairofdates.xml
                parse_pairOfDates(value_raw, operand_a, operand_b);
                break;
            case 412: // criterionType_integerrange4-digits_412.xml
                parse_pairOfFlights(value_raw, operand_a, operand_b);
                break;
            default:
                std::cout << "[!] Pair functor #" << criterion_def->m_functor;
                std::cout << " of value= " << value_raw << " is unknown\n";
                *operand_a = 0;
                *operand_b = 0;
        }
    }
}

uint16_t RuleParser::get_month_number(const std::string& month_code)
{
    std::map<std::string, uint16_t> months
    {
        { "JAN",  1 },
        { "FEB",  2 },
        { "MAR",  3 },
        { "APR",  4 },
        { "MAY",  5 },
        { "JUN",  6 },
        { "JUL",  7 },
        { "AUG",  8 },
        { "SEP",  9 },
        { "OCT", 10 },
        { "NOV", 11 },
        { "DEC", 12 }
    };

    return months[month_code];
}

uint32_t RuleParser::full_rata_die_day(const uint16_t& d, uint16_t m, uint16_t y)
{
    if (m < 3)
        y--, m += 12;
    return 365*y + y/4 - y/100 + y/400 + (153*m - 457)/5 + d - 306;
}

valueid_t RuleParser::date_check(const uint16_t& d, uint16_t m, uint16_t y)
{
    // Rata Die day one is 0001-01-01

    /*  0       wildcard '*': it matches anything
     *  1       infinity down   e.g. 1st Jan 1990
     *  2       start date      e.g. 1st Jan 2006
     *  ...
     *  2^14-2  end date        e.g. 6th Nov 2050
     *  2^14-1  infinity up     e.g. 1st Jan 9999
     * 
     *  16,381 days period
     */
    // const uint32_t JANFIRST1990  =  726468; // 1st Jan 1990 - infinity down
    // const uint32_t JANFIRST2006  =  732312; // 1st Jan 2006 - start date
    // const uint32_t NOVNINETH2050 =  748692; // 6th Nov 2050 - end date
    // const uint32_t JANFIRST9999  = 3651695; // 1st Jan 9999 - infinity up
    const uint32_t JANFIRST1990  =  726468; // 1st Jan 1990 - infinity down
    const uint32_t JANFIRST2006  =  732312; // 1st Jan 2006 - start date
    const uint32_t NOVNINETH2050 = JANFIRST2006 + (1 << CFG_ENGINE_CRITERION_WIDTH) - 2; // end date
    const uint32_t JANFIRST9999  = 3651695; // 1st Jan 9999 - infinity up
    // using 1st Jan 2006 as start day, the end day is:
    //   - 13 bits: 2 Jun 2028
    //   - 14 bits: 6 Nov 2050
    uint32_t interim = full_rata_die_day(d, m, y);

    if (interim == JANFIRST1990)
    {
        return 1;
    }
    else if (interim < JANFIRST2006)
    {
        printf("[!] Minimal date is Jan 1st 2006, got: m=%d d=%d y=%d\n", m, d, y);
        return 1;
    }
    else if (interim == JANFIRST9999)
    {
        return USHRT_MAX;
    }
    else if (interim > NOVNINETH2050)
    {
        printf("[!] Maximal date is Nov 6th 2050, got: m=%d d=%d y=%d\n", m, d, y);
        return USHRT_MAX;
    }
    else
        return interim - JANFIRST2006 + 2;
}

void RuleParser::parse_pairOfDates(const std::string& value, valueid_t* operand_a, valueid_t* operand_b)
{
    if (value.length() != 19)
    {
        printf("[!] Failed parsing value [%s] as a pair of dates\n", value.c_str());
        *operand_a = 0;
        *operand_b = 0;
        return;
    }

    *operand_a = date_check(atoi(value.substr( 0,  2).c_str()),
                            get_month_number(value.substr( 2,  3)),
                            atoi(value.substr( 5,  4).c_str()));
    *operand_b = date_check(atoi(value.substr(10, 2).c_str()),
                            get_month_number(value.substr(12, 3)),
                            atoi(value.substr(15, 4).c_str()));
}

void RuleParser::parse_pairOfFlights(std::string value_raw, valueid_t* operand_a, valueid_t* operand_b)
{
    std::replace(value_raw.begin(), value_raw.end(), '/', ' ');
    char* p_end;
    *operand_a = strtoul(value_raw.c_str(), &p_end, 10);
    *operand_b = strtoul(p_end, &p_end, 10);
}

void RuleParser::export_benchmark_workload(const std::string& path, const rulePack_s& rulepack, const Dictionnary* dic)
{
    // generate .csv and .aux
    std::fstream fileaux = RuleParser::dump_csv_raw_workload(path + "benchmark", rulepack, dic);
    std::fstream benchfile(path + "benchmark.bin", std::ios::out | std::ios::trunc | std::ios::binary);

    // first data corresponds to query size + benchmark size
    uint32_t query_size = rulepack.m_ruleType.m_criterionDefinition.size() * C_RAW_CRITERION_SIZE;
    query_size = query_size / C_CACHE_LINE_WIDTH + ((query_size % C_CACHE_LINE_WIDTH) ? 1 : 0);
    query_size = query_size * C_CACHE_LINE_WIDTH;
    uint32_t benchmark_size = rulepack.m_rules.size();

    benchfile.write(reinterpret_cast<char *>(&query_size), sizeof(query_size));
    benchfile.write(reinterpret_cast<char *>(&benchmark_size), sizeof(benchmark_size));

    // append benchmark.aux
    fileaux.seekg(0, std::ios::beg);
    benchfile << fileaux.rdbuf();

    fileaux.close();
    benchfile.close();
    remove(((std::string)(path + "benchmark.aux")).c_str());
}

std::fstream RuleParser::dump_csv_raw_workload(const std::string& filename, const rulePack_s& rulepack, const Dictionnary* dic)
{
    std::fstream filecsv(filename + ".csv", std::ios::out | std::ios::trunc);
    std::fstream fileaux(filename + ".aux", std::ios::out | std::ios::in | std::ios::trunc | std::ios::binary);

    const uint SLICES_PER_LINE = C_CACHE_LINE_WIDTH / C_RAW_CRITERION_SIZE;
    uint padding_slices = (rulepack.m_ruleType.m_criterionDefinition.size()) % SLICES_PER_LINE;
    padding_slices = (padding_slices == 0) ? 0 : SLICES_PER_LINE - padding_slices;

    operands_t mem_opa;
    operands_t mem_opb;
    const criterion_s* aux_criterion;
    const criterionDefinition_s* aux_definition;

    // export csv header
    filecsv << "ID,WEIGHT";
    for (auto& aux : dic->m_sorting_map)
    {
        filecsv << ",";
        filecsv << std::next(rulepack.m_ruleType.m_criterionDefinition.begin(), aux)->m_code;
    }
    filecsv << ",CONTENT" << std::endl;


    // shuffle rules so benchmark has no similar consecutive queries
    std::vector<rule_s> the_rules(rulepack.m_rules.begin(), rulepack.m_rules.end());
    std::shuffle(the_rules.begin(), the_rules.end(), std::default_random_engine(0));

    for (auto& rule : the_rules)
    {
        filecsv << rule.m_ruleId << "," << rule.m_weight;
        for (auto& ord : dic->m_sorting_map)
        {
            aux_criterion  = &(*std::next(rule.m_criteria.begin(), ord));
            aux_definition = &(*std::next(rulepack.m_ruleType.m_criterionDefinition.begin(), ord));

            RuleParser::parse_value(
                    aux_criterion->m_value,
                    dic->get_valueid_by_sort(ord, aux_criterion->m_value),
                    &mem_opa,
                    &mem_opb,
                    aux_definition);
            mem_opa = mem_opa & MASK_OPERAND_A;
            fileaux.write((char*)&mem_opa, sizeof(mem_opa));
            filecsv << "," << aux_criterion->m_value;
        }
        filecsv << "," << rule.m_content << std::endl;

        // padding
        mem_opa = 0;
        for (uint pad = padding_slices; pad != 0; pad--)
            fileaux.write((char*)&mem_opa, sizeof(mem_opa));
    }

    filecsv.close();
    return fileaux;
}

void RuleParser::export_vhdl_parameters(
    const std::string& filename,
    const rulePack_s& rulepack,
    const Dictionnary* dic,
    const std::vector<uint> edges_per_level)
{
    std::fstream outfile(filename, std::ios::out | std::ios::trunc);

    outfile << "library ieee;\nuse ieee.numeric_std.all;\nuse ieee.std_logic_1164.all;\n\n"
            << "library erbium;\nuse erbium.engine_pkg.all;\nuse erbium.core_pkg.all;\n\n"
            << "package cfg_criteria is\n"
            << "    type CORE_PARAM_ARRAY is array (0 to CFG_ENGINE_NCRITERIA - 1) of core_parameters_type;\n\n";

    const criterionDefinition_s* criterion_def;
    char buffer[1024];
    std::string func_a, func_b, func_pair, match_mode;
    criterionid_t the_level = 0;
    for (auto& ord : dic->m_sorting_map)
    {
        criterion_def = &(*std::next(rulepack.m_ruleType.m_criterionDefinition.begin(), ord));

        switch(criterion_def->m_functor)
        {
            case  60 : // criterionType_alphanumstring3-3.xml
            case  67 : // criterionType_alphanumstring2-2.xml
            case 273 : // criterionType_alphastring2-2.xml
            case 316 : // criterionType_alphanumstring1-3.xml
            case 408 : // criterionType_integer0-9999_408.xml
                func_a     = "FNCTR_SIMP_EQU";
                func_b     = "FNCTR_SIMP_NOP";
                func_pair  = "FNCTR_PAIR_NOP";
                match_mode = "MODE_STRICT_MATCH";
                break;
            case 212 : // criterionType_pairofdates.xml
            case 412 : // criterionType_integerrange4-digits_412.xml
                func_a     = "FNCTR_SIMP_GEQ";
                func_b     = "FNCTR_SIMP_LEQ";
                func_pair  = "FNCTR_PAIR_AND";
                match_mode = "MODE_FULL_ITERATION";
                break;
            default:
                std::cout << "[!] functor #" << criterion_def->m_functor << " is unknown\n";
                func_a     = "FNCTR_SIMP_NOP";
                func_b     = "FNCTR_SIMP_NOP";
                func_pair  = "FNCTR_PAIR_NOP";
                match_mode = "MODE_FULL_ITERATION";
        }
        uint ram_depth = 1 << ((uint)ceil(log2(edges_per_level[the_level])));
        // std::cout << "edges_per_level[" << the_level << "] = " << edges_per_level[the_level] << std::endl;
        sprintf(buffer, "    constant CORE_PARAM_%u : core_parameters_type := (\n"
                        "        G_RAM_DEPTH           => %u,\n"
                        "        G_RAM_LATENCY         => %u,\n"
                        "        G_MATCH_STRCT         => %s,\n"
                        "        G_MATCH_FUNCTION_A    => %s,\n"
                        "        G_MATCH_FUNCTION_B    => %s,\n"
                        "        G_MATCH_FUNCTION_PAIR => %s,\n"
                        "        G_MATCH_MODE          => %s,\n"
                        "        G_WEIGHT              => std_logic_vector(to_unsigned(%u, CFG_WEIGHT_WIDTH)),\n"
                        "        G_WILDCARD_ENABLED    => '%u'\n"
                        "    );\n",
            the_level,
            ram_depth,
            std::max((uint)3, ram_depth / 4096 + 2),
            (criterion_def->m_isPair) ? "STRCT_PAIR" : "STRCT_SIMPLE",
            func_a.c_str(),
            func_b.c_str(),
            func_pair.c_str(),
            match_mode.c_str(),
            criterion_def->m_weight,
            !criterion_def->m_isMandatory);

        outfile << buffer;        
        the_level++;
    }
    outfile << "    constant CFG_CORE_PARAM_ARRAY : CORE_PARAM_ARRAY := (\n";
    for (the_level = 0; the_level < rulepack.m_ruleType.m_criterionDefinition.size()-1; the_level++)
    {
        outfile << "        CORE_PARAM_" << the_level;
        if (the_level != rulepack.m_ruleType.m_criterionDefinition.size())
            outfile << ",\n";
        else
            outfile << "\n    );";
    }

    outfile << "\n\nend cfg_criteria;\n\npackage body cfg_criteria is\n\nend cfg_criteria;";

    outfile.close();
}

} // namespace erbium