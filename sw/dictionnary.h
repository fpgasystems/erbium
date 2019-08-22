#ifndef NFA_BRE_DICTIONNARY_H_
#define NFA_BRE_DICTIONNARY_H_

#include <map>
#include <vector>

#include "definitions.h"

namespace nfa_bre {

class Dictionnary
{

  public:

    std::map<uint, std::map<std::string, uint>> m_dic_criteria; // per criterion_id > per value > ID
    std::map<std::string, uint> m_dic_contents;                 // per value > ID
    std::vector<unsigned short int> m_sorting_map;              // key=position; value=criterion_id

    Dictionnary(const rulePack_s& rulepack);

    // sorting
    std::vector<unsigned short int> sort_by_n_of_values(const SortOrder order, std::vector<short int>* arbitrary = NULL);
    std::map<std::string, uint> get_criterion_dic_by_level(const unsigned short int& level);
    int get_level_by_criterion_id(const uint& criterion_id);
    void dump_dictionnary(const std::string& filename);


  private:

    bool exists_in_vector(const std::vector<short int> vec, const short int& point);
    struct sort_pred_inv
    {
        bool operator()(const std::pair<uint,uint> &left, const std::pair<uint,uint> &right) {
            return left.first > right.first;
        }
    };
};

} // namespace nfa_bre

#endif  // NFA_BRE_DICTIONNARY_H_