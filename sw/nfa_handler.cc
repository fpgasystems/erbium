#include "nfa_handler.h"

#include <boost/graph/graphviz.hpp>
#include <iostream>

namespace nfa_bre {

NFAHandler::NFAHandler(const rulePack_s rp, Dictionnary* dic)
{
    m_imported_param = false;

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
    std::map<uint, std::map<uint, std::set<uint>>> final_vertexes; // per level > per value_dic > states list
    graph_t final_graph(1);
    std::vector<uint> mapa;
    std::map<uint, uint> mapaa;
    final_graph[0].label="o"; // origin

    std::map<std::string, uint> dic;

    // iterates all states
    uint node_to_use;
    for (auto& level : m_vertexes)
    {
        dic = m_dic->get_criterium_dic_by_level(level.first);
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

                    final_vertexes[level.first][dic[m_graph[vert].label]].insert(node_to_use);
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
    std::cout << "origin: 1 states; " << m_graph[0].children.size() << " transitions; " << m_graph[0].children.size() << " max fan-out\n";
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
        std::cout << "level " << level.first << ": " << n_nodes << " states; " << n_edges << " transitions; " << n_edges_max << " max fan-out\n";
        n_bram_edges_max = (n_edges > n_bram_edges_max) ? n_edges : n_bram_edges_max;
    }
    return n_bram_edges_max;
}

void NFAHandler::export_dot_file(const std::string& filename)
{
    std::ofstream dot_file(filename);
    boost::write_graphviz(dot_file, m_graph, boost::make_label_writer(get(&vertex_info::label, m_graph)));
}

void NFAHandler::memory_dump(const std::string& filename)
{
    std::ofstream outfile(filename, std::ios::binary | std::ios::out | std::ios::trunc);

    //const uint CFG_ENGINE_NCRITERIA       = rp.m_ruleType.m_criterionDefinition.size();
    const uint CFG_ENGINE_CRITERIUM_WIDTH = 12;
    const uint CFG_WEIGHT_WIDTH           = 19;
    const uint CFG_MEM_ADDR_WIDTH         = 16;
    //const uint CFG_MEM_ADDR_WIDTH         = ceil(log2(n_bram_edges_max));
    //const uint CFG_EDGE_BUFFERS_DEPTH     = 5;
    //const uint CFG_EDGE_BRAM_DEPTH        = n_bram_edges_max;
    //const uint BRAM_USED_BITS             = CFG_WEIGHT_WIDTH + CFG_MEM_ADDR_WIDTH + CFG_ENGINE_CRITERIUM_WIDTH + CFG_ENGINE_CRITERIUM_WIDTH + 1;
    //const uint CFG_EDGE_BRAM_WIDTH        = 1 << ((uint)ceil(log2(BRAM_USED_BITS)));
    // const uint ZERO_PADDING               = CFG_EDGE_BRAM_WIDTH - BRAM_USED_BITS;

    const unsigned long long int MASK_WEIGHT     = 0x7FFFF;
    const unsigned long long int MASK_POINTER    = 0x7FFF;
    const unsigned long long int MASK_OPERAND_B  = 0xFFF;
    const unsigned long long int MASK_OPERAND_A  = 0xFFF;
    const unsigned long long int SHIFT_LAST      = CFG_WEIGHT_WIDTH+CFG_MEM_ADDR_WIDTH+2*CFG_ENGINE_CRITERIUM_WIDTH;
    const unsigned long long int SHIFT_WEIGHT    = CFG_MEM_ADDR_WIDTH+2*CFG_ENGINE_CRITERIUM_WIDTH;
    const unsigned long long int SHIFT_POINTER   = 2*CFG_ENGINE_CRITERIUM_WIDTH;
    const unsigned long long int SHIFT_OPERAND_B = CFG_ENGINE_CRITERIUM_WIDTH;
    const unsigned long long int SHIFT_OPERAND_A = 0;

    // POINTERS
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

    // before-last-criterium states point to the result directly
    auto element = m_graph[0];
    for (auto& value : m_vertexes[m_vertexes.size()-2])
    {
        for (auto& vert : m_vertexes[m_vertexes.size()-2][value.first])
        {
            element = m_graph[vert];
            if (element.parents.size() != 0)
            {
                element.dump_pointer = m_graph[*element.children.begin()].dump_pointer;
            }
        }
    }

    unsigned long long int mem_int;
    uint SLICES_PER_LINE = 512 / 64;

    ////// ORIGIN
    uint aux = 1;
    std::map<std::string, uint> dic;

    // number of edges
    mem_int = m_graph[0].children.size();
    write_longlongint(&outfile, mem_int);
    // helpers
    dic = m_dic->get_criterium_dic_by_level(0);
    n_edges_max = m_graph[0].children.size();
    for (auto& itr : m_graph[0].children)
    {
        mem_int = (unsigned long long int)(aux++ == n_edges_max) << SHIFT_LAST;
        mem_int |= ((unsigned long long int)256 & MASK_WEIGHT) << SHIFT_WEIGHT;
        mem_int |= ((unsigned long long int)m_graph[itr].dump_pointer & MASK_POINTER) << SHIFT_POINTER;
        mem_int |= ((unsigned long long int)dic[m_graph[itr].label] & MASK_OPERAND_B) << SHIFT_OPERAND_B;
        mem_int |= ((unsigned long long int)dic[m_graph[itr].label] & MASK_OPERAND_A) << SHIFT_OPERAND_A;
        write_longlongint(&outfile, mem_int);
    }

    // padding
    n_edges = (n_edges_max+1) % SLICES_PER_LINE;
    n_edges = (n_edges == 0) ? 0 : SLICES_PER_LINE - n_edges;
    for (uint pad = n_edges; pad != 0; pad--)
        write_longlongint(&outfile, 0);
    // std::cout << "level=0 edges=" << n_edges_max << " padding=" << n_edges << std::endl;

    ////// AND THE REST OF CRITERIA
    uint the_level = 1;
    for (auto level : m_vertexes)
    {
        if (level.second == m_vertexes[m_vertexes.size()-2])
            break;  // skip content


        // number of edges
        mem_int = edges_per_level[level.first];
        write_longlongint(&outfile, mem_int);
        // helpers
        dic = m_dic->get_criterium_dic_by_level(the_level++);
        for (auto& value : m_vertexes[level.first])
        {
            for (auto& vert : m_vertexes[level.first][value.first])
            {
                aux=1;
                n_edges_max = m_graph[vert].children.size();
                for (auto& itr : m_graph[vert].children)
                {
                    mem_int = (unsigned long long int)(aux++ == n_edges_max) << SHIFT_LAST;
                    mem_int |= ((unsigned long long int)256 & MASK_WEIGHT) << SHIFT_WEIGHT;
                    mem_int |= ((unsigned long long int)(m_graph[itr].dump_pointer) & MASK_POINTER) << SHIFT_POINTER;
                    mem_int |= ((unsigned long long int)(dic[m_graph[itr].label] & MASK_OPERAND_B)) << SHIFT_OPERAND_B;
                    mem_int |= ((unsigned long long int)(dic[m_graph[itr].label] & MASK_OPERAND_A)) << SHIFT_OPERAND_A;
                    write_longlongint(&outfile, mem_int);
                }
            }
        }
        // padding
        n_edges = (edges_per_level[level.first]+1) % SLICES_PER_LINE;
        n_edges = (n_edges == 0) ? 0 : SLICES_PER_LINE - n_edges;
        for (uint pad = n_edges; pad != 0; pad--)
            write_longlongint(&outfile, 0);
        // std::cout << "level=" << level.first+1 << " edges=" << edges_per_level[level.first] << " padding=" << n_edges << std::endl;
    }

    outfile.close();
}

void NFAHandler::write_longlongint(std::ofstream* outfile, unsigned long long int value)
{
    uintptr_t addr = (uintptr_t)&value;
    for (short i = sizeof(value)-1; i >= 0; i--)
        outfile->write((char*)(addr + i), 1);
}

bool import_parameters(const std::string& filename)
{
    // TODO
    return false;
}

bool export_parameters(const std::string& filename)
{
    // TODO
    return false;
}

void NFAHandler::dump_mirror_workload(const std::string& filename, const rulePack_s& rp)
{
    //    std::ofstream outfile(filename, std::ios::binary | std::ios::out | std::ios::trunc);
    //
    //    unsigned short int mem_int;
    //    uint SLICES_PER_LINE = 512 / 32;
    //
    //
    //    uint the_level = 1;
    //    for (auto& rule : rp.m_rules)
    //    {
    //        the_level = 0;
    //        for (auto& ord : m_dic->m_sorting_map)
    //        {
    //            criterion_s criterium = *std::next(rule.m_criteria.begin(), ord);
    //
    //            the_level++;
    //        }
    //
    //        // padding
    //        n_edges = (edges_per_level[level.first]+1) % SLICES_PER_LINE;
    //        n_edges = (n_edges == 0) ? 0 : SLICES_PER_LINE - n_edges;
    //        for (uint pad = n_edges; pad != 0; pad--)
    //            write_longlongint(&outfile, 0);
    //    }
    //
    //    for (auto level : m_vertexes)
    //    {
    //        if (level.second == m_vertexes[m_vertexes.size()-2])
    //            break;  // skip content
    //
    //
    //        // number of edges
    //        mem_int = edges_per_level[level.first];
    //        write_longlongint(&outfile, mem_int);
    //        // helpers
    //        dic = m_dic->get_criterium_dic_by_level(the_level++);
    //        for (auto& value : m_vertexes[level.first])
    //        {
    //            for (auto& vert : m_vertexes[level.first][value.first])
    //            {
    //                aux=1;
    //                n_edges_max = m_graph[vert].children.size();
    //                for (auto& itr : m_graph[vert].children)
    //                {
    //                    mem_int = (unsigned long long int)(aux++ == n_edges_max) << SHIFT_LAST;
    //                    mem_int |= ((unsigned long long int)256 & MASK_WEIGHT) << SHIFT_WEIGHT;
    //                    mem_int |= ((unsigned long long int)(m_graph[itr].dump_pointer) & MASK_POINTER) << SHIFT_POINTER;
    //                    mem_int |= ((unsigned long long int)(dic[m_graph[itr].label] & MASK_OPERAND_B)) << SHIFT_OPERAND_B;
    //                    mem_int |= ((unsigned long long int)(dic[m_graph[itr].label] & MASK_OPERAND_A)) << SHIFT_OPERAND_A;
    //                    write_longlongint(&outfile, mem_int);
    //                }
    //            }
    //        }
    //        
    //        // std::cout << "level=" << level.first+1 << " edges=" << edges_per_level[level.first] << " padding=" << n_edges << std::endl;
    //    }
    //
    //    outfile.close();
}

} // namespace nfa_bre