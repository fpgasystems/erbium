#ifndef ERBIUM_DEFINITIONS_H_
#define ERBIUM_DEFINITIONS_H_
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

#include <boost/graph/adjacency_list.hpp>

#include <string>
#include <set>
#include <map>
#include <vector>

namespace erbium {
// TODO a parameters struct and handle imports, exports, checks etc

////////////////////////////////////////////////////////////////////////////////////////////////////
// SW / HW CONSTRAINTS                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////

// raw criterion value (must be consistent with kernel_<shell>.cpp and engine_pkg.vhd)
typedef uint16_t  operand_t;

// raw NFA transition (to be stored in ultraRam)
typedef uint64_t  transition_t;


// create binary masks for n-bit wise field
constexpr transition_t generate_mask(int n)
{
    return n <= 1 ? 1 : (1 + (generate_mask(n-1) << 1));
}

// raw cacheline size (must be consistent with kernel_<shell>.cpp and erbium_wrapper.vhd)
const unsigned char C_CACHELINE_SIZE = 64; // in bytes

// used for determining zero-padding
const uint16_t C_EDGES_PER_CACHE_LINE = C_CACHELINE_SIZE / sizeof(transition_t);

// actual size of a criterion value (must be consistent with engine_pkg.vhd)
const uint16_t CFG_CRITERION_VALUE_WIDTH = 13; // in bits

// actual size of an address pointer (must be consistent with engine_pkg.vhd)
const uint16_t CFG_TRANSITION_POINTER_WIDTH = 16; // in bits

// maximum number of transitions able to stored in one memory unit
const uint32_t CFG_MEM_MAX_DEPTH = (1 << (CFG_TRANSITION_POINTER_WIDTH + 1)) - 1;

const transition_t MASK_POINTER  = generate_mask(CFG_TRANSITION_POINTER_WIDTH);
const transition_t MASK_OPERANDS = generate_mask(CFG_CRITERION_VALUE_WIDTH);

// shift constants to align fields to a transition memory line
const char SHIFT_OPERAND_A = 0;
const char SHIFT_OPERAND_B = CFG_CRITERION_VALUE_WIDTH + SHIFT_OPERAND_A;
const char SHIFT_POINTER   = CFG_CRITERION_VALUE_WIDTH + SHIFT_OPERAND_B;
const char SHIFT_LAST      = CFG_TRANSITION_POINTER_WIDTH + SHIFT_POINTER;


// Static sanity checks
static_assert(CFG_TRANSITION_POINTER_WIDTH + 2*CFG_CRITERION_VALUE_WIDTH + 1 <= sizeof(transition_t)*8,
              "NFA Transition fields to be stored must fit into the memory line.");

static_assert(CFG_CRITERION_VALUE_WIDTH <= sizeof(operand_t) * 8,
              "Operand (criterion value) size must fit into operand_t type.");


////////////////////////////////////////////////////////////////////////////////////////////////////
// TYPEDEF                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////

// elements
typedef uint16_t                                criterionid_t;
typedef uint32_t                                weight_t;
typedef uint32_t                                ruleid_t;

// dictionnary
typedef std::map<std::string, operand_t>       dictionnary_t;
typedef std::map<criterionid_t, dictionnary_t>  dic_criteria_t;
typedef std::vector<criterionid_t>              sorting_map_t;

// graph
struct vertex_info;
typedef boost::adjacency_list<boost::vecS, boost::vecS, boost::directedS, vertex_info> graph_t;
typedef boost::graph_traits<graph_t>::vertex_descriptor                       vertex_id_t;
typedef std::map<criterionid_t, std::map<operand_t, std::set<vertex_id_t>>>  vertexes_t;


enum SortOrder { Ascending, Descending };

struct vertex_info { 
    criterionid_t level;
    std::string   label;
    std::string   path;
    weight_t      weight; // only used for DFA filtering at last level
    std::set<vertex_id_t> parents;
    std::set<vertex_id_t> children;
    uint16_t dump_pointer;
};

struct criterionDefinition_s
{
    criterionid_t m_index;
    std::string m_code;
    bool m_isMandatory;
    std::string m_supertag;
    uint16_t m_functor;
    weight_t m_weight;
    bool m_isPair;
    bool operator < (const criterionDefinition_s &other) const { return m_index < other.m_index; }
    void print(const std::string &level) const
    {
        printf("%s[Criterion] index=%u code=%s isMandatory=%s supertag=%s functor=%u weight=%u isPair=%s\n", 
                level.c_str(),
                m_index,
                m_code.c_str(),
                (m_isMandatory) ? "true" : "false",
                m_supertag.c_str(),
                m_functor,
                m_weight,
                (m_isPair) ? "true" : "false");
    }
};
struct ruleType_s
{
    std::string m_organization;
    std::string m_code;
    std::string m_description;

    uint32_t m_release;
    std::set<criterionDefinition_s> m_criterionDefinition;

    void print(const std::string &level) const
    {
        printf("%s[RuleType] org=%s app=%s v=%u\n",
            level.c_str(),
            m_organization.c_str(),
            m_code.c_str(),
            m_release);
        for(auto& aux : m_criterionDefinition)
            aux.print(level + "\t");
    }
    int get_criterion_id(const std::string& code)
    {
        for (auto& aux : m_criterionDefinition)
        {
            if (aux.m_code == code)
                return aux.m_index;
        }
        return -1; // not found
    }

};
struct criterion_s
{
    criterionid_t m_index;
    std::string m_value;
    bool operator < (const criterion_s &other) const { return m_index < other.m_index; }
    void print(const std::string &level) const
    {
        printf("%s[Criterion] id=%d value=%s\n",
            level.c_str(),
            m_index,
            m_value.c_str());
    }
};
struct rule_s
{
    ruleid_t m_ruleId;
    weight_t m_weight;
    std::set<criterion_s> m_criteria;
    std::string m_content;
    bool operator < (const rule_s &other) const { return m_ruleId < other.m_ruleId; }
    void print(const std::string &level) const
    {
        printf("%s[Rule] id=%d weight=%u content=%s\n", 
            level.c_str(),
            m_ruleId,
            m_weight,
            m_content.c_str());
        for(auto& aux : m_criteria)
            aux.print(level + "\t");
    }
};
struct rulePack_s
{
    ruleType_s m_ruleType;
    std::set<rule_s> m_rules;

    void load_ruleType(const std::string& filename);
    void load_rules(const std::string& filename);
    bool operator < (const rulePack_s &other) const { return true; }
    void print(const std::string &level) const
    {
        m_ruleType.print(level);
        for(auto& aux : m_rules)
            aux.print(level + "\t");
    }
};
struct abr_dataset_s
{
    std::string m_organization;
    std::string m_application;
    std::set<rulePack_s> m_rulePacks;

    void load(const std::string& filename);
    void save(const std::string &filename);

    void print(const std::string &level) const
    {
        printf("%sorg: %s\n", level.c_str(), m_organization.c_str());
        printf("%sapp: %s\n", level.c_str(), m_application.c_str());
        for(auto& aux : m_rulePacks)
            aux.print(level + "\t");
    }
};

} // namespace erbium

#endif  // ERBIUM_DEFINITIONS_H_