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

#include "dictionnary.h"

#include <algorithm>
#include <fstream>

//#define WILDCARD_AS_LAST true
namespace erbium {

Dictionnary::Dictionnary(const rulePack_s& rulepack)
{
    for (auto& aux : rulepack.m_ruleType.m_criterionDefinition)
    {
        if (!aux.m_isMandatory)
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
    operand_t key = 0;
    for (auto& value : m_dic_contents)
        value.second = key++;

    // criteria indexes
    for (auto& criterion : m_dic_criteria)
    {
        key = 0;
        for(auto& value : criterion.second)
            value.second = key++;
    }

    // Put wildcard '*' codes as 0 or as LAST
    operand_t buff;
    for (auto& aux : rulepack.m_ruleType.m_criterionDefinition)
    {
        #ifdef WILDCARD_AS_LAST
        if (!aux.m_isMandatory)
        {
            buff = m_dic_criteria[aux.m_index].rbegin()->second;
            m_dic_criteria[aux.m_index].rbegin()->second = m_dic_criteria[aux.m_index]["*"];
            m_dic_criteria[aux.m_index]["*"] = buff;
        }
        #else
        if (!aux.m_isMandatory)
        {
            buff = m_dic_criteria[aux.m_index].begin()->second;
            m_dic_criteria[aux.m_index].begin()->second = m_dic_criteria[aux.m_index]["*"];
            m_dic_criteria[aux.m_index]["*"] = buff;
        }
        #endif
    }

    // sorting map
    for (auto& criterion : m_dic_criteria)
        m_sorting_map.push_back(criterion.first);
}

sorting_map_t Dictionnary::sort_by_n_of_values(const SortOrder order, std::vector<int16_t>* arbitrary)
{
    std::vector<std::pair<size_t, criterionid_t>> the_map; // list of pair <(#diff values) & (criteria_id)>
    
    // creation
    for (auto& criterion : m_dic_criteria)
        the_map.push_back(std::pair<size_t, criterionid_t>(criterion.second.size(), criterion.first));

    // effective sort
    if (order == SortOrder::Ascending)
        std::sort(the_map.begin(), the_map.end());
    else
        std::sort(the_map.begin(), the_map.end(), sort_pred_inv());

    // Update sorting_map
    size_t key = 0;
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

bool Dictionnary::exists_in_vector(const std::vector<int16_t> vec, const criterionid_t& point)
{
    for (auto& aux : vec)
    {
        if (aux == point)
            return true;
    }
    return false;
}

dictionnary_t Dictionnary::get_criterion_dic_by_level(const criterionid_t& level) const
{
    if (level == m_dic_criteria.size())
        return m_dic_contents;
    else
        return m_dic_criteria.at(m_sorting_map[level]);
}

int16_t Dictionnary::get_level_by_criterion_id(const criterionid_t& criterion_id) const
{
    int16_t key = 0;
    for (auto& aux : m_sorting_map)
    {
        if (aux == criterion_id)
            return key;
        key++;
    }
    return -1;
}

operand_t Dictionnary::get_valueid_by_sort(const criterionid_t& sort_id, const std::string& value) const
{
    if (sort_id == m_dic_criteria.size())
        return m_dic_contents.at(value);
    else
        return m_dic_criteria.at(sort_id).at(value);
}

operand_t Dictionnary::get_valueid_by_level(const criterionid_t& level, const std::string& value) const
{
    if (level == m_dic_criteria.size())
        return m_dic_contents.at(value);
    else
        return m_dic_criteria.at(m_sorting_map[level]).at(value);
}

void Dictionnary::dump_dictionnary(const std::string& filename)
{
    std::ofstream filecsv(filename, std::ios::out | std::ios::trunc);

    filecsv << "level,value,id\n";
    criterionid_t level = 0;
    for (auto& aux : m_sorting_map)
    {
        for (auto& pair : m_dic_criteria[aux])
        {
            filecsv << level << "," << pair.first << "," << pair.second << std::endl;
        }
        level++;
    }

    for (auto& pair : m_dic_contents)
    {
        filecsv << level << "," << pair.first << "," << pair.second << std::endl;
    }

    filecsv.close();
}

} // namespace erbium