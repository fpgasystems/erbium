#ifndef NFA_BRE_DICTIONNARY_H
#define NFA_BRE_DICTIONNARY_H

#include <map>
#include <vector>

#include "definitions.h"

namespace nfa_bre {

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

} // namespace nfa_bre

#endif  // NFA_BRE_DICTIONNARY_H