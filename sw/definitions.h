#ifndef NFA_BRE_DEFINITIONS_H_
#define NFA_BRE_DEFINITIONS_H_

#include <boost/graph/adjacency_list.hpp>

#include <string>
#include <set>
#include <map>
#include <vector>

namespace nfa_bre {

enum SortOrder { Ascending, Descending };

struct criterionDefinition_s
{
    int m_index;
    std::string m_code;
    bool m_isMandatory;
    std::string m_supertag;
    int m_weight;
    bool operator < (const criterionDefinition_s &other) const { return m_index < other.m_index; }
    void print(const std::string &level) const
    {
        printf("%s[Criterion] index=%d code=%s isMandatory=%s supertag=%s weight=%d\n", 
                level.c_str(),
                m_index,
                m_code.c_str(),
                (m_isMandatory)?"true":"false",
                m_supertag.c_str(),
                m_weight);
    }
};
struct ruleType_s
{
    std::string m_organization;
    std::string m_code;
    int m_release;
    std::vector<criterionDefinition_s> m_criterionDefinition;

    void print(const std::string &level) const
    {
        printf("%s[RuleType] org=%s app=%s v=%d\n",
            level.c_str(),
            m_organization.c_str(),
            m_code.c_str(),
            m_release);
        for(auto& aux : m_criterionDefinition)
            aux.print(level + "\t");
    }
    int get_criterium_id(const std::string code)
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
    std::string m_code;
    std::string m_value;
    bool operator < (const criterion_s &other) const { return m_index < other.m_index; }
    void print(const std::string &level) const
    {
        printf("%s[Criterion] id=%d code=%s value=%s\n",
            level.c_str(),
            m_index,
            m_code.c_str(),
            m_value.c_str());
    }
};
struct rule_s
{
    int m_ruleId;
    int m_weight;
    std::set<criterion_s> m_criteria;
    std::string m_content;
    bool operator < (const rule_s &other) const { return m_ruleId < other.m_ruleId; }
    void print(const std::string &level) const
    {
        printf("%s[Rule] id=%d weight=%d\n", 
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

    void load(const std::string &filename);
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