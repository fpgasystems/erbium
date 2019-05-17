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
#include <chrono>
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
    void print(const std::string &level) const
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

    void print(const std::string &level) const
    {
        printf("%s[RuleType] org=%s app=%s v=%d\n",
            level.c_str(),
            m_organization.c_str(),
            m_code.c_str(),
            m_release);
        for(auto& aux : m_criterionDefinition)
            aux.print(level + "\t");
    }

};
struct criterion_s
{
    int m_index;
    std::string m_code;
    std::string m_value;
    bool operator < (const criterion_s &other) const { return m_index < other.m_index; }
    void print(const std::string &level) const
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
    void print(const std::string &level) const
    {
        printf("%s[Rule] id=%d weight=%d\n", 
            level.c_str(),
            m_ruleId,
            m_weight);
        for(auto& aux : m_criteria)
            aux.print(level + "\t");
    }
};
struct rulePack_s
{
    ruleType_s m_ruleType;
    std::set<rule_s> m_rules;

    bool operator < (const rulePack_s &other) const { return true; }
    void print(const std::string &level) const
    {
        m_ruleType.print(level);
        for(auto& aux : m_rules)
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
    void print(const std::string &level) const
    {
        printf("%sorg: %s\n", level.c_str(), m_organization.c_str());
        printf("%sapp: %s\n", level.c_str(), m_application.c_str());
        for(auto& aux : m_rulePacks)
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

    std::cout << "# LOAD" << std::endl;
    auto start = std::chrono::high_resolution_clock::now();
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
        cd.m_isMandatory = false;
        cd.m_supertag = "";
        cd.m_weight = 0;
        cd.m_used = 0;
        rp.m_ruleType.m_criterionDefinition.push_back(cd);
    }

    int aux = row.m_data.size()-4;
    while(file >> row)
    {
        if (row.m_data[aux+2] == "\"TRUE\"")
            continue;

        // NOT PRODUCTION
        // JUST TO FILTER WHILE IN DEV
        //if (row.m_data[8] != "\"CDG\"" && row.m_data[9] != "\"CDG\"")
        //    continue;
        //if (row.m_data[aux+3] != "\"35\"")
        //    continue;

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
    //rp.m_ruleType.print("");
    //ds.m_rulePacks.insert(rp);

    auto finish = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> elapsed = finish - start;
    std::cout << rp.m_rules.size() << " rules loaded" << std::endl;
    std::cout << "# LOAD COMPLETED in " << elapsed.count() << " s\n";

    ////////////////////////////////////////////////////////////////////////////////////////

    //####### DICTIONNARY
    start = std::chrono::high_resolution_clock::now();
    std::cout << "# DICTIONNARY" << std::endl;
    
    std::map<uint, std::map<std::string, uint>> dictionnary; // per criteira -> per value -> ID
    std::map<std::string, uint> contents;                    // per value -> ID
    //for(auto& criterium : rp.m_ruleType.m_criterionDefinition)
    //{
    //    std::map<std::string, uint> dic;
    //    dictionnary.push_back(dic);
    //}

    for (auto& rule : rp.m_rules)
    {
        for (auto& aux : rule.m_criteria)
            dictionnary[aux.m_index][aux.m_value]=0;
        contents[rule.m_content] = 0;
    }
    dictionnary[rp.m_ruleType.m_criterionDefinition.size()] = contents;

    uint key;
    for(auto& aux : dictionnary)
    {
        key = 0;
        for(auto& x : aux.second)
            x.second = key++;
    }

    // PRINT
    // for(auto& aux : dictionnary)
    // {
    //     for(auto& x : aux.second)
    //         std::cout << x.first << "," << x.second << std::endl;
    // }
    finish = std::chrono::high_resolution_clock::now();
    elapsed = finish - start;

    // Stats    
    #ifdef _DEBUG
    #endif

    std::cout << "# DICTIONNARY COMPLETED in " << elapsed.count() << " s\n";

    //####### GRAPH
    std::cout << "# GRAPH" << std::endl;
    start = std::chrono::high_resolution_clock::now();

    std::map<std::string, uint> netSI; // from node_path to node_id
    std::map<std::string, uint> netSI_bwd; // from node_path_bwd to node_id
    std::map<uint, std::string> netIS; // from node_id to node_path
    std::map<uint, std::string> netIS_bwd; // from node_id to node_path
    std::vector<std::string> labels;   // from node_id to node_value
    std::map<uint, std::set<uint>> parents_of; // from node_id to parents of it (parent node_id)
    std::map<uint, std::map<uint, std::set<uint>>> vertexes; // per level -> per value -> list of nodes

    labels.push_back("o");
    boost::adjacency_list <> g(1);

    uint stats_bwd = 0;
    uint stats_fwd = 0;

    uint node_to_use;
    uint prev_id;
    std::string path_fwd;
    std::string path_bwd;
    std::map<uint, std::string> path_bwd_db;
    for (auto& rule : rp.m_rules)
    {
        path_fwd = "";
        path_bwd_db.clear();
        prev_id = 0;

        // build path_bwd
        for (auto& criterium : rule.m_criteria)
        {
            for (uint i=0; i<=criterium.m_index; ++i)
                path_bwd_db[i] = path_bwd_db[i] + "_" + criterium.m_value;
        }
        for (uint i=0; i<=rule.m_criteria.size(); ++i)
            path_bwd_db[i] = path_bwd_db[i] + "_" + rule.m_content;

        for (auto& criterium : rule.m_criteria)
        {
            path_fwd = criterium.m_value + "_" + path_fwd;
            path_bwd = path_bwd_db[criterium.m_index];

            // if one of the paths already exists, use it
            // if none, them create it
            node_to_use = 0;
            if (netSI[path_fwd] == 0 && netSI_bwd[path_bwd] == 0)
            {
                node_to_use = add_vertex(g);
                netSI_bwd[path_bwd] = node_to_use;
                netIS_bwd[netSI_bwd[path_bwd]] = path_bwd;
                netSI[path_fwd] = node_to_use;
                netIS[netSI[path_fwd]] = path_fwd;
                labels.push_back(criterium.m_value);
                vertexes[criterium.m_index][dictionnary[criterium.m_index][criterium.m_value]].insert(netSI[path_fwd]);
            }
            else if (netSI[path_fwd] != 0)
            {
                // use forward node
                node_to_use = netSI[path_fwd];
                stats_fwd++;
            }
            else
            {
                // use backward node
                node_to_use = netSI_bwd[path_bwd];
                stats_bwd++;// rule.m_criteria.size() - criterium.m_index;
            }
            boost::remove_edge(prev_id, node_to_use, g);
            boost::add_edge(prev_id, node_to_use, g);
            parents_of[node_to_use].insert(prev_id);
            prev_id = node_to_use;
            //std::cout << "net[" << path_fwd << "]=" << net[path_fwd] << std::endl;
        }
        // Add content
        if (netSI[rule.m_content] == 0)
        {
            // It does not exist
            netSI[rule.m_content] = add_vertex(g);
            netIS[netSI[rule.m_content]] = rule.m_content;
            labels.push_back(rule.m_content);
            vertexes[rule.m_criteria.size()][dictionnary[rule.m_criteria.size()][rule.m_content]].insert(netSI[rule.m_content]);
        }
        boost::remove_edge(prev_id, netSI[rule.m_content], g);
        boost::add_edge(prev_id, netSI[rule.m_content], g);
        parents_of[netSI[rule.m_content]].insert(prev_id);
    }
    finish = std::chrono::high_resolution_clock::now();
    elapsed = finish - start;
    
    #ifdef _DEBUG
    for(auto& level : vertexes)
        std::cout << "level " << level.first << " has " << level.second.size() << " different values" << std::endl;
    #endif

    // Stats
    std::cout << "total number of nodes: " << boost::num_vertices(g) << std::endl;
    std::cout << "total number of transitions: " << boost::num_edges(g) << std::endl;
    std::cout << "total number of fwd merges: " << stats_fwd << std::endl;
    std::cout << "total number of bwd merges: " << stats_bwd << std::endl;
    std::cout << "# GRAPH COMPLETED in " << elapsed.count() << " s\n";

    ////// OPTIMISATIONS
    std::cout << "# OPTIMISATIONS" << std::endl;
    // stats
    uint merged = 0;
    uint aux_v;

    std::set<std::pair<uint, uint>> vertexes_to_remove;
    boost::graph_traits < boost::adjacency_list <> >::adjacency_iterator ai, a_end;
    boost::graph_traits < boost::adjacency_list <> >::adjacency_iterator bi, b_end;
    boost::graph_traits < boost::adjacency_list <> >::adjacency_iterator ci, c_end;
    
    // iterates all the levels (one level per criterium)
    for (auto level = ++(vertexes.rbegin()); level != vertexes.rend(); ++level)
    {
        std::cout << "level " << (level->first);
        start = std::chrono::high_resolution_clock::now();
        merged = 0;
        // iterates all the values
        for (auto value_id : vertexes[level->first])
        {
            // iterates all the nodes with this value within this level
            for (auto vertex = vertexes[level->first][value_id.first].rbegin(); vertex != vertexes[level->first][value_id.first].rend(); ++vertex)
            {
                // skip if already merged
                if (labels[*vertex] == "")
                    continue;

                boost::tie(ci, c_end) = adjacent_vertices(*vertex, g);
                // compare to all the other nodes with same value (within same level)
                for (auto aux = std::next(vertex); aux != vertexes[level->first][value_id.first].rend(); ++aux)
                //for (auto& aux : vertexes[level->first][value_id.first])
                {
                    aux_v = *aux;

                    // skip if already merged
                    if (labels[aux_v] == "")
                        continue;

                    bool equal = true;

                    // Check if both nodes point to the same nodes
                    boost::tie(ai, a_end) = boost::tie(ci, c_end);
                    boost::tie(bi, b_end) = adjacent_vertices(aux_v, g);

                    for (; ai != a_end && equal; ++ai, ++bi)
                    {
                        if (*ai != *bi)
                            equal = false;
                    }
                    if (ai != a_end || bi != b_end)
                        equal = false;

                    if (equal)
                    {
                        // redirect all the in edges of aux to vertex
                        for (auto cr : parents_of[aux_v])
                        {
                            #ifdef _DEBUG
                            std::cout << "replacing edge [" << cr << "]-[" << aux_v;
                            std::cout << "] to [" << cr << "]-[" << *vertex << "]" << std::endl;
                            std::cout << "[" << cr << "] " << netIS[cr] << " & " << netIS_bwd[cr] << std::endl;
                            #endif
                            boost::remove_edge(cr, aux_v, g);
                            boost::add_edge(cr, *vertex, g);
                        }
                        parents_of[aux_v].clear();

                        #ifdef _DEBUG
                        std::cout << "[" << aux_v << "] " << netIS[aux_v] << " & " << netIS_bwd[aux_v] << std::endl;
                        std::cout << "[" << *vertex << "] " << netIS[*vertex] << " & " << netIS_bwd[*vertex] << std::endl;
                        boost::tie(bi, b_end) = boost::adjacent_vertices(aux_v, g);
                        for (; bi != b_end; ++bi)
                            std::cout << "pointing to [" << *bi << "] " << netIS[*bi] << " & " << netIS_bwd[*bi] << std::endl;
                        #endif

                        vertexes_to_remove.insert(std::make_pair(aux_v, level->first));
                        labels[aux_v] = "";
                        merged++;
                        //std::cout << std::endl;
                        // rename vertex netIS/netSI ?
                    }
                }
            }
        }
        finish = std::chrono::high_resolution_clock::now();
        elapsed = finish - start;
        //#ifdef _DEBUG
        std::cout << " merged " << merged << " nodes in " << elapsed.count() << " s\n";
        //#endif
    }

    // effectively remove obsolete vertexes from the graph
    std::cout << "deleting " << vertexes_to_remove.size() << " nodes" << std::endl << std::endl;
    start = std::chrono::high_resolution_clock::now();
    for (auto aux = vertexes_to_remove.rbegin(); aux != vertexes_to_remove.rend(); ++aux)
    {
        //std::cout << "removing [" << aux->first << "] " << netIS[aux->first] << " from level " << aux->second << std::endl;

        // this is not working!
        //vertexes[aux->second][dictionnary[aux->second][labels[aux->first]]].erase(aux->first);

        netSI.erase(netIS[aux->first]);
        netIS.erase(aux->first);
        labels.erase(labels.begin() + aux->first);

        boost::clear_vertex(aux->first, g);
        boost::remove_vertex(aux->first, g);
    }
    finish = std::chrono::high_resolution_clock::now();
    elapsed = finish - start;
    std::cout << "Elapsed time: " << elapsed.count() << " s\n";

    // print final state
    #ifdef _DEBUG
    for (auto& level : vertexes)
    {
        aux=0;
        for (auto& value : level.second)
            aux += value.second.size();
        std::cout << "level " << level.first << " has " << aux << " nodes" << std::endl;
    }
    #endif
    std::cout << "total number of nodes: " << boost::num_vertices(g) << std::endl;
    std::cout << "total number of transitions: " << boost::num_edges(g) << std::endl;
    
    // save file
    std::ofstream dot_file("automaton.dot");
    boost::write_graphviz(dot_file, g, boost::make_label_writer(&labels[0]));

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