#include "nfa_handler.h"

#include <boost/graph/graphviz.hpp>
#include <iostream>                     // std::cout
#include <fstream>
#include <stdio.h>
#include <omp.h>
#include <random>                       // std::default_random_engine
#include <algorithm>                    // std::random_shuffle

namespace nfa_bre {

uint64_t NFAHandler::hash(vertexes_t& the_map, graph_t const& the_graph)
{
    uint64_t h1, h2, h3, h4, h5, result = 0;
    for (auto& level : the_map)
    {
        for (auto& value : the_map[level.first])
        {
            for (auto& vert : the_map[level.first][value.first])
            {
                h1 = std::hash<uint>{}(the_graph[vert].level);
                h2 = std::hash<std::string>{}(the_graph[vert].label);
                h3 = std::hash<std::string>{}(the_graph[vert].path);
                
                h4 = 0;
                for (auto& parent : the_graph[vert].parents)
                    h4 = h4 * 5 + std::hash<uint>{}(parent);

                h5 = 0;
                for (auto& child : the_graph[vert].children)
                    h5 = h5 * 7 + std::hash<uint>{}(child);

                result = h1 + h2 * 2 + h3 * 3 + h4 * 5 + h5 * 7 + result * 11;
            }
        }
    }
    return result;
}

NFAHandler::NFAHandler(const rulePack_s& rulepack, Dictionnary* dic)
{
    m_imported_param = false;

    add_vertex(m_graph); // origin;

	std::map<std::string, vertex_id_t> path_map;   // from node_path to node_id
    std::string    path_fwd;
    vertex_id_t    prev_id = 0;
    vertex_id_t    node_to_use = 0;
    criterionid_t level = 0;

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
    omp_lock_t writelock;
    omp_lock_t writelock2;
    omp_init_lock(&writelock);
    omp_init_lock(&writelock2);

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
                            omp_set_lock(&writelock);
                            m_graph[cr].children.erase(aux);
                            m_graph[cr].children.insert(vertex);
                            omp_unset_lock(&writelock);
                            m_graph[vertex].parents.insert(cr);
                        }
                        omp_set_lock(&writelock2);
                        n_merged++;
                        omp_unset_lock(&writelock2);
                        m_graph[aux].parents.clear();
                        m_graph[aux].label = "";
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
    vertexes_t final_vertexes; // per level > per value_dic > states list
    graph_t    final_graph(1);
    std::vector<vertex_id_t> mapa;
    std::map<vertex_id_t, vertex_id_t> mapaa;
    final_graph[0].label="o"; // origin
    dictionnary_t dic;

    // iterates all states
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
    std::fstream dot_file(filename, std::ios::out | std::ios::trunc);
    boost::write_graphviz(dot_file, m_graph, boost::make_label_writer(get(&vertex_info::label, m_graph)));
}

