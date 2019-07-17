#ifndef NFA_BRE_DICTIONNARY_H_
#define NFA_BRE_DICTIONNARY_H_

#include <map>
#include <vector>

#include "definitions.h"

namespace nfa_bre {

class Dictionnary
{

  public:

    std::map<uint, std::map<std::string, uint>> m_dic_criteria; // per criteria_id > per value > ID
    std::map<std::string, uint> m_dic_contents;                 // per value > ID
    std::vector<uint> m_sorting_map;                            // key=position; value=criteria_id

    Dictionnary(const rulePack_s rp);

    // sorting
    std::vector<uint> sort_by_n_of_values(const SortOrder order,
                                          std::vector<int>* arbitrary = NULL);
    std::map<std::string, uint> get_criterium_dic_by_level(const uint level);
    int get_level_by_criterium_id(const uint criterium_id);


  private:

    bool exists_in_vector(const std::vector<int> vec, int point);
    struct sort_pred_inv
    {
        bool operator()(const std::pair<uint,uint> &left, const std::pair<uint,uint> &right) {
            return left.first > right.first;
        }
    };
};

} // namespace nfa_bre

#endif  // NFA_BRE_DICTIONNARY_H_