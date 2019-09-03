#ifndef NFA_BRE_DICTIONNARY_H_
#define NFA_BRE_DICTIONNARY_H_

#include <map>
#include <vector>

#include "definitions.h"

namespace nfa_bre {

class Dictionnary
{

  public:

    dic_criteria_t m_dic_criteria; // per criterion_id > per value > ID
    dictionnary_t  m_dic_contents;  // per value > ID
    sorting_map_t  m_sorting_map; // key=position; value=criterion_id

    Dictionnary(const rulePack_s& rulepack);

    // sorting
    sorting_map_t sort_by_n_of_values(const SortOrder order, std::vector<int16_t>* arbitrary = NULL);
    dictionnary_t get_criterion_dic_by_level(const criterionid_t& level);
    int16_t get_level_by_criterion_id(const criterionid_t& criterion_id);
    void dump_dictionnary(const std::string& filename);


  private:

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

#endif  // NFA_BRE_DICTIONNARY_H_