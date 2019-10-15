#ifndef NFA_BRE_DEFINITIONS_H_
#define NFA_BRE_DEFINITIONS_H_

#include <boost/graph/adjacency_list.hpp>

#include <string>
#include <set>
#include <map>
#include <vector>

namespace nfa_bre {

const uint16_t C_CACHE_LINE_WIDTH = 64;
const uint16_t C_EDGES_PER_CACHE_LINE = C_CACHE_LINE_WIDTH / sizeof(uint64_t);
const uint16_t C_RAW_CRITERION_SIZE = sizeof(uint16_t);
const uint16_t C_RAW_RESUTLS_SIZE = sizeof(uint16_t);
const uint16_t C_RAW_RESULT_STATS_WIDTH = sizeof(uint64_t);

// TODO a parameters struct and handle imports, exports, checks etc
const uint16_t CFG_ENGINE_CRITERION_WIDTH = 13;
const uint16_t CFG_WEIGHT_WIDTH           = 20;
const uint16_t CFG_MEM_ADDR_WIDTH         = 16;  // ceil(log2(n_bram_edges_max));

const uint64_t MASK_WEIGHT     = 0xFFFFF;
const uint64_t MASK_POINTER    = 0x7FFF;
const uint64_t MASK_OPERAND_B  = 0x3FFF; // depends on CFG_ENGINE_CRITERION_WIDTH
const uint64_t MASK_OPERAND_A  = 0x3FFF; // depends on CFG_ENGINE_CRITERION_WIDTH
const uint64_t SHIFT_LAST      = CFG_WEIGHT_WIDTH+CFG_MEM_ADDR_WIDTH+2*CFG_ENGINE_CRITERION_WIDTH;
const uint64_t SHIFT_WEIGHT    = CFG_MEM_ADDR_WIDTH+2*CFG_ENGINE_CRITERION_WIDTH;
const uint64_t SHIFT_POINTER   = 2*CFG_ENGINE_CRITERION_WIDTH;
const uint64_t SHIFT_OPERAND_B = CFG_ENGINE_CRITERION_WIDTH;
const uint64_t SHIFT_OPERAND_A = 0;

////////////////////////////////////////////////////////////////////////////////////////////////////
// TYPEDEF                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////

// memory (change kernel.cpp as well)
typedef uint16_t                                operands_t;

// elements
typedef uint16_t                                criterionid_t;
typedef uint32_t                                weight_t;
typedef uint16_t                                valueid_t;
typedef uint32_t                                ruleid_t;

// dictionnary
typedef std::map<std::string, valueid_t>        dictionnary_t;
typedef std::map<criterionid_t, dictionnary_t>  dic_criteria_t;
typedef std::vector<criterionid_t>              sorting_map_t;

// graph
struct vertex_info;
typedef boost::adjacency_list<boost::vecS, boost::vecS, boost::directedS, vertex_info> graph_t;
typedef boost::graph_traits<graph_t>::vertex_descriptor                      vertex_id_t;
typedef std::map<criterionid_t, std::map<valueid_t, std::set<vertex_id_t>>>  vertexes_t;


enum SortOrder { Ascending, Descending };

struct vertex_info { 
    criterionid_t level;
    std::string   label;
    std::string   path;
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

} // namespace nfa_bre

#endif  // NFA_BRE_DEFINITIONS_H_