void NFAHandler::memory_dump(const std::string& filename, const rulePack_s& rulepack)
{
    std::fstream outfile(filename, std::ios::out | std::ios::trunc | std::ios::binary);

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

    // NFA ID (hash)
    const uint64_t nfa_hash = hash(m_vertexes, m_graph);
    outfile.write((char*)&nfa_hash, sizeof(nfa_hash));
    std::cout << "NFA hash: " << nfa_hash << std::endl;

    ////// ORIGIN
    mem_int = m_graph[0].children.size();
    outfile.write((char*)&mem_int, sizeof(mem_int));

    dic = m_dic->get_criterion_dic_by_level(0);
    criterion_def = &(*std::next(rulepack.m_ruleType.m_criterionDefinition.begin(),
                                 m_dic->m_sorting_map[0]));

    dump_nfa_state(&outfile, 0, &dic, criterion_def);
    dump_padding(&outfile, m_graph[0].children.size()+1);

    ////// AND THE REST OF CRITERIA
    criterionid_t the_level = 1;
    for (auto& level : m_vertexes)
    {
        if (level.second == m_vertexes[m_vertexes.size()-2])
            break;  // skip content

        mem_int = edges_per_level[level.first];
        outfile.write((char*)&mem_int, sizeof(mem_int));

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

void NFAHandler::dump_nfa_state(std::fstream* outfile,
                                const vertex_id_t& vertex_id,
                                dictionnary_t* dic,
                                const criterionDefinition_s* criterion_def)
{
    size_t n_fanout = m_graph[vertex_id].children.size();
    size_t aux = 1;
    uint64_t mem_int;
    operands_t mem_opa;
    operands_t mem_opb;

    for (auto& itr : m_graph[vertex_id].children)
    {
        parse_value(m_graph[itr].label, (*dic)[m_graph[itr].label], &mem_opa, &mem_opb, criterion_def);
        mem_int = (uint64_t)(aux++ == n_fanout) << SHIFT_LAST;
        mem_int |= ((uint64_t)256 & MASK_WEIGHT) << SHIFT_WEIGHT;
        mem_int |= ((uint64_t)(m_graph[itr].dump_pointer) & MASK_POINTER) << SHIFT_POINTER;
        mem_int |= ((uint64_t)(mem_opb & MASK_OPERAND_B)) << SHIFT_OPERAND_B;
        mem_int |= ((uint64_t)(mem_opa & MASK_OPERAND_A)) << SHIFT_OPERAND_A;
        outfile->write((char*)&mem_int, sizeof(mem_int));
    }
}

void NFAHandler::dump_padding(std::fstream* outfile, const size_t& slices)
{
    uint64_t mem_int = 0;
    size_t n_edges = slices % C_EDGES_PER_CACHE_LINE;
    n_edges = (n_edges == 0) ? 0 : C_EDGES_PER_CACHE_LINE - n_edges;
    for (size_t pad = n_edges; pad != 0; pad--)
        outfile->write((char*)&mem_int, sizeof(mem_int));
}

void NFAHandler::parse_value(const std::string& value_raw,
                             const valueid_t& value_id,
                             valueid_t* operand_a,
                             valueid_t* operand_b,
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

void NFAHandler::dump_benchmark_workload(const std::string& path, const rulePack_s& rulepack)
{
    // generate .csv and .aux
    std::fstream fileaux = dump_workload(path + "benchmark", rulepack);
    std::fstream benchfile(path + "benchmark.bin", std::ios::out | std::ios::trunc | std::ios::binary);

    uint32_t query_size = rulepack.m_ruleType.m_criterionDefinition.size() * C_RAW_CRITERION_SIZE;
    query_size = query_size / C_CACHE_LINE_WIDTH + ((query_size % C_CACHE_LINE_WIDTH) ? 1 : 0);
    query_size = query_size * C_CACHE_LINE_WIDTH;
    uint32_t benchmark_size = rulepack.m_rules.size();

    benchfile.write(reinterpret_cast<char *>(&query_size), sizeof(query_size));
    benchfile.write(reinterpret_cast<char *>(&benchmark_size), sizeof(benchmark_size));

    fileaux.seekg(0, std::ios::beg);
    benchfile << fileaux.rdbuf();

    fileaux.close();
    benchfile.close();
    remove(((std::string)(path + "benchmark.aux")).c_str());
}

// void NFAHandler::dump_benchmark_workload(const std::string& path, const rulePack_s& rulepack)
// {
//     std::string dest_folder = path + "benchmarks/";
//     if (std::filesystem::exists(dest_folder))
//         std::filesystem::remove_all(dest_folder);
//     std::filesystem::create_directory(dest_folder);
// 
//     dest_folder = dest_folder + "workload";
//     // generate .csv and .aux
//     std::fstream fileaux = dump_workload(dest_folder, rulepack);
// 
//     // partial benchmarks
//     for (uint i = 1; i <= rulepack.m_rules.size(); i = i << 1)
//         dump_partial_workload(dest_folder, rulepack, &fileaux, i, 1);
// 
//     // full benchmarks
//     for (uint i = 1; i < 10; i++)
//         dump_partial_workload(dest_folder, rulepack, &fileaux, rulepack.m_rules.size(), i);
// 
//     fileaux.close();
//     remove(((std::string)(dest_folder + ".aux")).c_str());
// }

void NFAHandler::dump_partial_workload(const std::string& filename, const rulePack_s& rulepack,
                                       std::fstream* fileaux,
                                       const uint32_t& size, const uint16_t& mult)
{
    char fname[1024];
    sprintf(fname, "%s-%07d.bin", filename.c_str(), size * mult);
    std::fstream filebin(fname, std::ios::out | std::ios::trunc | std::ios::binary);

    // file header
    uint32_t query_size;   // in bytes with padding
    uint32_t queries_size; // in bytes with padding
    uint32_t results_size; // in bytes without padding
    uint32_t restats_size; // in bytes without padding
    uint32_t num_queries = size * mult;

    results_size = num_queries * C_RAW_RESUTLS_SIZE;
    restats_size = num_queries * C_RAW_RESULT_STATS_WIDTH;
    query_size   = rulepack.m_ruleType.m_criterionDefinition.size() * C_RAW_CRITERION_SIZE;
    query_size   = query_size / C_CACHE_LINE_WIDTH + ((query_size % C_CACHE_LINE_WIDTH) ? 1 : 0);
    queries_size = query_size * num_queries * C_CACHE_LINE_WIDTH;

    filebin.write(reinterpret_cast<char *>(&queries_size), sizeof(queries_size));
    filebin.write(reinterpret_cast<char *>(&results_size), sizeof(results_size));
    filebin.write(reinterpret_cast<char *>(&restats_size), sizeof(restats_size));
    filebin.write(reinterpret_cast<char *>(&num_queries),  sizeof(num_queries));

    printf("> %u rules and %u batches\n", size, mult);
    printf("> # of queries: %9u\n", num_queries);
    printf("> Queries size: %9u bytes\n", queries_size);
    printf("> Results size: %9u bytes\n", results_size);
    printf("> Stats size:   %9u bytes\n", restats_size);

    char* buffer = new char[size * query_size * C_CACHE_LINE_WIDTH];
    fileaux->seekg(0, std::ios::beg);
    fileaux->read(buffer, size * query_size * C_CACHE_LINE_WIDTH);


    for (size_t i = 0; i < mult; i++)
        filebin.write(buffer, size * query_size * C_CACHE_LINE_WIDTH);

    delete[] buffer;

    filebin.close();
}

std::fstream NFAHandler::dump_workload(const std::string& filename, const rulePack_s& rulepack)
{
    std::fstream filecsv(filename + ".csv", std::ios::out | std::ios::trunc);
    std::fstream fileaux(filename + ".aux", std::ios::out | std::ios::in | std::ios::trunc | std::ios::binary);

    const uint SLICES_PER_LINE = C_CACHE_LINE_WIDTH / C_RAW_CRITERION_SIZE;
    uint padding_slices = (rulepack.m_ruleType.m_criterionDefinition.size()) % SLICES_PER_LINE;
    padding_slices = (padding_slices == 0) ? 0 : SLICES_PER_LINE - padding_slices;

    operands_t mem_opa;
    operands_t mem_opb;
    criterionid_t the_level;
    const criterion_s* aux_criterion;
    const criterionDefinition_s* aux_definition;

    // shuffle rules so benchmark has no similar consecutive queries
    std::vector<rule_s> the_rules(rulepack.m_rules.begin(), rulepack.m_rules.end());
    std::shuffle(the_rules.begin(), the_rules.end(), std::default_random_engine(0));

    for (auto& rule : the_rules)
    {
        the_level = 0;
        filecsv << rule.m_ruleId << "," << rule.m_weight;
        for (auto& ord : m_dic->m_sorting_map)
        {
            aux_criterion  = &(*std::next(rule.m_criteria.begin(), ord));
            aux_definition = &(*std::next(rulepack.m_ruleType.m_criterionDefinition.begin(), ord));

            parse_value(aux_criterion->m_value,
                        m_dic->get_criterion_dic_by_level(the_level)[aux_criterion->m_value],
                        &mem_opa,
                        &mem_opb,
                        aux_definition);

            fileaux.write((char*)&mem_opa, sizeof(mem_opa));
            filecsv << "," << aux_criterion->m_value;
            the_level++;
        }
        filecsv << "," << rule.m_content << std::endl;

        // padding
        mem_opa = 0;
        for (uint pad = padding_slices; pad != 0; pad--)
            fileaux.write((char*)&mem_opa, sizeof(mem_opa));
    }

    filecsv.close();
    return fileaux;
}

void NFAHandler::dump_mirror_workload(const std::string& filename, const rulePack_s& rulepack)
{
    const uint16_t BATCHES = 1;
    std::fstream filebin(filename + ".bin", std::ios::out | std::ios::trunc | std::ios::binary);
    std::fstream filecsv(filename + ".csv", std::ios::out | std::ios::trunc);
    std::fstream fileaux(filename + ".aux", std::ios::out | std::ios::in | std::ios::trunc | std::ios::binary);
    
    const uint SLICES_PER_LINE = C_CACHE_LINE_WIDTH / C_RAW_CRITERION_SIZE;

    uint padding_slices = (rulepack.m_ruleType.m_criterionDefinition.size()) % SLICES_PER_LINE;
    padding_slices = (padding_slices == 0) ? 0 : SLICES_PER_LINE - padding_slices;

    // file header
    uint32_t queries_size; // in bytes with padding
    uint32_t results_size; // in bytes without padding
    uint32_t restats_size; // in bytes without padding
    uint32_t num_queries;

    num_queries = 1;// rulepack.m_rules.size() * BATCHES; // ONLY ONE RULE
    results_size = num_queries * C_RAW_RESUTLS_SIZE;
    restats_size = num_queries * C_RAW_RESULT_STATS_WIDTH;
    queries_size = rulepack.m_ruleType.m_criterionDefinition.size() * C_RAW_CRITERION_SIZE;
    queries_size = queries_size / C_CACHE_LINE_WIDTH + ((queries_size % C_CACHE_LINE_WIDTH) ? 1 : 0);
    queries_size = queries_size * num_queries * C_CACHE_LINE_WIDTH;

    filebin.write(reinterpret_cast<char *>(&queries_size), sizeof(queries_size));
    filebin.write(reinterpret_cast<char *>(&results_size), sizeof(results_size));
    filebin.write(reinterpret_cast<char *>(&restats_size), sizeof(restats_size));
    filebin.write(reinterpret_cast<char *>(&num_queries),  sizeof(num_queries));

    printf("> # of queries: %9u\n", num_queries);
    printf("> Queries size: %9u bytes\n", queries_size);
    printf("> Results size: %9u bytes\n", results_size);
    printf("> Stats size:   %9u bytes\n", restats_size);

    operands_t mem_opa;
    operands_t mem_opb;
    criterionid_t the_level;
    const criterion_s* aux_criterion;
    const criterionDefinition_s* aux_definition;
    for (auto& rule : rulepack.m_rules)
    {
        the_level = 0;
        filecsv << rule.m_ruleId << "," << rule.m_weight;
        for (auto& ord : m_dic->m_sorting_map)
        {
            aux_criterion  = &(*std::next(rule.m_criteria.begin(), ord));
            aux_definition = &(*std::next(rulepack.m_ruleType.m_criterionDefinition.begin(), ord));

            parse_value(aux_criterion->m_value,
                        m_dic->get_criterion_dic_by_level(the_level)[aux_criterion->m_value],
                        &mem_opa,
                        &mem_opb,
                        aux_definition);

            fileaux.write((char*)&mem_opa, sizeof(mem_opa));
            filecsv << "," << aux_criterion->m_value;
            the_level++;
        }
        filecsv << "," << rule.m_content << std::endl;

        // padding
        mem_opa = 0;
        for (uint pad = padding_slices; pad != 0; pad--)
            fileaux.write((char*)&mem_opa, sizeof(mem_opa));
        break; //  ONLY ONE RULE
    }
    for (size_t i = 0; i < BATCHES; i++)
    {
        fileaux.seekg(0, std::ios::beg);
        filebin << fileaux.rdbuf();
    }

    filebin.close();
    filecsv.close();
    fileaux.close();
    remove(((std::string)(filename + ".aux")).c_str());
}

void NFAHandler::dump_core_parameters(const std::string& filename, const rulePack_s& rulepack)
{
    std::fstream outfile(filename, std::ios::out | std::ios::trunc);

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
    criterionid_t the_level = 0;
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
                        "        G_WEIGHT              => %u,\n"
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

void NFAHandler::dump_drools_rules(const std::string& path, const rulePack_s& rulepack)
{
    std::fstream outfile(path + "Rule.drl", std::ios::out | std::ios::trunc);

    outfile << "package com.ethz.rules\n\nimport com.ethz.SK_FDF;\n";
    outfile << "\ndialect \"java\"\n\n";

    // helpers
    uint16_t operand_a, operand_b;
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

    std::fstream secfile(path + "SK_FDF.java", std::ios::out | std::ios::trunc);
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

uint16_t NFAHandler::get_month_number(const std::string& month_code) const
{
    std::map<std::string, uint16_t> months
    {
        { "JAN",  1 },
        { "FEB",  2 },
        { "MAR",  3 },
        { "APR",  4 },
        { "MAY",  5 },
        { "JUN",  6 },
        { "JUL",  7 },
        { "AUG",  8 },
        { "SEP",  9 },
        { "OCT", 10 },
        { "NOV", 11 },
        { "DEC", 12 }
    };

    return months[month_code];
}

uint32_t NFAHandler::full_rata_die_day(const uint16_t& d, uint16_t m, uint16_t y) const
{
    if (m < 3)
        y--, m += 12;
    return 365*y + y/4 - y/100 + y/400 + (153*m - 457)/5 + d - 306;
}

valueid_t NFAHandler::date_check(const uint16_t& d, uint16_t m, uint16_t y) const
{
    // Rata Die day one is 0001-01-01

    /*  0       wildcard '*': it matches anything
     *  1       infinity down   e.g. 1st Jan 1990
     *  2       start date      e.g. 1st Jan 2006
     *  ...
     *  2^14-2  end date        e.g. 6th Nov 2050
     *  2^14-1  infinity up     e.g. 1st Jan 9999
     * 
     *  16,381 days period
     */
    // const uint32_t JANFIRST1990  =  726468; // 1st Jan 1990 - infinity down
    // const uint32_t JANFIRST2006  =  732312; // 1st Jan 2006 - start date
    // const uint32_t NOVNINETH2050 =  748692; // 6th Nov 2050 - end date
    // const uint32_t JANFIRST9999  = 3651695; // 1st Jan 9999 - infinity up
    const uint32_t JANFIRST1990  =  726468; // 1st Jan 1990 - infinity down
    const uint32_t JANFIRST2006  =  732312; // 1st Jan 2006 - start date
    const uint32_t NOVNINETH2050 = JANFIRST2006 + (1 << CFG_ENGINE_CRITERION_WIDTH) - 2; // end date
    const uint32_t JANFIRST9999  = 3651695; // 1st Jan 9999 - infinity up
    // using 1st Jan 2006 as start day, the end day is:
    //   - 13 bits: 2 Jun 2028
    //   - 14 bits: 6 Nov 2050
    uint32_t interim = full_rata_die_day(d, m, y);

    if (interim == JANFIRST1990)
    {
        return 1;
    }
    else if (interim < JANFIRST2006)
    {
        printf("[!] Minimal date is Jan 1st 2006, got: m=%d d=%d y=%d\n", m, d, y);
        return 1;
    }
    else if (interim == JANFIRST9999)
    {
        return USHRT_MAX;
    }
    else if (interim > NOVNINETH2050)
    {
        printf("[!] Maximal date is Nov 6th 2050, got: m=%d d=%d y=%d\n", m, d, y);
        return USHRT_MAX;
    }
    else
        return interim - JANFIRST2006 + 2;
}

void NFAHandler::parse_pairOfDates(const std::string& value, valueid_t* operand_a, valueid_t* operand_b) const
{
    if (value.length() != 19)
    {
        printf("[!] Failed parsing value [%s] as a pair of dates\n", value.c_str());
        *operand_a = 0;
        *operand_b = 0;
        return;
    }

    *operand_a = date_check(atoi(value.substr( 0,  2).c_str()),
                            get_month_number(value.substr( 2,  3)),
                            atoi(value.substr( 5,  4).c_str()));
    *operand_b = date_check(atoi(value.substr(10, 2).c_str()),
                            get_month_number(value.substr(12, 3)),
                            atoi(value.substr(15, 4).c_str()));
}

void NFAHandler::parse_pairOfFlights(std::string value_raw, valueid_t* operand_a, valueid_t* operand_b) const
{
    std::replace(value_raw.begin(), value_raw.end(), '/', ' ');
    char* p_end;
    *operand_a = strtoul(value_raw.c_str(), &p_end, 10);
    *operand_b = strtoul(p_end, &p_end, 10);
}

} // namespace nfa_bre