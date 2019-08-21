#include "nfa_handler.h"

#include <boost/graph/graphviz.hpp>
#include <iostream>

namespace nfa_bre {

NFAHandler::NFAHandler(const rulePack_s& rulepack, Dictionnary* dic)
{
    m_imported_param = false;

    add_vertex(m_graph); // origin;

	std::map<std::string, uint> path_map;   // from node_path to node_id
    std::string path_fwd;
    uint prev_id = 0;
    uint level = 0;
    uint node_to_use = 0;

    for (auto& rule : rulepack.m_rules)
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
                node_to_use = add_vertex(m_graph);
                path_map[path_fwd] = node_to_use;
                m_graph[node_to_use].label = criterion.m_value;
                m_graph[node_to_use].level = level;
                m_graph[node_to_use].path = path_fwd;
                m_vertexes[level][dic->m_dic_criteria[criterion.m_index][criterion.m_value]].insert(node_to_use);
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
    // iterates all the levels (one level per criterion)
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
        dic = m_dic->get_criterion_dic_by_level(level.first);
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

void NFAHandler::export_dot_file(const std::string& filename)
{
    std::ofstream dot_file(filename);
    boost::write_graphviz(dot_file, m_graph, boost::make_label_writer(get(&vertex_info::label, m_graph)));
}

void NFAHandler::memory_dump(const std::string& filename, const rulePack_s& rulepack)
{
    std::ofstream outfile(filename, std::ios::binary | std::ios::out | std::ios::trunc);

    //----------------- Address pointers
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

                // TODO why this? last level is not used
                // does it work for conflict rules for ex?
                if (n_edges_max == 0)
                    n_edges++;
                else
                    n_edges += n_edges_max;
            }
        }
        edges_per_level[level->first] = n_edges;
    }

    // before-last-criterion states point to the result directly
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
    std::map<std::string, uint> dic;
    const criterionDefinition_s* criterion_def;

    ////// ORIGIN
    mem_int = m_graph[0].children.size();
    write_longlongint(&outfile, mem_int);

    dic = m_dic->get_criterion_dic_by_level(0);
    criterion_def = &(*std::next(rulepack.m_ruleType.m_criterionDefinition.begin(),
                                 m_dic->m_sorting_map[0]));

    dump_nfa_state(&outfile, 0, &dic, criterion_def);
    dump_padding(&outfile, m_graph[0].children.size()+1);

    ////// AND THE REST OF CRITERIA
    uint the_level = 1;
    for (auto& level : m_vertexes)
    {
        if (level.second == m_vertexes[m_vertexes.size()-2])
            break;  // skip content

        mem_int = edges_per_level[level.first];
        write_longlongint(&outfile, mem_int);        

        dic = m_dic->get_criterion_dic_by_level(the_level);
        criterion_def = &(*std::next(rulepack.m_ruleType.m_criterionDefinition.begin(),
                                     m_dic->m_sorting_map[the_level]));
        for (auto& value : m_vertexes[level.first])
        {
            for (auto& vert : m_vertexes[level.first][value.first])
                dump_nfa_state(&outfile, vert, &dic, criterion_def);
        }
        dump_padding(&outfile, edges_per_level[level.first]+1);
        the_level++;
    }

    outfile.close();
}

void NFAHandler::dump_nfa_state(std::ofstream* outfile,
                                const uint& vertex_id,
                                std::map<std::string, uint>* dic,
                                const criterionDefinition_s* criterion_def)
{
    unsigned long long int mem_int;
    uint aux = 1;
    uint n_fanout = m_graph[vertex_id].children.size();
    unsigned short int mem_opa;
    unsigned short int mem_opb;

    for (auto& itr : m_graph[vertex_id].children)
    {
        parse_value(m_graph[itr].label, (*dic)[m_graph[itr].label], &mem_opa, &mem_opb, criterion_def);
        mem_int = (unsigned long long int)(aux++ == n_fanout) << SHIFT_LAST;
        mem_int |= ((unsigned long long int)256 & MASK_WEIGHT) << SHIFT_WEIGHT;
        mem_int |= ((unsigned long long int)(m_graph[itr].dump_pointer) & MASK_POINTER) << SHIFT_POINTER;
        mem_int |= ((unsigned long long int)(mem_opb & MASK_OPERAND_B)) << SHIFT_OPERAND_B;
        mem_int |= ((unsigned long long int)(mem_opa & MASK_OPERAND_A)) << SHIFT_OPERAND_A;
        write_longlongint(outfile, mem_int);
    }
}

