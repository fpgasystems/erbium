#ifndef ERBIUM_DICTIONNARY_H
#define ERBIUM_DICTIONNARY_H
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

#include <map>
#include <vector>

#include "definitions.h"

namespace erbium {

class Dictionnary
{
  public:
    sorting_map_t  m_sorting_map; // key=position; value=criterion_id

    Dictionnary(const rulePack_s& rulepack);

    // sorting
    sorting_map_t sort_by_n_of_values(const SortOrder order, std::vector<int16_t>* arbitrary = NULL);

    dictionnary_t get_criterion_dic_by_level(const criterionid_t& level) const;
    int16_t get_level_by_criterion_id(const criterionid_t& criterion_id) const;

    valueid_t get_valueid_by_sort(const criterionid_t& sort_id, const std::string& value) const;
    valueid_t get_valueid_by_level(const criterionid_t& level, const std::string& value) const;

    void dump_dictionnary(const std::string& filename);

  private:
    dic_criteria_t m_dic_criteria; // per criterion_id > per value > ID
    dictionnary_t  m_dic_contents;  // per value > ID

    bool exists_in_vector(const std::vector<int16_t> vec, const criterionid_t& point);
    struct sort_pred_inv
    {
        bool operator()(const std::pair<criterionid_t,criterionid_t> &left,
                        const std::pair<criterionid_t,criterionid_t> &right) {
            return left.first > right.first;
        }
    };
};

} // namespace erbium

#endif  // ERBIUM_DICTIONNARY_H