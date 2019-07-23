#include <boost/property_tree/ptree.hpp>
#include <boost/property_tree/xml_parser.hpp>
#include <boost/foreach.hpp>

#include "definitions.h"

namespace nfa_bre {

void nfa_bre::abr_dataset_s::load(const std::string& filename)
{
    // Create empty property tree object
    boost::property_tree::ptree tree;

    // Parse the XML into the property tree.
    boost::property_tree::read_xml(filename, tree);

    m_organization = tree.get<std::string>("ABR.<xmlattr>.organization");
    m_application = tree.get<std::string>("ABR.<xmlattr>.application");

    BOOST_FOREACH(boost::property_tree::ptree::value_type &aux, tree.get_child("ABR.RUL"))
    {
        //printf("[%s]\n", aux.first.c_str());

        // RULE PACK
        rulePack_s aux_rulePack;

        if (!strcmp(aux.first.c_str(), "rules"))
        {
            BOOST_FOREACH(boost::property_tree::ptree::value_type &aux_a, aux.second.get_child(""))
            {
                //printf("\t[%s]\n", aux_a.first.c_str());

                if (!strcmp(aux_a.first.c_str(), "RTD"))
                {
                    // RULE TYPE
                    ruleType_s aux_ruleType;
                    aux_ruleType.m_organization = aux_a.second.get<std::string>("<xmlattr>.organization");
                    aux_ruleType.m_code = aux_a.second.get<std::string>("<xmlattr>.ruleTypeCode");
                    aux_ruleType.m_release = aux_a.second.get<int>("<xmlattr>.release");
                    BOOST_FOREACH(boost::property_tree::ptree::value_type &aux_b, aux_a.second.get_child(""))
                    {
                        //printf("\t\t[%s]\n", aux_b.first.c_str());
                        if (!strcmp(aux_b.first.c_str(), "criterionDefinition"))
                        {
                            criterionDefinition_s aux_criterionDef;
                            aux_criterionDef.m_index = aux_b.second.get<int>("<xmlattr>.index");
                            aux_criterionDef.m_code = aux_b.second.get<std::string>("<xmlattr>.code");
                            aux_criterionDef.m_isMandatory = aux_b.second.get("<xmlattr>.isMandatory",false);
                            aux_criterionDef.m_supertag = aux_b.second.get<std::string>("criterionType.<xmlattr>.supertag");
                            aux_criterionDef.m_weight = aux_b.second.get<unsigned long int>("criterionWeight.<xmlattr>.weight");
                            aux_ruleType.m_criterionDefinition.insert(aux_criterionDef);
                        }
                        //printf("[%s] %s\n", aux_b.first.c_str(), aux_b.second.data().c_str());
                        //boost::property_tree::ptree::value_type &aux_c = aux_b.second.get_child("<xmlattr>");
                    }
                    aux_rulePack.m_ruleType = aux_ruleType;
                }
                else if (!strcmp(aux_a.first.c_str(), "rule"))
                {
                    // RULE
                    rule_s aux_rule;
                    aux_rule.m_ruleId = aux_a.second.get<int>("<xmlattr>.ruleId");
                    aux_rule.m_weight = aux_a.second.get<unsigned long int>("weight");
                    aux_rule.m_content = aux_a.second.get<std::string>("content");
                    BOOST_FOREACH(boost::property_tree::ptree::value_type &aux_b, aux_a.second.get_child("criteria"))
                    {
                        //printf("[%s]\n", aux_b.first.c_str());

                        criterion_s aux_criterion;
                        aux_criterion.m_index = aux_b.second.get<int>("<xmlattr>.index");
                        aux_criterion.m_value = aux_b.second.get<std::string>("value");
                        aux_rule.m_criteria.insert(aux_criterion);
                    }
                    
                    aux_rulePack.m_rules.insert(aux_rule);
                }
            }
            m_rulePacks.insert(aux_rulePack);
        }
    }
}

void nfa_bre::rulePack_s::load(const std::string& filename)
{
    // for abr exported XML e.g. ruleTypeDefinition_MINCT_1-0_Template1.xml

    boost::property_tree::ptree tree;
    boost::property_tree::read_xml(filename, tree);

    // m_ruleType.m_organization = tree.get<std::string>("ruleTypeDefinition.organization");
    m_ruleType.m_organization = "Amadeus";
    m_ruleType.m_code         = tree.get<std::string>("ruleTypeDefinition.code");
    m_ruleType.m_description  = tree.get<std::string>("ruleTypeDefinition.description");
    m_ruleType.m_release      = tree.get<unsigned long int>("ruleTypeDefinition.subversion");

    BOOST_FOREACH(boost::property_tree::ptree::value_type &aux, tree.get_child("ruleTypeDefinition"))
    {
        if (!strcmp(aux.first.c_str(), "criterionDefinition"))
        {
            criterionDefinition_s aux_criterionDef;
            aux_criterionDef.m_index       = aux.second.get<int>("sequenceNumber");
            aux_criterionDef.m_code        = aux.second.get<std::string>("code");
            aux_criterionDef.m_isMandatory = aux.second.get("isMandatory",false);
            aux_criterionDef.m_supertag    = aux.second.get<std::string>("criterionTypeReference.id");
            aux_criterionDef.m_weight      = aux.second.get<unsigned long int>("weight", 0);

            switch (aux.second.count("guiProperties"))
            {
                case 1:
                    aux_criterionDef.m_isPair = false;
                    break;
                case 2:
                    aux_criterionDef.m_isPair = true;
                    break;
                default:
                    // problem!
                    aux_criterionDef.m_isPair = false;
                    printf("[!] Criterion %s has %lu `guiProperties`. Expected: 1 (simple) or 2 (pair)\n",
                            aux_criterionDef.m_code.c_str(), aux.second.count("guiProperties"));
            }
            m_ruleType.m_criterionDefinition.insert(aux_criterionDef);
        }
    }
}

} // namespace nfa_bre