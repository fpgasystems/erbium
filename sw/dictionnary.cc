#include "dictionnary.h"

#include <algorithm>

namespace nfa_bre {

Dictionnary::Dictionnary(const rulePack_s& rulepack)
{
    for (auto& aux : rulepack.m_ruleType.m_criterionDefinition)
    {
        m_dic_criteria[aux.m_index]["*"] = 0;
    }
    
    // scan rules
    for (auto& rule : rulepack.m_rules)
    {
        for (auto& aux : rule.m_criteria)
            m_dic_criteria[aux.m_index][aux.m_value] = 0;

        m_dic_contents[rule.m_content] = 0;
    }

    // content indexes
    uint key = 0;
    for (auto& value : m_dic_contents)
        value.second = key++;

    // criteria indexes
    for (auto& criterion : m_dic_criteria)
    {
        key = 0;
        for(auto& value : criterion.second)
            value.second = key++;
    }

    // TODO pre-add the wildcart '*' for all levels (so it's always the id=0)
    uint buff;
    for (auto& aux : rulepack.m_ruleType.m_criterionDefinition)
    {
        buff = m_dic_criteria[aux.m_index].GET_FIRST().second;
        m_dic_criteria[aux.m_index].GET_FIRST().second = m_dic_criteria[aux.m_index]["*"];
        m_dic_criteria[aux.m_index]["*"] = buff;
    }

    // sorting map
    for (auto& criterion : m_dic_criteria)
        m_sorting_map.push_back(criterion.first);
}

std::vector<unsigned short int> Dictionnary::sort_by_n_of_values(const SortOrder order, std::vector<unsigned short int>* arbitrary)
{
    std::vector<std::pair<uint, uint>> the_map;     // list of pair <(#diff values) & (criteria_id)>
    
    // creation
    for (auto& criterion : m_dic_criteria)
        the_map.push_back(std::pair<uint, uint>(criterion.second.size(), criterion.first));

    // effective sort
    if (order == SortOrder::Ascending)
        std::sort(the_map.begin(), the_map.end());
    else
        std::sort(the_map.begin(), the_map.end(), sort_pred_inv());

    // Update sorting_map
    uint key = 0;
    for (auto& aux : the_map)
        m_sorting_map[key++] = aux.second;

    if (arbitrary != NULL)
    {
        for (auto& aux : m_sorting_map)
        {
            if (exists_in_vector(*arbitrary, aux))
                continue;

            key = 0;
            for (auto& arb : *arbitrary)
            {
                if (arb == -1)
                {
                    (*arbitrary)[key] = aux;
                    break;
                }
                key++;
            }
        }

        key = 0;
        for (auto& aux : *arbitrary)
            m_sorting_map[key++] = aux;
    }

    return m_sorting_map;
}
bool Dictionnary::exists_in_vector(const std::vector<unsigned short int> vec, const unsigned short int& point)
{
    for (auto& aux : vec)
    {
        if (aux == point)
            return true;
    }
    return false;
}

std::map<std::string, uint> Dictionnary::get_criterion_dic_by_level(const unsigned short int& level)
{
    if (level == m_dic_criteria.size())
        return m_dic_contents;
    else
        return m_dic_criteria[m_sorting_map[level]];
}

int Dictionnary::get_level_by_criterion_id(const uint& criterion_id)
{
    int key = 0;
    for (auto& aux : m_sorting_map)
    {
        if (aux == criterion_id)
            return key;
        key++;
    }
    return -1;
}

} // namespace nfa_bre