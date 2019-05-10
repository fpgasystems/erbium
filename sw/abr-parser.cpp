// ----------------------------------------------------------------------------
// Copyright (C) 2002-2006 Marcin Kalicinski
//
// Distributed under the Boost Software License, Version 1.0. 
// (See accompanying file LICENSE_1_0.txt or copy at 
// http://www.boost.org/LICENSE_1_0.txt)
//
// For more information, see www.boost.org
// ----------------------------------------------------------------------------

//[abr_dataset_includes
#include <boost/property_tree/ptree.hpp>
#include <boost/property_tree/xml_parser.hpp>
#include <boost/foreach.hpp>
#include <string>
#include <set>
#include <exception>
#include <iostream>
namespace pt = boost::property_tree;

//[abr_dataset_data
struct criterionDefinition_s
{
    int m_index;
    std::string m_code;
    bool m_isMandatory;
    std::string m_supertag;
    int m_weight;
    int m_used;
    bool operator < (const criterionDefinition_s &other) const { return m_index < other.m_index; }
    void print(const std::string &level)
    {
        printf("%s[Criterion] index=%d code=%s isMandatory=%s supertag=%s weight=%d used=%d\n", level.c_str(),
                                     m_index,
                                     m_code.c_str(),
                                     (m_isMandatory)?"true":"false",
                                     m_supertag.c_str(),
                                     m_weight,
                                     m_used);
    }
};
struct ruleType_s
{
    std::string m_organization;
    std::string m_code;
    int m_release;
    std::vector<criterionDefinition_s> m_criterionDefinition;

    void print(const std::string &level)
    {
        printf("%s[RuleType] org=%s app=%s v=%d\n",
            level.c_str(),
            m_organization.c_str(),
            m_code.c_str(),
            m_release);
        for(auto aux : m_criterionDefinition)
            aux.print(level + "\t");
    }

};
struct criterion_s
{
    int m_index;
    std::string m_code;
    std::string m_value;
    bool operator < (const criterion_s &other) const { return m_index < other.m_index; }
    void print(const std::string &level)
    {
        printf("%s[Criterion] id=%d code=%s value=%s\n",
            level.c_str(),
            m_index,
            m_code.c_str(),
            m_value.c_str());
    }
};
struct rule_s
{
    int m_ruleId;
    int m_weight;
    std::set<criterion_s> m_criteria;
    std::string m_content;
    bool operator < (const rule_s &other) const { return m_ruleId < other.m_ruleId; }
    void print(const std::string &level)
    {
        printf("%s[Rule] id=%d weight=%d\n", 
            level.c_str(),
            m_ruleId,
            m_weight);
        for(auto aux : m_criteria)
            aux.print(level + "\t");
    }
};
struct rulePack_s
{
    ruleType_s m_ruleType;
    std::set<rule_s> m_rules;

    bool operator < (const rulePack_s &other) const { return true; }
    void print(const std::string &level)
    {
        m_ruleType.print(level);
        for(auto aux : m_rules)
            aux.print(level + "\t");
    }
};
struct abr_dataset
{
    std::string m_organization;
    std::string m_application;
    std::set<rulePack_s> m_rulePacks;

    void load(const std::string &filename);
    void save(const std::string &filename);

    //[abr_dataset_print
    void print(const std::string &level)
    {
        printf("%sorg: %s\n", level.c_str(), m_organization.c_str());
        printf("%sapp: %s\n", level.c_str(), m_application.c_str());
        for(auto aux : m_rulePacks)
            aux.print(level + "\t");
    }
    //]
};
//]
//[abr_dataset_load
void abr_dataset::load(const std::string &filename)
{
    // Create empty property tree object
    pt::ptree tree;

    // Parse the XML into the property tree.
    pt::read_xml(filename, tree);

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
                            aux_criterionDef.m_weight = aux_b.second.get<int>("criterionWeight.<xmlattr>.weight");
                            aux_ruleType.m_criterionDefinition.push_back(aux_criterionDef);
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
                    aux_rule.m_weight = aux_a.second.get<int>("weight");
                    aux_rule.m_content = aux_a.second.get<std::string>("content");
                    BOOST_FOREACH(boost::property_tree::ptree::value_type &aux_b, aux_a.second.get_child("criteria"))
                    {
                        //printf("[%s]\n", aux_b.first.c_str());

                        criterion_s aux_criterion;
                        aux_criterion.m_index = aux_b.second.get<int>("<xmlattr>.index");
                        aux_criterion.m_code = aux_b.second.get<std::string>("<xmlattr>.code");
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
//]
//[abr_dataset_save
void abr_dataset::save(const std::string &filename)
{
    // TODO
    pt::ptree tree;

    //BOOST_FOREACH(const std::string &name, m_modules)
        //tree.add("debug.modules.module", name);

    // Write property tree to XML file
    pt::write_xml(filename, tree);
}
//]


class CSVRow
{
public:
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
        std::string         line;
        std::getline(str, line);

        std::stringstream   lineStream(line);
        std::string         cell;

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
    std::vector<std::string>    m_data;
};
std::istream& operator>>(std::istream& str, CSVRow& data)
{
    data.readNextRow(str);
    return str;
}

int main()
{
    std::ifstream       file("../../../Documents/amadeus-share/mct_rules.csv");
    CSVRow              row;

    row.readNextRow(file);
    abr_dataset ds;
    rulePack_s rp;
    ds.m_organization = "Amadeus";
    ds.m_application = "MCT";

    rp.m_ruleType.m_organization = "Amadeus";
    rp.m_ruleType.m_code = "MINCT";
    rp.m_ruleType.m_release = 0;

    for (int i=6; i<row.m_data.size()-4; i++)
    {
        criterionDefinition_s cd;
        cd.m_index = i-6;
        cd.m_code = row.m_data[i];
        //cd.m_isMandatory;
        //cd.m_supertag;
        //cd.m_weight;
        //cd.print("");
        rp.m_ruleType.m_criterionDefinition.push_back(cd);
    }

    int aux = row.m_data.size()-4;
    while(file >> row)
    {
        if (row.m_data[aux+2] == "\"TRUE\"")
            continue;

        rule_s rl;
        rl.m_ruleId = std::stoi(row.m_data[0].substr(1));
        rl.m_weight = std::stoi(row.m_data[1]);
        for (int i=6; i<aux; i++)
        {
            if(!row.m_data[i].empty())
            {
                criterion_s ct;
                ct.m_index = i-6;
                ct.m_code = rp.m_ruleType.m_criterionDefinition[i-6].m_code;
                ct.m_value = row.get_value(i);

                rp.m_ruleType.m_criterionDefinition[i-6].m_used++;
                rl.m_criteria.insert(ct);
            }
        }
        //if (row.m_data[aux+2] == "\"FALSE\"")
        //{
            rl.m_content = std::to_string(std::stoi(row.get_value(aux+1))*60 + 
                                          std::stoi(row.get_value(aux+3)));
        //}
        //rl.print("");
        rp.m_rules.insert(rl);
    }

    rp.m_ruleType.print("");
    std::cout << rp.m_rules.size() << " rules loaded" << std::endl;
    ds.m_rulePacks.insert(rp);

    return 0;

    try
    {
        abr_dataset ds;
        ds.load("../../../Documents/serial-NGI-biggest/test.xml");
        ds.print("");
        //ds.save("abr_dataset_out.xml");
    }
    catch (std::exception &e)
    {
        std::cout << "Error: " << e.what() << "\n";
    }

    return 0;
}