void NFAHandler::dump_padding(std::ofstream* outfile, const uint& slices)
{
    unsigned long long int mem_int = 0;
    uint n_edges = slices % C_EDGES_PER_CACHE_LINE;
    n_edges = (n_edges == 0) ? 0 : C_EDGES_PER_CACHE_LINE - n_edges;
    for (uint pad = n_edges; pad != 0; pad--)
        write_longlongint(outfile, mem_int);
}

template<typename T>
void NFAHandler::write_longlongint(std::ofstream* outfile, const T& value)
{
    //const uintptr_t addr = (uintptr_t)&value;
    //for (short i = sizeof(value) - 1; i >= 0; i--)
    //    outfile->write((char*)(addr + i), 1);
    outfile->write((char*)&value, sizeof(value));
}

void NFAHandler::parse_value(const std::string& value_raw,
                             const uint& value_id,
                             unsigned short int* operand_a,
                             unsigned short int* operand_b,
                             const criterionDefinition_s* criterion_def)
{
    if (!criterion_def->m_isPair)
    {
        *operand_a = value_id;
        *operand_b = 0;
    }
    else if (value_raw.c_str()[0] == '*')
    {
        *operand_a = value_id;
        *operand_b = value_id;
    }
    else
    {
        switch (criterion_def->m_functor)
        {
            case 212: // criterionType_pairofdates.xml
                parse_pairOfDates(value_raw, operand_a, operand_b);
                break;
            case 412: // criterionType_integerrange4-digits_412.xml
                parse_pairOfFlights(value_raw, operand_a, operand_b);
                break;
            default:
                std::cout << "[!] Pair functor #" << criterion_def->m_functor;
                std::cout << " of value= " << value_raw << " is unknown\n";
                *operand_a = 0;
                *operand_b = 0;
        }
    }
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

void NFAHandler::dump_mirror_workload(const std::string& filename, const rulePack_s& rulepack)
{
    std::ofstream outfile(filename, std::ios::binary | std::ios::out | std::ios::trunc);
    // std::ofstream hrfile(filename.substr(filename.length()-4)+".txt", std::ios::out | std::ios::trunc);
    
    const uint SLICES_PER_LINE = C_CACHE_LINE_WIDTH / C_RAW_CRITERION_SIZE;
    unsigned short int mem_opa;
    unsigned short int mem_opb;

    uint padding_slices = (rulepack.m_ruleType.m_criterionDefinition.size()) % SLICES_PER_LINE;
    padding_slices = (padding_slices == 0) ? 0 : SLICES_PER_LINE - padding_slices;

    // file header
    uint32_t queries_size; // in bytes with padding
    uint32_t results_size; // in bytes without padding
    uint32_t restats_size; // in bytes without padding
    uint32_t num_queries;

    num_queries = rulepack.m_rules.size();
    results_size = num_queries * C_RAW_RESUTLS_SIZE;
    restats_size = num_queries * C_RAW_RESULT_STATS_WIDTH;
    queries_size = rulepack.m_ruleType.m_criterionDefinition.size() * C_RAW_CRITERION_SIZE;
    queries_size = queries_size / C_CACHE_LINE_WIDTH + ((queries_size % C_CACHE_LINE_WIDTH) ? 1 : 0);
    queries_size = queries_size * num_queries * C_CACHE_LINE_WIDTH;

    outfile.write(reinterpret_cast<char *>(&queries_size), sizeof(queries_size));
    outfile.write(reinterpret_cast<char *>(&results_size), sizeof(results_size));
    outfile.write(reinterpret_cast<char *>(&restats_size), sizeof(restats_size));
    outfile.write(reinterpret_cast<char *>(&num_queries),  sizeof(num_queries));

    printf("> # of queries: %9u\n", num_queries);
    printf("> Queries size: %9u bytes\n", queries_size);
    printf("> Results size: %9u bytes\n", results_size);
    printf("> Stats size:   %9u bytes\n", restats_size);

    uint the_level;
    const criterion_s* aux_criterion;
    const criterionDefinition_s* aux_definition;
    for (auto& rule : rulepack.m_rules)
    {
        the_level = 0;
        for (auto& ord : m_dic->m_sorting_map)
        {
            aux_criterion  = &(*std::next(rule.m_criteria.begin(), ord));
            aux_definition = &(*std::next(rulepack.m_ruleType.m_criterionDefinition.begin(), ord));

            parse_value(aux_criterion->m_value,
                        m_dic->get_criterion_dic_by_level(the_level)[aux_criterion->m_value],
                        &mem_opa,
                        &mem_opb,
                        aux_definition);

            write_longlongint(&outfile, mem_opa);
            // hrfile.write(aux_criterion->m_value.c_str(), aux_criterion->m_value.length());
            // hrfile.write(" ", 1);
            the_level++;
        }
        // hrfile.write("\n", 1);

        // padding
        mem_opa = 0;
        for (uint pad = padding_slices; pad != 0; pad--)
            write_longlongint(&outfile, mem_opa);
    }

    outfile.close();
    // hrfile.close();
}

void NFAHandler::dump_core_parameters(const std::string& filename, const rulePack_s& rulepack)
{
    std::ofstream outfile(filename, std::ios::out | std::ios::trunc);

    std::vector<uint> edges_per_level(m_vertexes.size()+1);
    edges_per_level[0] = m_graph[0].children.size();
    for (auto& level : m_vertexes)
    {
        edges_per_level[level.first+1] = 0;
        for (auto& value : m_vertexes[level.first])
        {
            for (auto& vert : m_vertexes[level.first][value.first])
            {
                edges_per_level[level.first+1] += m_graph[vert].children.size();
            }
        }
    }

    const criterionDefinition_s* criterion_def;
    char buffer[1024];
    std::string func_a, func_b, func_pair, match_mode;
    uint the_level = 0;
    for (auto& ord : m_dic->m_sorting_map)
    {
        criterion_def = &(*std::next(rulepack.m_ruleType.m_criterionDefinition.begin(), ord));


        switch(criterion_def->m_functor)
        {
            case  60 : // criterionType_alphanumstring3-3.xml
            case  67 : // criterionType_alphanumstring2-2.xml
            case 273 : // criterionType_alphastring2-2.xml
            case 316 : // criterionType_alphanumstring1-3.xml
            case 408 : // criterionType_integer0-9999_408.xml
                func_a     = "FNCTR_SIMP_EQU";
                func_b     = "FNCTR_SIMP_NOP";
                func_pair  = "FNCTR_PAIR_NOP";
                match_mode = "MODE_STRICT_MATCH";
                break;
            case 212 : // criterionType_pairofdates.xml
            case 412 : // criterionType_integerrange4-digits_412.xml
                func_a     = "FNCTR_SIMP_GEQ";
                func_b     = "FNCTR_SIMP_LEQ";
                func_pair  = "FNCTR_PAIR_AND";
                match_mode = "MODE_FULL_ITERATION";
                break;
            default:
                std::cout << "[!] functor #" << criterion_def->m_functor << " is unknown\n";
                func_a     = "FNCTR_SIMP_NOP";
                func_b     = "FNCTR_SIMP_NOP";
                func_pair  = "FNCTR_PAIR_NOP";
                match_mode = "MODE_FULL_ITERATION";
        }

        // std::cout << "edges_per_level[" << the_level << "] = " << edges_per_level[the_level] << std::endl;
        sprintf(buffer, "    constant CORE_PARAM_%u : core_parameters_type := (\n"
                        "        G_RAM_DEPTH           => %u,\n"
                        "        G_MATCH_STRCT         => %s,\n"
                        "        G_MATCH_FUNCTION_A    => %s,\n"
                        "        G_MATCH_FUNCTION_B    => %s,\n"
                        "        G_MATCH_FUNCTION_PAIR => %s,\n"
                        "        G_MATCH_MODE          => %s,\n"
                        "        G_WEIGHT              => %lu,\n"
                        "        G_WILDCARD_ENABLED    => '%u'\n"
                        "    );\n",
            the_level,
            1 << ((uint)ceil(log2(edges_per_level[the_level]))),
            (criterion_def->m_isPair) ? "STRCT_PAIR" : "STRCT_SIMPLE",
            func_a.c_str(),
            func_b.c_str(),
            func_pair.c_str(),
            match_mode.c_str(),
            criterion_def->m_weight,
            !criterion_def->m_isMandatory);

        outfile << buffer;        
        the_level++;
    }
    outfile << "    constant CFG_CORE_PARAM_ARRAY : CORE_PARAM_ARRAY := (\n";
    for (the_level = 0; the_level < m_vertexes.size()-1; the_level++)
    {
        outfile << "        CORE_PARAM_" << the_level;
        if (the_level != m_vertexes.size()-2)
            outfile << ",\n";
        else
            outfile << "\n    );";
    }

    outfile.close();
}

void NFAHandler::dump_drools_rules(const std::string& filename, const rulePack_s& rulepack)
{
    std::ofstream outfile(filename, std::ios::out | std::ios::trunc);

    outfile << "package rules\n\nimport com.ethz.SK_FDF;\n";
    outfile << "\ndialect \"java\"\n\n";

    // helpers
    unsigned short int operand_a, operand_b;
    bool except;
    const criterionDefinition_s* crit_def;
    for (auto& rule : rulepack.m_rules)
    {
        outfile << "rule \"abr" << rule.m_ruleId << "\"\n\tsalience " << rule.m_weight;
        outfile << "\n\twhen\n\t\trule : SK_FDF (\n";
        except = false;
        for (auto& criterion : rule.m_criteria)
        {
            if (criterion.m_value[0] != '*')
            {
                if (except)
                {
                    outfile << ",\n";
                }
                crit_def = &(*std::next(rulepack.m_ruleType.m_criterionDefinition.begin(), criterion.m_index));
                outfile << "\t\t\t";

                if (!crit_def->m_isPair)
                {
                    outfile << crit_def->m_code;
                    outfile << " == \"" << criterion.m_value << "\"";
                }
                else
                {
                    parse_value(criterion.m_value, 0, &operand_a, &operand_b, crit_def);
                    outfile << "(" << crit_def->m_code << " >= \"" << operand_a << "\" && ";
                    outfile << crit_def->m_code << " <= \"" << operand_b << "\")";
                }
                except = true;
            }
        }

        outfile << "\n\t\t)\n\tthen\n\tSystem.out.println(" << rule.m_content << ");\nend\n";
    }

    outfile.close();

    std::ofstream secfile("build/SK_FDF.java", std::ios::out | std::ios::trunc);
    secfile << "package com.sample;\n\npublic class SK_FDF {\n";
    for (auto& crit_def : rulepack.m_ruleType.m_criterionDefinition)
    {
        if (!crit_def.m_isPair)
            secfile << "\tpublic String " << crit_def.m_code << ";\n";
        else
            secfile << "\tpublic int " << crit_def.m_code << ";\n";
    }
    secfile << "}";
    secfile.close();
}

void NFAHandler::dump_drools_workload(const std::string& filename, const rulePack_s& rulepack)
{

}

} // namespace nfa_bre