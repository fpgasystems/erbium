#ifndef NFA_BRE_DEFINITIONS_H_
#define NFA_BRE_DEFINITIONS_H_

#include <boost/graph/adjacency_list.hpp>

#include <string>
#include <set>
#include <map>
#include <vector>

namespace nfa_bre {

const unsigned short int C_CACHE_LINE_WIDTH = 64;
const unsigned short int C_EDGES_PER_CACHE_LINE = C_CACHE_LINE_WIDTH / sizeof(uint64_t);
const unsigned short int C_RAW_CRITERION_SIZE = sizeof(uint32_t);
const unsigned short int C_RAW_RESUTLS_SIZE = sizeof(uint16_t);

// TODO a parameters struct and handle imports, exports, checks etc
const uint CFG_ENGINE_CRITERION_WIDTH = 14;
const uint CFG_WEIGHT_WIDTH           = 20;
const uint CFG_MEM_ADDR_WIDTH         = 15;  // ceil(log2(n_bram_edges_max));

const unsigned long long int MASK_WEIGHT     = 0xFFFFF;
const unsigned long long int MASK_POINTER    = 0x7FFF;
const unsigned long long int MASK_OPERAND_B  = 0x3FFF; // depends on CFG_ENGINE_CRITERION_WIDTH
const unsigned long long int MASK_OPERAND_A  = 0x3FFF; // depends on CFG_ENGINE_CRITERION_WIDTH
const unsigned long long int SHIFT_LAST      = CFG_WEIGHT_WIDTH+CFG_MEM_ADDR_WIDTH+2*CFG_ENGINE_CRITERION_WIDTH;
const unsigned long long int SHIFT_WEIGHT    = CFG_MEM_ADDR_WIDTH+2*CFG_ENGINE_CRITERION_WIDTH;
const unsigned long long int SHIFT_POINTER   = 2*CFG_ENGINE_CRITERION_WIDTH;
const unsigned long long int SHIFT_OPERAND_B = CFG_ENGINE_CRITERION_WIDTH;
const unsigned long long int SHIFT_OPERAND_A = 0;



enum SortOrder { Ascending, Descending };

struct criterionDefinition_s
{
    int m_index;
    std::string m_code;
    bool m_isMandatory;
    std::string m_supertag;
    unsigned short int m_functor;
    unsigned long int m_weight;
    bool m_isPair;
    bool operator < (const criterionDefinition_s &other) const { return m_index < other.m_index; }
    void print(const std::string &level) const
    {
        printf("%s[Criterion] index=%d code=%s isMandatory=%s supertag=%s functor=%d weight=%lu isPair=%s\n", 
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

    unsigned long int m_release;
    std::set<criterionDefinition_s> m_criterionDefinition;

    void print(const std::string &level) const
    {
        printf("%s[RuleType] org=%s app=%s v=%lu\n",
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
    int m_index;
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
    int m_ruleId;
    unsigned long int m_weight;
    std::set<criterion_s> m_criteria;
    std::string m_content;
    bool operator < (const rule_s &other) const { return m_ruleId < other.m_ruleId; }
    void print(const std::string &level) const
    {
        printf("%s[Rule] id=%d weight=%lu\n", 
            level.c_str(),
            m_ruleId,
            m_weight);
        for(auto& aux : m_criteria)
            aux.print(level + "\t");
    }
};
struct rulePack_s
{
    ruleType_s m_ruleType;
    std::set<rule_s> m_rules;

    void load(const std::string& filename);
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

////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////

struct vertex_info { 
    uint level;
    std::string label;
    std::string path;
    std::set<uint> parents;
    std::set<uint> children;
    uint dump_pointer;
};

typedef boost::adjacency_list<boost::vecS, boost::vecS, boost::directedS, vertex_info> graph_t;

} // namespace nfa_bre

#endif  // NFA_BRE_DEFINITIONS_H_