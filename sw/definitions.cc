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

#include <boost/property_tree/ptree.hpp>
#include <boost/property_tree/xml_parser.hpp>
#include <boost/foreach.hpp>

#include "definitions.h"

namespace erbium {

class CSVRow
{
public:
    std::vector<std::string> m_data;
    
    std::string const& operator[](std::size_t index) const
    {
        return m_data[index];
    }
    std::size_t size() const
    {
        return m_data.size();
    }
    std::string get_value(std::size_t index)
    {
        // REMOVE " "
        return m_data[index].substr(1, m_data[index].size()-2);
    }
    void readNextRow(std::istream& str)
    {
        std::string line;
        std::string cell;

        std::getline(str, line);
        std::stringstream lineStream(line);

        m_data.clear();
        while(std::getline(lineStream, cell, ','))
        {
            m_data.push_back(cell);
        }
        // This checks for a trailing comma with no data after it.
        if (!lineStream && cell.empty())
        {
            // If there was a trailing comma then add an empty element.
            m_data.push_back("");
        }
    }
};
std::istream& operator>>(std::istream& str, CSVRow& data)
{
    data.readNextRow(str);
    return str;
}

void erbium::abr_dataset_s::load(const std::string& filename)
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
                            aux_criterionDef.m_index = aux_b.second.get<criterionid_t>("<xmlattr>.index");
                            aux_criterionDef.m_code = aux_b.second.get<std::string>("<xmlattr>.code");
                            aux_criterionDef.m_isMandatory = aux_b.second.get("<xmlattr>.isMandatory",false);
                            aux_criterionDef.m_supertag = aux_b.second.get<std::string>("criterionType.<xmlattr>.supertag");
                            aux_criterionDef.m_weight = aux_b.second.get<weight_t>("criterionWeight.<xmlattr>.weight");
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
                    aux_rule.m_ruleId  = aux_a.second.get<ruleid_t>("<xmlattr>.ruleId");
                    aux_rule.m_weight  = aux_a.second.get<weight_t>("weight");
                    aux_rule.m_content = aux_a.second.get<std::string>("content");
                    BOOST_FOREACH(boost::property_tree::ptree::value_type &aux_b, aux_a.second.get_child("criteria"))
                    {
                        //printf("[%s]\n", aux_b.first.c_str());

                        criterion_s aux_criterion;
                        aux_criterion.m_index = aux_b.second.get<criterionid_t>("<xmlattr>.index");
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

void erbium::rulePack_s::load_rules(const std::string& filename)
{
    std::ifstream file(filename);
    CSVRow row;
    row.readNextRow(file);
    int aux = row.m_data.size()-4;
    while(file >> row)
    {
        erbium::rule_s rl;
        rl.m_ruleId = std::stoi(row.m_data[0].substr(1));
        rl.m_weight = std::stoi(row.m_data[1]);

        for (int i=6; i<aux; i++)
        {
            erbium::criterion_s ct;
            ct.m_index = i-6;
            if (!row.m_data[i].empty())
                ct.m_value = row.get_value(i);
            else
                ct.m_value = "*";
            rl.m_criteria.insert(ct);
        }

        if (row.m_data[aux+2] == "\"TRUE\"")
            rl.m_content = "999";
        else
            rl.m_content = std::to_string(std::stoi(row.get_value(aux+1))*60 + 
                                          std::stoi(row.get_value(aux+3)));

        m_rules.insert(rl);
    }
}

void erbium::rulePack_s::load_ruleType(const std::string& filename)
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
            aux_criterionDef.m_index       = aux.second.get<criterionid_t>("sequenceNumber");
            aux_criterionDef.m_code        = aux.second.get<std::string>("code");
            aux_criterionDef.m_isMandatory = aux.second.get("isMandatory",false);
            aux_criterionDef.m_supertag    = aux.second.get<std::string>("criterionTypeReference.fileName");
            aux_criterionDef.m_functor     = aux.second.get<unsigned short int>("criterionTypeReference.id");
            aux_criterionDef.m_weight      = aux.second.get<weight_t>("weight", 0);

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

} // namespace erbium