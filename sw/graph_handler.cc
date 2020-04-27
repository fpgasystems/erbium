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

#include "graph_handler.h"
#include "dictionnary.h"
#include "rule_parser.h"

#include <boost/graph/graphviz.hpp>
#include <fstream>                  // file read/write
#include <iostream>                 // std::cout
#include <omp.h>                    // openmp
#include <iterator>

namespace erbium {

GraphHandler::GraphHandler(const rulePack_s* rulepack, const Dictionnary* dic)
{
    add_vertex(m_graph); // origin;

    std::map<std::string, vertex_id_t> path_map;   // from node_path to node_id
    std::string   path_fwd;
    vertex_id_t   prev_id = 0;
    vertex_id_t   node_to_use = 0;
    criterionid_t level = 0;

    for (auto& rule : rulepack->m_rules)
    {
        path_fwd = "";
        prev_id = 0;
        level = 0;

        // Add criteria
        for (auto& ord : dic->m_sorting_map)
        {
            criterion_s criterion = *std::next(rule.m_criteria.begin(), ord);

            path_fwd = criterion.m_value + "_" + path_fwd;

            node_to_use = 0;
            if (path_map[path_fwd] == 0) // new path
            {
                node_to_use = boost::add_vertex(m_graph);
                path_map[path_fwd] = node_to_use;
                m_graph[node_to_use].label = criterion.m_value;
                m_graph[node_to_use].level = level;
                m_graph[node_to_use].path = path_fwd;
                m_graph[node_to_use].weight = rule.m_weight; // only used for last level DFA filtering
                m_vertexes[level][dic->get_valueid_by_sort(criterion.m_index, criterion.m_value)].insert(node_to_use);
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
            node_to_use = boost::add_vertex(m_graph);
            path_map[rule.m_content] = node_to_use;
            m_graph[node_to_use].label = rule.m_content;
            m_graph[node_to_use].level = level;
            m_graph[node_to_use].path  = rule.m_content;
            m_vertexes[level][dic->get_valueid_by_sort(level, rule.m_content)].insert(node_to_use);
        }
        else
            node_to_use = path_map[rule.m_content];

        m_graph[node_to_use].parents.insert(prev_id);
        m_graph[prev_id].children.insert(node_to_use);
    }
    m_dic = dic;
    m_rulePack = rulepack;
}

uint GraphHandler::suffix_reduction()
{
    omp_lock_t mgraph_writelock;
    omp_init_lock(&mgraph_writelock);

    uint n_merged = 0;
    // iterates all the levels (one level per criterion)
    for (auto level = ++(m_vertexes.rbegin()); level != m_vertexes.rend(); ++level)
    {
        auto it = m_vertexes[level->first].begin();
 
        // iterates all the values
        #pragma omp parallel for num_threads(m_vertexes[level->first].size())
        //for (auto& value_id : m_vertexes[level->first])
        for (uint i = 0; i < m_vertexes[level->first].size(); i++)
        {
            auto& value_id = *std::next(it, i);
            // iterates all the states with this value within this level
            for (auto& vertex : m_vertexes[level->first][value_id.first])
            {
                // skip if already merged
                if (m_graph[vertex].label == "")
                    continue;

                // compare to all the other states with same value (within same level)
                for (auto& aux : m_vertexes[level->first][value_id.first])
                {
                    if (aux <= vertex)
                        continue;

                    // skip if already merged
                    if (m_graph[aux].label == "")
                        continue;

                    // Check if both states point to the same states
                    if (m_graph[aux].children == m_graph[vertex].children)
                    {
                        // redirect all the in edges of aux to vertex
                        for (auto& cr : m_graph[aux].parents)
                        {
                            omp_set_lock(&mgraph_writelock);
                            m_graph[cr].children.erase(aux);
                            m_graph[cr].children.insert(vertex);
                            omp_unset_lock(&mgraph_writelock);
                            m_graph[vertex].parents.insert(cr);
                        }

                        #pragma omp atomic
                        n_merged++;

                        m_graph[aux].parents.clear();
                        m_graph[aux].label = "";
                    }
                }
            }
        }
    }
    return n_merged;
}

void GraphHandler::consolidate_graph()
{
    // effectively remove obsolete vertexes from the graph
    vertexes_t final_vertexes; // per level > per value_dic > states list
    graph_t    final_graph(1);
    std::vector<vertex_id_t> final_vlist;
    std::map<vertex_id_t, vertex_id_t> map_old2new;

    // iterates all states
    dictionnary_t dic;
    vertex_id_t node_to_use;
    for (auto& level : m_vertexes)
    {
        dic = m_dic->get_criterion_dic_by_level(level.first);
        for (auto& value : m_vertexes[level.first])
        {
            for (auto& vert : m_vertexes[level.first][value.first])
            {
                if (m_graph[vert].parents.size() != 0)
                {
                    final_vlist.push_back(vert);
                    node_to_use = boost::add_vertex(final_graph);
                    map_old2new[vert] = node_to_use;
                    final_graph[node_to_use] = m_graph[vert];
                    final_graph[node_to_use].parents.clear();
                    final_graph[node_to_use].children.clear();

                    final_vertexes[level.first][dic[m_graph[vert].label]].insert(node_to_use);
                }
            }
        }
    }

    // from origin, add edges
    final_graph[0].label="o";
    for (auto& vert : m_graph[0].children)
    {
        boost::add_edge(0, map_old2new[vert], final_graph);
        final_graph[map_old2new[vert]].parents.insert(0);
        final_graph[0].children.insert(map_old2new[vert]);
    }

    for (auto& itr : final_vlist)
    {
        for (auto& vert : m_graph[itr].children)
        {
            boost::add_edge(map_old2new[itr], map_old2new[vert], final_graph);
            final_graph[map_old2new[vert]].parents.insert(map_old2new[itr]);
            final_graph[map_old2new[itr]].children.insert(map_old2new[vert]);
        }

    }

    m_graph = final_graph;
    m_vertexes = final_vertexes;
}

void GraphHandler::make_deterministic()
{
    dictionnary_t dic;   
    // iterate all level from origin
    for (auto& level : m_vertexes)
    {
        dic = m_dic->get_criterion_dic_by_level(level.first);

        if (strcmp(dic.begin()->first.c_str(), "*") != 0)
            continue;

        /*std::cout << "Level " << level.first << " has "
                  << m_vertexes[level.first][dic.begin()->second].size()
                  << " wildcard states "
                  << dic.begin()->first
                  << std::endl;*/

        // for each wildcard vertex in this level
        for (auto& the_wildcard : m_vertexes[level.first][dic.begin()->second])
        {
            // for each of its parent -- N.B.: at this point it **should** be only one though...
            const auto list_parents = m_graph[the_wildcard].parents;
            for (auto& the_parent : list_parents)
            {
                // for each other children
                const auto list_child = m_graph[the_parent].children;
                for (auto& the_child : list_child)
                {
                    if (the_child == the_wildcard)
                        continue;

                    // duplicate the_wildcard into the_child
                    // "crescite et multiplicamini"
                    dfa_merge_paths(the_wildcard, the_child);
                }
            }
        }
    }
}

void GraphHandler::dfa_merge_paths(const vertex_id_t& orgi_state, const vertex_id_t& dest_state)
{
    /*std::cout << "merge at " << m_graph[orgi_state].level
                << " for " << m_graph[orgi_state].label << " into "
                << m_graph[dest_state].label << std::endl;*/

    if (m_graph[orgi_state].level == m_vertexes.size() - 2)
    {
        // keep only highest weight
        if (m_graph[orgi_state].weight > m_graph[dest_state].weight)
        {
            //std::cout << "I'm not sure when this would happen... [GraphHandler::dfa_merge_paths]\n";

            // remove initial content
            m_graph[*(m_graph[dest_state].children.begin())].parents.erase(dest_state);
            m_graph[dest_state].children.clear();

            // add new one
            m_graph[*(m_graph[orgi_state].children.begin())].parents.insert(dest_state);
            m_graph[dest_state].children.insert(*(m_graph[orgi_state].children.begin()));

            // update weight
            m_graph[dest_state].weight = m_graph[orgi_state].weight;
        }
        return;
    }

    bool existing_edge;
    // iterates all outgoing transition of origin state
    const auto list = m_graph[orgi_state].children;
    for (auto& orgi_children : list)
    {
        existing_edge = false;
        
        // check for same-value out. transitions
        const auto child_list = m_graph[dest_state].children;
        for (auto& dest_children : child_list)
        {
            if (m_graph[orgi_children].label == m_graph[dest_children].label)
            {
                existing_edge = true;

                // merge children paths
                dfa_merge_paths(orgi_children, dest_children);
                break;
            }
        }

        if (not existing_edge)
        {
            // append full path
            dfa_append_path(orgi_children, dest_state);
        }
    }
}

void GraphHandler::dfa_append_path(const vertex_id_t& orgi_children, const vertex_id_t& dest_state)
{
    /*std::cout << "[" << m_graph[orgi_children].level << "] "
              << m_graph[orgi_children].label
              << m_graph[orgi_children].weight
              << " into " << "[" << m_graph[dest_state].level << "] "
              << m_graph[dest_state].label
              << m_graph[dest_state].weight << std::endl;*/

    vertex_id_t neo_child = boost::add_vertex(m_graph);
    m_graph[neo_child].label  = m_graph[orgi_children].label;
    m_graph[neo_child].level  = m_graph[orgi_children].level;
    m_graph[neo_child].path   = m_graph[orgi_children].path;
    m_graph[neo_child].weight = m_graph[orgi_children].weight; // only used for last level DFA filtering
    
    m_vertexes[m_graph[neo_child].level]
        [m_dic->get_valueid_by_level(m_graph[neo_child].level, m_graph[neo_child].label)].insert(neo_child);
    
    m_graph[dest_state].children.insert(neo_child);
    m_graph[neo_child].parents.insert(dest_state);

    if (m_graph[orgi_children].level == m_vertexes.size() - 2)
    {
        m_graph[neo_child].children.insert(*m_graph[orgi_children].children.begin());
        return;
    }

    const auto list = m_graph[orgi_children].children;
    for (auto& grand_children : list)
        dfa_append_path(grand_children, neo_child);
}

uint GraphHandler::print_stats()
{
    uint n_nodes;
    uint n_edges;
    uint n_edges_max = 0;
    uint n_bram_edges_max = 0;
    uint aux;
    printf("origin  :     1 state ; %5lu transitions; %4lu max fan-out\n",
        m_graph[0].children.size(), m_graph[0].children.size());
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
        printf("level %2u: %5u states; %5u transitions; %4u max fan-out\n",
            level.first, n_nodes, n_edges, n_edges_max);
        n_bram_edges_max = (n_edges > n_bram_edges_max) ? n_edges : n_bram_edges_max;
    }
    return n_bram_edges_max;
}

uint64_t GraphHandler::get_graph_hash()
{
    uint64_t h1, h2, h3, h4, h5, result = 0;
    for (auto& level : m_vertexes)
    {
        for (auto& value : m_vertexes[level.first])
        {
            for (auto& vert : m_vertexes[level.first][value.first])
            {
                h1 = std::hash<uint>{}(m_graph[vert].level);
                h2 = std::hash<std::string>{}(m_graph[vert].label);
                h3 = std::hash<std::string>{}(m_graph[vert].path);
                
                h4 = 0;
                for (auto& parent : m_graph[vert].parents)
                    h4 = h4 * 5 + std::hash<uint>{}(parent);

                h5 = 0;
                for (auto& child : m_graph[vert].children)
                    h5 = h5 * 7 + std::hash<uint>{}(child);

                result = h1 + h2 * 2 + h3 * 3 + h4 * 5 + h5 * 7 + result * 11;
            }
        }
    }
    return result;
}

uint32_t GraphHandler::get_num_states()
{
    return boost::num_vertices(m_graph);
}

uint32_t GraphHandler::get_num_transitions()
{
    auto transitions_per_level = get_transitions_per_level();
    uint32_t total = 0;
    for (auto& level : transitions_per_level)
        total += level;
    return total;
}

std::vector<uint> GraphHandler::get_transitions_per_level()
{
    std::vector<uint> transitions_per_level(m_vertexes.size()+1);
    transitions_per_level[0] = m_graph[0].children.size();
    for (auto& level : m_vertexes)
    {
        transitions_per_level[level.first+1] = 0;
        for (auto& value : m_vertexes[level.first])
        {
            for (auto& vert : m_vertexes[level.first][value.first])
            {
                transitions_per_level[level.first+1] += m_graph[vert].children.size();
            }
        }
    }
    return transitions_per_level;
}

void GraphHandler::export_graphviz(const std::string& filename)
{
    std::fstream dot_file(filename, std::ios::out | std::ios::trunc);
    boost::write_graphviz(dot_file, m_graph, boost::make_label_writer(get(&vertex_info::label, m_graph)));
}

void GraphHandler::export_memory(const std::string& filename)
{
    std::fstream outfile(filename, std::ios::out | std::ios::trunc | std::ios::binary);

    // Address pointers
    std::vector<uint> edges_per_level(m_vertexes.size());
    uint n_edges;
    uint n_edges_max;
    for (auto level = m_vertexes.rbegin(); level != m_vertexes.rend(); ++level)
    {
        n_edges = 0;
        for (auto& value : m_vertexes[level->first])
        {
            for (auto& vert : m_vertexes[level->first][value.first])
            {
                m_graph[vert].dump_pointer = n_edges;
                n_edges_max = m_graph[vert].children.size();

                if (n_edges_max == 0)
                    n_edges++;
                else
                    n_edges += n_edges_max;
            }
        }
        edges_per_level[level->first] = n_edges;
    }

    // before-last-criterion states point to the result directly
    for (auto& value : m_vertexes[m_vertexes.size()-2])
    {
        for (auto& vert : m_vertexes[m_vertexes.size()-2][value.first])
            m_graph[vert].dump_pointer = m_graph[*m_graph[vert].children.begin()].dump_pointer;
    }

    uint64_t mem_int;
    dictionnary_t dic;
    const criterionDefinition_s* criterion_def;

    // Automata ID (hash)
    const uint64_t nfa_hash = get_graph_hash();
    outfile.write((char*)&nfa_hash, sizeof(nfa_hash));

    ////// ORIGIN
    mem_int = m_graph[0].children.size();
    outfile.write((char*)&mem_int, sizeof(mem_int));

    dic = m_dic->get_criterion_dic_by_level(0);
    criterion_def = &(*std::next(m_rulePack->m_ruleType.m_criterionDefinition.begin(),
                                 m_dic->m_sorting_map[0]));

    dump_binary_transition(&outfile, 0, &dic, criterion_def);
    dump_binary_padding(&outfile, m_graph[0].children.size()+1);

    ////// AND THE REST OF CRITERIA
    for (auto& level : m_vertexes)
    {
        if (level.second == m_vertexes[m_vertexes.size()-2])
            break;  // skip content

        mem_int = edges_per_level[level.first];
        outfile.write((char*)&mem_int, sizeof(mem_int));

        dic = m_dic->get_criterion_dic_by_level(level.first+1);
        criterion_def = &(*std::next(m_rulePack->m_ruleType.m_criterionDefinition.begin(),
                                     m_dic->m_sorting_map[level.first+1]));
        for (auto& value : m_vertexes[level.first])
        {
            for (auto& vert : m_vertexes[level.first][value.first])
                dump_binary_transition(&outfile, vert, &dic, criterion_def);
        }
        dump_binary_padding(&outfile, edges_per_level[level.first]+1);
    }

    outfile.close();
}

void GraphHandler::dump_binary_transition(std::fstream* outfile,
                                          const vertex_id_t& vertex_id,
                                          dictionnary_t* dic,
                                          const criterionDefinition_s* criterion_def)
{
    size_t n_fanout = m_graph[vertex_id].children.size();
    size_t aux = 1;
    transition_t mem_int;
    operand_t mem_opa;
    operand_t mem_opb;

    for (auto& itr : m_graph[vertex_id].children)
    {
        RuleParser::parse_value(
                m_graph[itr].label,
                (*dic)[m_graph[itr].label],
                &mem_opa,
                &mem_opb,
                criterion_def);

        mem_int = (transition_t)(aux++ == n_fanout) << SHIFT_LAST;
        mem_int |= (((transition_t)m_graph[itr].dump_pointer) & MASK_POINTER) << SHIFT_POINTER;
        mem_int |= (((transition_t)mem_opb) & MASK_OPERANDS) << SHIFT_OPERAND_B;
        mem_int |= (((transition_t)mem_opa) & MASK_OPERANDS) << SHIFT_OPERAND_A;
        // std::cout << mem_int << " p=" << m_graph[itr].dump_pointer << " a=" << mem_opa
        //           << " b=" << mem_opb << std::endl;
        outfile->write((char*)&mem_int, sizeof(mem_int));
    }
}

void GraphHandler::dump_binary_padding(std::fstream* outfile, const size_t& slices)
{
    transition_t mem_int = 0;
    size_t n_edges = slices % C_EDGES_PER_CACHE_LINE;
    n_edges = (n_edges == 0) ? 0 : C_EDGES_PER_CACHE_LINE - n_edges;
    for (size_t pad = n_edges; pad != 0; pad--)
        outfile->write((char*)&mem_int, sizeof(mem_int));
}

} // namespace erbium