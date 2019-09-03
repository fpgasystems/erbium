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
    void dump_mirror_workload(const std::string& filename, const rulePack_s& rulepack);
    void dump_core_parameters(const std::string& filename, const rulePack_s& rulepack);

    void dump_drools_rules(const std::string& filename, const rulePack_s& rulepack);
    
    bool import_parameters(const std::string& filename);
    bool export_parameters(const std::string& filename);

  private:
    Dictionnary* m_dic;

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

    bool m_imported_param;

    std::size_t hash(vertexes_t& the_map, graph_t const& the_graph);

    uint32_t full_rata_die_day(const uint16_t& d, uint16_t m, uint16_t y)
    {
        if (m < 3)
            y--, m += 12;
        return 365*y + y/4 - y/100 + y/400 + (153*m - 457)/5 + d - 306;
    }

    valueid_t date_check(const uint16_t& d, uint16_t m, uint16_t y) // Rata Die day one is 0001-01-01
    {
        /*  0       wildcard '*': it matches anything
         *  1       infinity down   e.g. 1st Jan 1990
         *  2       start date      e.g. 1st Jan 2006
         *  ...
         *  2^14-2  end date        e.g. 6th Nov 2050
         *  2^14-1  infinity up     e.g. 1st Jan 9999
         * 
         *  16,381 days period
         */
        const uint32_t JANFIRST1990  =  726468; // 1st Jan 1990 - infinity down
        const uint32_t JANFIRST2006  =  732312; // 1st Jan 2006 - start date
        const uint32_t NOVNINETH2050 =  748692; // 6th Nov 2050 - end date
        const uint32_t JANFIRST9999  = 3651695; // 1st Jan 9999 - infinity up
        
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

    uint16_t get_month_number(const std::string& month_code)
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

    void parse_pairOfDates(const std::string& value, valueid_t* operand_a, valueid_t* operand_b)
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
        //printf("> [%s] is a=%u, b=%u\n", value.c_str(), *operand_a, *operand_b);
    }

    void parse_pairOfFlights(std::string value_raw, valueid_t* operand_a, valueid_t* operand_b)
    {
        std::replace(value_raw.begin(), value_raw.end(), '/', ' ');
        char* p_end;
        *operand_a = strtoul(value_raw.c_str(), &p_end, 10);
        *operand_b = strtoul(p_end, &p_end, 10);
    }
};

} // namespace nfa_bre

#endif // NFA_BRE_NFA_HANDLER_H