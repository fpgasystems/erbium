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
#include <boost/graph/adjacency_list.hpp>
#include <boost/graph/graphviz.hpp>
#include <boost/property_tree/ptree.hpp>
#include <boost/property_tree/xml_parser.hpp>
#include <boost/foreach.hpp>
#include <string>
#include <set>
#include <map>
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
    //std::ifstream       file("../data/demo_01.csv");
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
            else
            {
                // IF NO VALUE, USE "*"
                criterion_s ct;
                ct.m_index = i-6;
                ct.m_code = rp.m_ruleType.m_criterionDefinition[i-6].m_code;
                ct.m_value = "*";
                rl.m_criteria.insert(ct);
            }
        }
        rl.m_content = std::to_string(std::stoi(row.get_value(aux+1))*60 + 
                                      std::stoi(row.get_value(aux+3)));
        rp.m_rules.insert(rl);
    }

    rp.m_ruleType.print("");
    std::cout << rp.m_rules.size() << " rules loaded" << std::endl;
    //ds.m_rulePacks.insert(rp);

    ////////////////////////////////////////////////////////////////////////////////////////

    /* //####### DICTIONNARY
    std::vector<std::map<std::string, uint>> dictionnary; // per criteira -> per value -> ID
    std::map<std::string, uint> contents;                 // per value -> ID
    for(auto criterium : rp.m_ruleType.m_criterionDefinition)
    {
        std::map<std::string, uint> dic;
        dictionnary.push_back(dic);
    }

    for (auto rule : rp.m_rules)
    {
        for (auto aux : rule.m_criteria)
            dictionnary[aux.m_index][aux.m_value]=0;
        contents[rule.m_content] = 0;
    }
    dictionnary.push_back(contents);

    uint key;
    for(auto& aux : dictionnary)
    {
        key = 0;
        for(auto& x : aux)
            x.second = key++;
    }

    // PRINT
    for(auto& aux : dictionnary)
    {
        for(auto& x : aux)
            std::cout << x.first << "," << x.second << std::endl;
    }*/

    //####### GRAPH
    std::map<std::string, uint> netSI; // from node_path to node_id
    std::map<uint, std::string> netIS; // from node_id to node_path
    std::vector<std::string> labels;   // from node_id to node_value
    std::map<uint, std::set<uint>> parents_of; // from node_id to parents of it (parent node_id)
    //std::map<uint, std::set<uint>> vertexes; // per level -> list of nodes
    std::map<uint, std::map<uint, std::set<uint>>> v_perLevel_perValue; // per level -> per value -> list of nodes

    std::map<uint, std::map<std::string, uint>> dictionnary; // per level -> per value -> value_id

    labels.push_back("o");
    boost::adjacency_list <> g(1);
    for (auto rule : rp.m_rules)
    {
        std::string node_path = "";
        uint prev_id = 0;
        for (auto criterium : rule.m_criteria)
        {
            // DICTIONNARY
            if (dictionnary[criterium.m_index][criterium.m_value] == 0)
                dictionnary[criterium.m_index][criterium.m_value] = dictionnary[criterium.m_index].size();

            node_path = criterium.m_value + "_" + node_path;

            if (netSI[node_path] == 0)
            {
                netSI[node_path] = add_vertex(g);
                netIS[netSI[node_path]] = node_path;
                labels.push_back(criterium.m_value);
                //vertexes[criterium.m_index].insert(netSI[node_path]);
                v_perLevel_perValue[criterium.m_index][dictionnary[criterium.m_index][criterium.m_value]].insert(netSI[node_path]);
            }
            remove_edge(prev_id, netSI[node_path], g);
            add_edge(prev_id, netSI[node_path], g);
            parents_of[netSI[node_path]].insert(prev_id);
            prev_id = netSI[node_path];
            //std::cout << "net[" << node_path << "]=" << net[node_path] << std::endl;
        }
        // Add content
        if (netSI[rule.m_content] == 0)
        {
            // It does not exist
            netSI[rule.m_content] = add_vertex(g);
            netIS[netSI[rule.m_content]] = rule.m_content;
            labels.push_back(rule.m_content);
        }
        remove_edge(prev_id, netSI[rule.m_content], g);
        add_edge(prev_id, netSI[rule.m_content], g);
        parents_of[netSI[rule.m_content]].insert(prev_id);
    }

    ////// OPTIMISATIONS

    std::set<std::pair<uint, uint>> vertexes_to_remove;
    boost::graph_traits < boost::adjacency_list <> >::adjacency_iterator ai, a_end;
    boost::graph_traits < boost::adjacency_list <> >::adjacency_iterator bi, b_end;
    
    // iterates all the levels (one level per criterium)
    for (auto level = v_perLevel_perValue.rbegin(); level != v_perLevel_perValue.rend(); ++level)
    {
        std::cout << "level " << level->first << std::endl;
        // iterates all the values
        for (auto value_id : v_perLevel_perValue[level->first])
        {
            // iterates all the nodes with this value within this level
            for (auto vertex = v_perLevel_perValue[level->first][value_id.first].begin(); vertex != v_perLevel_perValue[level->first][value_id.first].end(); ++vertex)
            {
                // skip if already merged
                if (labels[*vertex] == "")
                    continue;

                // compare to all the other nodes with same value (within same level)
                for (auto aux = std::next(vertex); aux != v_perLevel_perValue[level->first][value_id.first].end(); ++aux)
                {
                    // skip if already merged
                    if (labels[*aux] == "")
                        continue;

                    bool equal = true;

                    // Check if both nodes point to the same nodes
                    boost::tie(ai, a_end) = adjacent_vertices(*vertex, g);
                    boost::tie(bi, b_end) = adjacent_vertices(*aux, g);
                    for (; ai != a_end && bi != b_end && equal; ++ai, ++bi)
                    {
                        if (*ai != *bi)
                            equal = false;
                    }
                    if (ai != a_end || bi != b_end)
                        equal = false;

                    if (equal)
                    {
                        // redirect all the in edges of aux to vertex
                        for (auto cr : parents_of[*aux])
                        {
                            // std::cout << "replacing edge [" << cr << "]-[" << *aux;
                            // std::cout << "] to [" << cr << "]-[" << *vertex << "]" << std::endl;
                            remove_edge(cr, *aux, g);
                            add_edge(cr, *vertex, g);
                            parents_of[*aux].erase(cr);
                        }

                        vertexes_to_remove.insert(std::make_pair(*aux, level->first));
                        labels[*aux] = "";
                        // rename vertex netIS/netSI ?

                        // DEBUG
                        //boost::tie(ai, a_end) = adjacent_vertices(*vertex, g);
                        //boost::tie(bi, b_end) = adjacent_vertices(*aux, g);
                        //for (; ai != a_end && bi != b_end; ++ai, ++bi)
                        //    std::cout << "they point to " << *ai << std::endl;
                        //std::cout << "VERTEX=" << *vertex << " and AUX=" << *aux << " are " << labels[*vertex] << std::endl;
                    }
                }
            }
        }
    }
    /*
    for (auto level = vertexes.rbegin(); level != vertexes.rend(); ++level)
    {
        // iterates all the nodes within this criterium
        for (auto vertex = level->second.begin(); std::next(vertex) != level->second.end(); ++vertex)
        {
            if (labels[*vertex] == "")
                continue;
            
            // iterates all the other nodes with same value within this criterium
            for (auto aux : v_perLevel_perValue[level->first][dictionnary[level->first][labels[*vertex]]])
            {
                if (aux != *vertex)
                {
                    bool equal = true;

                    // Check if both nodes point to the same nodes
                    boost::tie(ai, a_end) = adjacent_vertices(*vertex, g);
                    boost::tie(bi, b_end) = adjacent_vertices(aux, g);
                    for (; ai != a_end && bi != b_end && equal; ++ai, ++bi)
                    {
                        if (*ai != *bi)
                            equal = false;
                    }
                    if (ai != a_end || bi != b_end)
                        equal = false;

                    if (equal)
                    {
                        // redirect all the in edges of aux to vertex
                        for (auto cr : parents_of[aux])
                        {
                            // std::cout << "replacing edge [" << cr << "]-[" << *aux;
                            // std::cout << "] to [" << cr << "]-[" << *vertex << "]" << std::endl;
                            remove_edge(cr, aux, g);
                            add_edge(cr, *vertex, g);
                            parents_of[aux].erase(cr);
                        }

                        vertexes_to_remove.insert(std::make_pair(aux, level->first));
                        labels[aux] = "";
                        // rename vertex netIS/netSI ?

                        // DEBUG
                        //boost::tie(ai, a_end) = adjacent_vertices(*vertex, g);
                        //boost::tie(bi, b_end) = adjacent_vertices(*aux, g);
                        //for (; ai != a_end && bi != b_end; ++ai, ++bi)
                        //    std::cout << "they point to " << *ai << std::endl;
                        //std::cout << "VERTEX=" << *vertex << " and AUX=" << *aux << " are " << labels[*vertex] << std::endl;
                    }
                }
            }
            
//            for (auto aux = std::next(vertex); aux != level->second.end(); ++aux)
//            {
//                // Check if both nodes have the same value
//                if (labels[*aux] == labels[*vertex] && labels[*vertex] != "")
//                {
//                    bool equal = true;
//
//                    // Check if both nodes point to the same nodes
//                    boost::tie(ai, a_end) = adjacent_vertices(*vertex, g);
//                    boost::tie(bi, b_end) = adjacent_vertices(*aux, g);
//                    for (; ai != a_end && bi != b_end && equal; ++ai, ++bi)
//                    {
//                        if (*ai != *bi)
//                            equal = false;
//                    }
//                    if (ai != a_end || bi != b_end)
//                        equal = false;
//
//                    if (equal)
//                    {
//                        // redirect all the in edges of aux to vertex
//                        for (auto cr : parents_of[*aux])
//                        {
//                            // std::cout << "replacing edge [" << cr << "]-[" << *aux;
//                            // std::cout << "] to [" << cr << "]-[" << *vertex << "]" << std::endl;
//                            remove_edge(cr, *aux, g);
//                            add_edge(cr, *vertex, g);
//                            parents_of[*aux].erase(cr);
//                        }
//
//                        vertexes_to_remove.insert(std::make_pair(*aux, level->first));
//                        labels[*aux] = "";
//                        // rename vertex netIS/netSI ?
//
//                        // DEBUG
//                        //boost::tie(ai, a_end) = adjacent_vertices(*vertex, g);
//                        //boost::tie(bi, b_end) = adjacent_vertices(*aux, g);
//                        //for (; ai != a_end && bi != b_end; ++ai, ++bi)
//                        //    std::cout << "they point to " << *ai << std::endl;
//                        //std::cout << "VERTEX=" << *vertex << " and AUX=" << *aux << " are " << labels[*vertex] << std::endl;
//                    }
//                }
//            }
        }
    }*/

    // effectively remove obsolete vertexes from the graph
    //for (auto aux : vertexes_to_remove)
    for (auto aux = vertexes_to_remove.rbegin(); aux != vertexes_to_remove.rend(); ++aux)
    {
        // std::cout << "removing [" << aux->first << "] " << netIS[aux->first] << " from level " << aux->second << std::endl;
        //vertexes[aux->second].erase(aux->first);
        v_perLevel_perValue[aux->second][dictionnary[aux->second][labels[aux->first]]].erase(aux->first);
        netSI.erase(netIS[aux->first]);
        netIS.erase(aux->first);
        labels.erase(labels.begin() + aux->first);
        remove_vertex(aux->first, g);
    }

    // vertex with the same value pointing to exactly the same vertex can be merged
    //  so check all vertices pointing to them

    //for(auto it = netIS.begin(); it != netIS.end(); ++it)
    //    labels.push_back(it->second);
    
    boost::write_graphviz(std::cout, g, boost::make_label_writer(&labels[0]));

    // boost::graph_traits < boost::adjacency_list <> >::vertex_iterator i, end;
    // boost::graph_traits < boost::adjacency_list <> >::adjacency_iterator ai, a_end;
    // boost::property_map < boost::adjacency_list <>, boost::vertex_index_t >::type index_map = get(boost::vertex_index, g);
    // for (boost::tie(i, end) = vertices(g); i != end; ++i)
    // {
    //     std::cout << *i;
    //     boost::tie(ai, a_end) = adjacent_vertices(*i, g);
    //     if (ai == a_end)
    //         std::cout << " has no children";
    //     else
    //         std::cout << " is the parent of ";
    //     
    //     for (; ai != a_end; ++ai)
    //     {
    //         std::cout << *ai;
    //         if (boost::next(ai) != a_end)
    //             std::cout << ", ";
    //     }
    //     std::cout << std::endl;
    // }

    ////////////////////////////////////////////////////////////////////////////////////////

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