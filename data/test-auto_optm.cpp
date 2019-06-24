////// OPTIMISATIONS
    std::cout << "# OPTIMISATIONS" << std::endl;
    start = std::chrono::high_resolution_clock::now();
    // stats
    uint merged = 0;

    std::set<std::pair<uint, uint>> vertexes_to_remove;
    boost::graph_traits < boost::adjacency_list <> >::adjacency_iterator ai, a_end;
    boost::graph_traits < boost::adjacency_list <> >::adjacency_iterator bi, b_end;
    boost::graph_traits < boost::adjacency_list <> >::adjacency_iterator ci, c_end;
    
    // iterates all the levels (one level per criterium)
    for (auto level = ++(vertexes.rbegin()); level != vertexes.rend(); ++level)
    {
        #ifdef _DEBUG
        std::cout << "level " << (level->first);
        start = std::chrono::high_resolution_clock::now();
        #endif
        merged = 0;
        // iterates all the values
        for (auto value_id : vertexes[level->first])
        {
            // TODO: check why using the "auto" form misses some merges! (227 instead of 234)
            // iterates all the nodes with this value within this level
            for (auto vertex = vertexes[level->first][value_id.first].rbegin(); vertex != vertexes[level->first][value_id.first].rend(); ++vertex)
            //for (auto& vertex : vertexes[level->first][value_id.first])
            {
                // skip if already merged
                if (labels[*vertex] == "")
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
                    if (labels[*aux] == "")
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
                        for (auto cr : parents_of[*aux])
                        {
                            #ifdef _DEBUG
                            std::cout << "replacing edge [" << cr << "]-[" << *aux;
                            std::cout << "] to [" << cr << "]-[" << *vertex << "]" << std::endl;
                            std::cout << "[" << cr << "] " << netIS[cr] << " & " << netIS_bwd[cr] << std::endl;
                            #endif
                            boost::remove_edge(cr, *aux, g);
                            boost::add_edge(cr, *vertex, g);
                        }
                        parents_of[*aux].clear();

                        #ifdef _DEBUG
                        std::cout << "[" << *aux << "] " << netIS[*aux] << " & " << netIS_bwd[*aux] << std::endl;
                        std::cout << "[" << *vertex << "] " << netIS[*vertex] << " & " << netIS_bwd[*vertex] << std::endl;
                        boost::tie(bi, b_end) = boost::adjacent_vertices(*aux, g);
                        for (; bi != b_end; ++bi)
                            std::cout << "pointing to [" << *bi << "] " << netIS[*bi] << " & " << netIS_bwd[*bi] << std::endl;
                        #endif

                        vertexes_to_remove.insert(std::make_pair(*aux, level->first));
                        labels[*aux] = "";
                        merged++;
                        //{std::ofstream maoe("automaton" + std::to_string(filec++) + ".dot");
                        //boost::write_graphviz(maoe, g, boost::make_label_writer(&labels[0]));}
                        //std::cout << std::endl;
                        // rename vertex netIS/netSI ?
                    }
                }
            }
        }
        #ifdef _DEBUG
        finish = std::chrono::high_resolution_clock::now();
        elapsed = finish - start;
        std::cout << " merged " << merged << " nodes in " << elapsed.count() << " s\n";
        #endif
    }
    finish = std::chrono::high_resolution_clock::now();
    elapsed = finish - start;
    std::cout << "# OPTIMISATIONS COMPLETED in " << elapsed.count() << " s\n";
//========================================================================================================
    ////// OPTIMISATIONS
    std::cout << "# OPTIMISATIONS" << std::endl;
    start = std::chrono::high_resolution_clock::now();
    // stats
    uint merged = 0;

    std::set<std::pair<uint, uint>> vertexes_to_remove;
    boost::graph_traits < boost::adjacency_list <> >::adjacency_iterator ai, a_end;
    boost::graph_traits < boost::adjacency_list <> >::adjacency_iterator bi, b_end;
    boost::graph_traits < boost::adjacency_list <> >::adjacency_iterator ci, c_end;
    
    // iterates all the levels (one level per criterium)
    for (auto level = ++(vertexes.rbegin()); level != vertexes.rend(); ++level)
    {
        #ifdef _DEBUG
        std::cout << "level " << (level->first);
        start = std::chrono::high_resolution_clock::now();
        #endif
        merged = 0;
        // iterates all the values
        for (auto value_id : vertexes[level->first])
        {
            // TODO: check why using the "auto" form misses some merges! (227 instead of 234)
            // iterates all the nodes with this value within this level
            //for (auto vertex = vertexes[level->first][value_id.first].rbegin(); vertex != vertexes[level->first][value_id.first].rend(); ++vertex)
            for (auto& vertex : vertexes[level->first][value_id.first])
            {
                // skip if already merged
                if (labels[vertex] == "")
                    continue;

                boost::tie(ci, c_end) = adjacent_vertices(vertex, g);
                // for (auto& aux : vertexes[level->first][value_id.first])
                // compare to all the other nodes with same value (within same level)
                //for (auto aux = std::next(vertex); aux != vertexes[level->first][value_id.first].rend(); ++aux)
                for (auto& aux : vertexes[level->first][value_id.first])
                {
                    if (aux <= vertex)
                        continue;

                    // skip if already merged
                    if (labels[aux] == "")
                        continue;

                    bool equal = true;

                    // Check if both nodes point to the same nodes
                    boost::tie(ai, a_end) = boost::tie(ci, c_end);
                    boost::tie(bi, b_end) = adjacent_vertices(aux, g);

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
                        for (auto cr : parents_of[aux])
                        {
                            #ifdef _DEBUG
                            std::cout << "replacing edge [" << cr << "]-[" << *aux;
                            std::cout << "] to [" << cr << "]-[" << *vertex << "]" << std::endl;
                            std::cout << "[" << cr << "] " << netIS[cr] << " & " << netIS_bwd[cr] << std::endl;
                            #endif
                            boost::remove_edge(cr, aux, g);
                            boost::add_edge(cr, vertex, g);
                        }
                        parents_of[aux].clear();

                        #ifdef _DEBUG
                        std::cout << "[" << *aux << "] " << netIS[*aux] << " & " << netIS_bwd[*aux] << std::endl;
                        std::cout << "[" << *vertex << "] " << netIS[*vertex] << " & " << netIS_bwd[*vertex] << std::endl;
                        boost::tie(bi, b_end) = boost::adjacent_vertices(*aux, g);
                        for (; bi != b_end; ++bi)
                            std::cout << "pointing to [" << *bi << "] " << netIS[*bi] << " & " << netIS_bwd[*bi] << std::endl;
                        #endif

                        vertexes_to_remove.insert(std::make_pair(aux, level->first));
                        labels[aux] = "";
                        merged++;
                        //{std::ofstream maoe("automaton" + std::to_string(filec++) + ".dot");
                        //boost::write_graphviz(maoe, g, boost::make_label_writer(&labels[0]));}
                        //std::cout << std::endl;
                        // rename vertex netIS/netSI ?
                    }
                }
            }
        }
        #ifdef _DEBUG
        finish = std::chrono::high_resolution_clock::now();
        elapsed = finish - start;
        std::cout << " merged " << merged << " nodes in " << elapsed.count() << " s\n";
        #endif
    }
    finish = std::chrono::high_resolution_clock::now();
    elapsed = finish - start;
    std::cout << "# OPTIMISATIONS COMPLETED in " << elapsed.count() << " s\n";