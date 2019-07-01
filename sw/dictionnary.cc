#include "definitions.h"

enum SortOrder = {Ascending, Descending};

class Dictionnary
{

  public:
    std::map<uint, std::map<std::string, uint>> m_dic_criteria; // per criteria_id > per value > ID
    std::map<std::string, uint> m_dic_contents;                 // per value > ID
    std::vector<uint> m_sorting_map;                            // key=position; value=criteria_id

    Dictionnary(const& rulePack_s rp);

    // sorting
    std::vector<uint> sort_by_n_of_values(const& SortOrder order);

  private:

    struct sort_pred_inv
    {
        bool operator()(const std::pair<uint,uint> &left, const std::pair<uint,uint> &right) {
            return left.first > right.first;
        }
    };
}

Dictionnary(const& rulePack_s rp)
{
    // scan rules
    for (auto& rule : rp.m_rules)
    {
        for (auto& aux : rule.m_criteria)
            m_dic_criteria[aux.m_index][aux.m_value] = 0;

        m_dic_contents[rule.m_content] = 0;
    }
    
    // content indexes
    for (auto& value : m_dic_contents)
        value.second = key++;

    // criteria indexes
    uint key = 0;
    for (auto& criterium : m_dic_criteria)
    {
        key = 0;
        for(auto& value : criterium.second)
            value.second = key++;
    }

    // sorting map
    for (auto& criterium : m_dic_criteria)          // TODO: check: is a map scan sorted by the key?
        ordered.push_back(criterium.first);
    // nothing garantees that the rule.m_criteria will be sorted by m_index
}

std::vector<uint> sort_by_n_of_values(const& SortOrder order)
{
    std::vector<std::pair<uint, uint>> the_map;     // list of pair <(#diff values) & (criteria_id)>
    uint key = 0;
    
    // creation
    for (auto& criterium : m_dic_criteria)
        the_map.push_back(std::pair<uint, uint>(criterium.second.size(), criteria.first));

    // effective sort
    if (order == SortOrder::Ascending)
        sort(ordered.begin(), ordered.end());
    else
        sort(ordered.begin(), ordered.end(), sort_pred_inv());

    // Update sorting_map
    for (auto& aux : the_map)
        m_sorting_map[key++] = aux.second;

    return m_sorting_map;
}