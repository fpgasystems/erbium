#include "dictionnary.h"

#include <algorithm>

namespace nfa_bre {

Dictionnary::Dictionnary(const rulePack_s rp)
{
    // scan rules
    for (auto& rule : rp.m_rules)
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
    for (auto& criterium : m_dic_criteria)
    {
        key = 0;
        for(auto& value : criterium.second)
            value.second = key++;
    }

    // sorting map
    for (auto& criterium : m_dic_criteria)          // TODO: check: is a map scan sorted by the key?
        m_sorting_map.push_back(criterium.first);
    // nothing garantees that the rule.m_criteria will be sorted by m_index
}

std::vector<uint> Dictionnary::sort_by_n_of_values(const SortOrder order, std::vector<int>* arbitrary)
{
    std::vector<std::pair<uint, uint>> the_map;     // list of pair <(#diff values) & (criteria_id)>
    
    // creation
    for (auto& criterium : m_dic_criteria)
        the_map.push_back(std::pair<uint, uint>(criterium.second.size(), criterium.first));

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
bool Dictionnary::exists_in_vector(const std::vector<int> vec, int point)
{
    for (auto& aux : vec)
    {
        if (aux == point)
            return true;
    }
    return false;
}

int Dictionnary::get_level_by_criterium_id(const uint criterium_id)
{
    int key = 0;
    for (auto& aux : m_sorting_map)
    {
        if (aux == criterium_id)
            return key;
        key++;
    }
    return -1;
}

std::map<std::string, uint> Dictionnary::get_criterium_dic_by_level(const uint level)
{
    if (level == m_dic_criteria.size())
        return m_dic_contents;
    else
        return m_dic_criteria[m_sorting_map[level]];
}

} // namespace nfa_bre