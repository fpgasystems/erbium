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

//#define _DEBUG true

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



struct vertex_info { 
    uint level;
    std::string label;
    std::string path;
    std::set<uint> parents;
};
typedef boost::adjacency_list<boost::vecS, boost::vecS, boost::directedS, vertex_info> graph_t;


int main()
{
    std::ifstream       file("../../../Documents/amadeus-share/mct_rules.csv");
    //std::ifstream       file("../data/demo_02.csv");
    //std::ifstream       file("../data/demo_01.csv");

    ////////////////////////////////////////////////////////////////////////////////////////
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
        // NOT PRODUCTION
        // JUST TO FILTER WHILE IN DEV
        //if (row.m_data[8] != "\"ZRH\"" && row.m_data[9] != "\"ZRH\"")
        //    continue;
        //if (row.m_data[8] != "\"CDG\"" && row.m_data[9] != "\"CDG\"")
        //    continue;
        //if (row.m_data[8] != "\"GRU\"" && row.m_data[9] != "\"GRU\"")
        //    continue;
        //if (row.m_data[8] != "\"ZRH\"" && row.m_data[9] != "\"ZRH\"" && row.m_data[8] != "\"CDG\"" && row.m_data[9] != "\"CDG\"" && row.m_data[8] != "\"GRU\"" && row.m_data[9] != "\"GRU\"")
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
        if (row.m_data[aux+2] == "\"TRUE\"")
            rl.m_content = "999";
        else
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
    std::vector<std::pair<uint, uint>> ordered;              // list of pair < (#diff values) & (level)>

    // create it
    for (auto& rule : rp.m_rules)
    {
        for (auto& aux : rule.m_criteria)
            dictionnary[aux.m_index][aux.m_value]=0;
        contents[rule.m_content] = 0;
    }

    // indexes
    uint key;
    for(auto& aux : dictionnary)
    {
        key = 0;
        for(auto& x : aux.second)
            x.second = key++;
        ordered.push_back(std::pair<uint, uint>(aux.second.size(), aux.first));
    }
    sort(ordered.begin(), ordered.end());
    dictionnary[rp.m_ruleType.m_criterionDefinition.size()] = contents;

    key = 0;
    for (auto& aux : ordered)
    {
        std::cout << "[" << key << "] " << rp.m_ruleType.m_criterionDefinition[aux.second].m_code << " #" << aux.first << std::endl;
        key++;
    }

    finish = std::chrono::high_resolution_clock::now();
    elapsed = finish - start;
    std::cout << "# DICTIONNARY COMPLETED in " << elapsed.count() << " s\n";

    ////////////////////////////////////////////////////////////////////////////////////////

    //####### GRAPH
    std::cout << "# GRAPH" << std::endl;
    start = std::chrono::high_resolution_clock::now();

    std::map<std::string, uint> netSI; // from node_path to node_id
    std::map<uint, std::map<uint, std::set<uint>>> vertexes; // per level -> per value -> list of nodes

    graph_t g(1);

    uint stats_fwd = 0;
    uint node_to_use;
    uint prev_id;
    uint level = 0;
    std::string path_fwd;

    for (auto& rule : rp.m_rules)
    {
        path_fwd = "";
        prev_id = 0;

        level = 0;
        for (auto& ord : ordered)
        {
            criterion_s criterium = *std::next(rule.m_criteria.begin(), ord.second);

            path_fwd = criterium.m_value + "_" + path_fwd;

            node_to_use = 0;
            if (netSI[path_fwd] == 0)
            {
                // new path
                node_to_use = add_vertex(g);
                netSI[path_fwd] = node_to_use;
                g[node_to_use].label = criterium.m_value;
                g[node_to_use].level = level;
                g[node_to_use].path = path_fwd;
                vertexes[level][dictionnary[criterium.m_index][criterium.m_value]].insert(node_to_use);
            }
            else
            {
                // use existing path
                node_to_use = netSI[path_fwd];
                stats_fwd++;
            }
            boost::remove_edge(prev_id, node_to_use, g);
            boost::add_edge(prev_id, node_to_use, g);
            g[node_to_use].parents.insert(prev_id);
            prev_id = node_to_use;
            level++;
        }
        // Add content
        if (netSI[rule.m_content] == 0)
        {
            // It does not exist
            node_to_use = add_vertex(g);
            netSI[rule.m_content] = node_to_use;
            g[node_to_use].label = rule.m_content;
            g[node_to_use].level = level;
            g[node_to_use].path  = rule.m_content;
            vertexes[level][dictionnary[rule.m_criteria.size()][rule.m_content]].insert(node_to_use);
        }
        else
            node_to_use = netSI[rule.m_content];
        boost::remove_edge(prev_id, node_to_use, g);
        boost::add_edge(prev_id, node_to_use, g);
        g[node_to_use].parents.insert(prev_id);
    }
    finish = std::chrono::high_resolution_clock::now();
    elapsed = finish - start;
    #ifdef _DEBUG
    for (auto& level : vertexes)
    {
        aux=0;
        for (auto& value : level.second)
            aux += value.second.size();
        std::cout << "level " << level.first << " has " << aux << " nodes" << std::endl;
    }
    #endif
    // Stats
    std::cout << "total number of nodes: " << boost::num_vertices(g) << std::endl;
    std::cout << "total number of transitions: " << boost::num_edges(g) << std::endl;
    std::cout << "total number of fwd merges: " << stats_fwd << std::endl;
    std::cout << "# GRAPH COMPLETED in " << elapsed.count() << " s\n";

    ////////////////////////////////////////////////////////////////////////////////////////

    ////// OPTIMISATIONS
    std::cout << "# OPTIMISATIONS" << std::endl;
    start = std::chrono::high_resolution_clock::now();
    // stats
    uint merged_total = 0;
    uint merged_level = 0;

    boost::graph_traits < graph_t >::adjacency_iterator ai, a_end;
    boost::graph_traits < graph_t >::adjacency_iterator bi, b_end;
    boost::graph_traits < graph_t >::adjacency_iterator ci, c_end;
    
    // iterates all the levels (one level per criterium)
    for (auto level = ++(vertexes.rbegin()); level != vertexes.rend(); ++level)
    {
        #ifdef _DEBUG
        std::cout << "level " << (level->first);
        start = std::chrono::high_resolution_clock::now();
        #endif
        merged_level = 0;
        // iterates all the values
        for (auto value_id : vertexes[level->first])
        {
            // TODO: check why using the "auto" form misses some merges! (227 instead of 234)
            // iterates all the nodes with this value within this level
            for (auto vertex = vertexes[level->first][value_id.first].rbegin(); vertex != vertexes[level->first][value_id.first].rend(); ++vertex)
            //for (auto& vertex : vertexes[level->first][value_id.first])
            {
                // skip if already merged
                if (g[*vertex].label == "")
                    continue;

                boost::tie(ci, c_end) = adjacent_vertices(*vertex, g);
                // for (auto& aux : vertexes[level->first][value_id.first])
                // compare to all the other nodes with same value (within same level)
                for (auto aux = std::next(vertex); aux != vertexes[level->first][value_id.first].rend(); ++aux)
                //for (auto& aux : vertexes[level->first][value_id.first])
                {
                    //if (aux <= vertex)
                    //    continue;

                    // skip if already merged
                    if (g[*aux].label == "")
                        continue;

                    bool equal = true;

                    // Check if both nodes point to the same nodes
                    boost::tie(ai, a_end) = boost::tie(ci, c_end);
                    boost::tie(bi, b_end) = adjacent_vertices(*aux, g);

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
                        for (auto cr : g[*aux].parents)
                        {
                            boost::remove_edge(cr, *aux, g);
                            boost::add_edge(cr, *vertex, g);
                        }
                        g[*aux].parents.clear();
                        g[*aux].label = "";
                        merged_level++;
                        merged_total++;
                    }
                }
            }
        }
        #ifdef _DEBUG
        finish = std::chrono::high_resolution_clock::now();
        elapsed = finish - start;
        std::cout << " merged " << merged_level << " nodes in " << elapsed.count() << " s\n";
        #endif
    }
    finish = std::chrono::high_resolution_clock::now();
    elapsed = finish - start;
    std::cout << "# OPTIMISATIONS COMPLETED in " << elapsed.count() << " s\n";

    ////////////////////////////////////////////////////////////////////////////////////////

    ////// DELETION
    std::cout << "# DELETING" << std::endl;
    std::cout << "deleting " << merged_total << " nodes" << std::endl;
    start = std::chrono::high_resolution_clock::now();

    // effectively remove obsolete vertexes from the graph
    graph_t final_one(1);
    std::vector<uint> mapa;
    std::map<uint, uint> mapaa;

    final_one[0].label="o"; // origin
    boost::graph_traits < graph_t >::vertex_iterator vi, vi_end;
    for (boost::tie(vi, vi_end) = vertices(g); vi != vi_end; ++vi)
    {
        if (g[*vi].parents.size() != 0)
        {
            mapa.push_back(*vi);
            mapaa[*vi] = boost::add_vertex(final_one);
            final_one[mapaa[*vi]] = g[*vi];
        }
    }
    for(boost::tie(bi, b_end) = adjacent_vertices(0, g); bi != b_end; ++bi)
        boost::add_edge(0, mapaa[*bi], final_one);
    for (auto itr : mapa)
    {
        for(boost::tie(bi, b_end) = adjacent_vertices(itr, g); bi != b_end; ++bi)
            boost::add_edge(mapaa[itr], mapaa[*bi], final_one);

    }
    g = final_one;
    finish = std::chrono::high_resolution_clock::now();
    elapsed = finish - start;
    std::cout << "# DELETING COMPLETED in " << elapsed.count() << " s\n";

    ////////////////////////////////////////////////////////////////////////////////////////

    // FINAL STATS
    uint n_nodes;
    uint n_edges;
    uint n_edges_max = 0;
    for (auto& level : vertexes)
    {
        n_nodes = 0;
        n_edges = 0;
        n_edges_max = 0;
        for (auto& value : vertexes[level.first])
        {
            for (auto& vert : vertexes[level.first][value.first])
            {
                if(g[mapaa[vert]].parents.size() != 0)
                {
                    aux = out_degree(mapaa[vert], g);
                    n_nodes++;
                    n_edges += aux;
                    n_edges_max = (aux > n_edges_max) ? aux : n_edges_max;
                }
            }
        }
        std::cout << "level " << level.first << ": " << n_nodes << " nodes; " << n_edges << " edges; " << n_edges_max << " max edges\n";
    }

    std::cout << "total number of nodes: " << boost::num_vertices(g) << std::endl;
    std::cout << "total number of transitions: " << boost::num_edges(g) << std::endl;

    ////////////////////////////////////////////////////////////////////////////////////////

    // EXPORT FILE
    std::ofstream dot_file("automaton.dot");
    boost::write_graphviz(dot_file, g, boost::make_label_writer(get(&vertex_info::label, g)));

    ////////////////////////////////////////////////////////////////////////////////////////

    return 0;
}

/*
typedef adjacency_list<vecS, vecS, bidirectionalS, 
    no_property, property<edge_index_t, std::size_t> > Graph;

  const int num_vertices = 9;
  Graph G(num_vertices);

  int capacity_array[] = { 10, 20, 20, 20, 40, 40, 20, 20, 20, 10 };
  int flow_array[] = { 8, 12, 12, 12, 12, 12, 16, 16, 16, 8 };

  // Add edges to the graph, and assign each edge an ID number.
  add_edge(0, 1, 0, G);
  // ...

  typedef graph_traits<Graph>::edge_descriptor Edge;
  typedef property_map<Graph, edge_index_t>::type EdgeID_Map;
  EdgeID_Map edge_id = get(edge_index, G);

  random_access_iterator_property_map
    <int*, int, int&, EdgeID_Map> 
      capacity(capacity_array, edge_id), 
      flow(flow_array, edge_id);

  print_network(G, capacity, flow);*/