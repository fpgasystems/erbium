#include "nfa_handler.h"

#include <boost/graph/graphviz.hpp>
#include <iostream>
#include <fstream>

namespace nfa_bre {

NFAHandler::NFAHandler(const rulePack_s rp, Dictionnary* dic)
{
    add_vertex(m_graph); // origin;

	std::map<std::string, uint> path_map;   // from node_path to node_id
    std::string path_fwd;
    uint prev_id = 0;
    uint level = 0;
    uint node_to_use = 0;

    for (auto& rule : rp.m_rules)
    {
        path_fwd = "";
        prev_id = 0;
        level = 0;

        // Add criteria
        for (auto& ord : dic->m_sorting_map)
        {
            criterion_s criterium = *std::next(rule.m_criteria.begin(), ord);

            path_fwd = criterium.m_value + "_" + path_fwd;

            node_to_use = 0;
            if (path_map[path_fwd] == 0) // new path
            {
                node_to_use = add_vertex(m_graph);
                path_map[path_fwd] = node_to_use;
                m_graph[node_to_use].label = criterium.m_value;
                m_graph[node_to_use].level = level;
                m_graph[node_to_use].path = path_fwd;
                m_vertexes[level][dic->m_dic_criteria[criterium.m_index][criterium.m_value]].insert(node_to_use);
            }
            else // use existing path
                node_to_use = path_map[path_fwd];

            m_graph[node_to_use].parents.insert(prev_id);
            m_graph[prev_id].children.insert(node_to_use);
            prev_id = node_to_use;
            level++;
        }

        // Add content
        if (path_map[rule.m_content] == 0)
        {
            // It does not exist
            node_to_use = add_vertex(m_graph);
            path_map[rule.m_content] = node_to_use;
            m_graph[node_to_use].label = rule.m_content;
            m_graph[node_to_use].level = level;
            m_graph[node_to_use].path  = rule.m_content;
            m_vertexes[level][dic->m_dic_contents[rule.m_content]].insert(node_to_use);
        }
        else
            node_to_use = path_map[rule.m_content];

        m_graph[node_to_use].parents.insert(prev_id);
        m_graph[prev_id].children.insert(node_to_use);
    }
    m_dic = dic;
}

uint NFAHandler::optimise()
{
    uint n_merged = 0;
    // iterates all the levels (one level per criterium)
    for (auto level = ++(m_vertexes.rbegin()); level != m_vertexes.rend(); ++level)
    {
        // iterates all the values
        for (auto& value_id : m_vertexes[level->first])
        {
            // iterates all the nodes with this value within this level
            for (auto& vertex : m_vertexes[level->first][value_id.first])
            {
                // skip if already merged
                if (m_graph[vertex].label == "")
                    continue;

                // compare to all the other nodes with same value (within same level)
                for (auto& aux : m_vertexes[level->first][value_id.first])
                {
                    if (aux <= vertex)
                        continue;

                    // skip if already merged
                    if (m_graph[aux].label == "")
                        continue;

                    // Check if both nodes point to the same nodes
                    if (m_graph[aux].children == m_graph[vertex].children)
                    {
                        // redirect all the in edges of aux to vertex
                        for (auto& cr : m_graph[aux].parents)
                        {
                            m_graph[cr].children.erase(aux);
                            m_graph[cr].children.insert(vertex);
                            m_graph[vertex].parents.insert(cr);
                        }
                        m_graph[aux].parents.clear();
                        m_graph[aux].label = "";
                        n_merged++;
                    }
                }
            }
        }
    }
    return n_merged;
}

void NFAHandler::deletion()
{
    // effectively remove obsolete vertexes from the graph
    std::map<uint, std::map<uint, std::set<uint>>> final_vertexes; // per level > per value_dic > nodes list
    graph_t final_graph(1);
    std::vector<uint> mapa;
    std::map<uint, uint> mapaa;
    final_graph[0].label="o"; // origin

    std::map<std::string, uint> dic;

    // iterates all states
    uint node_to_use;
    for (auto& level : m_vertexes)
    {
        dic = m_dic->get_criterium_dic(level.first);
        for (auto& value : m_vertexes[level.first])
        {
            for (auto& vert : m_vertexes[level.first][value.first])
            {
                if (m_graph[vert].parents.size() != 0)
                {
                    mapa.push_back(vert);
                    node_to_use = boost::add_vertex(final_graph);
                    mapaa[vert] = node_to_use;
                    final_graph[node_to_use] = m_graph[vert];
                    final_graph[node_to_use].parents.clear();
                    final_graph[node_to_use].children.clear();

                    final_vertexes[level][dic[m_graph[vert].label]].insert(node_to_use);
                }
            }
        }
    }
    // from origin, add edges
    for (auto& vert : m_graph[0].children)
    {
        boost::add_edge(0, mapaa[vert], final_graph);
        final_graph[mapaa[vert]].parents.insert(0);
        final_graph[0].children.insert(mapaa[vert]);
    }
    for (auto& itr : mapa)
    {
        for (auto& vert : m_graph[itr].children)
        {
            boost::add_edge(mapaa[itr], mapaa[vert], final_graph);
            final_graph[mapaa[vert]].parents.insert(mapaa[itr]);
            final_graph[mapaa[itr]].children.insert(mapaa[vert]);
        }

    }

    m_graph = final_graph;
    m_vertexes = final_vertexes;
}

uint NFAHandler::print_stats()
{
    uint n_nodes;
    uint n_edges;
    uint n_edges_max = 0;
    uint n_bram_edges_max = 0;
    uint aux;
    for (auto& level : m_vertexes)
    {
        n_nodes = 0;
        n_edges = 0;
        n_edges_max = 0;
        for (auto& value : m_vertexes[level.first])
        {
            for (auto& vert : m_vertexes[level.first][value.first])
            {
                aux = m_graph[vert].children.size();
                n_nodes++;
                n_edges += aux;
                n_edges_max = (aux > n_edges_max) ? aux : n_edges_max;
            }
        }
        std::cout << "level " << level.first << ": " << n_nodes << " nodes; " << n_edges << " edges; " << n_edges_max << " max edges\n";
        n_bram_edges_max = (n_edges > n_bram_edges_max) ? n_edges : n_bram_edges_max;
    }
    return n_bram_edges_max;
}

void NFAHandler::export_dot_file(const std::string filename)
{
    std::ofstream dot_file(filename);
    boost::write_graphviz(dot_file, m_graph, boost::make_label_writer(get(&vertex_info::label, m_graph)));
}

} // namespace nfa_bre