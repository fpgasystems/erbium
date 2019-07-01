class NFAHandler
{
    NFAHandler(const& rulePack_s rp, const& Dictionnary dic)
    {
    	std::map<std::string, uint> path_map;   // from node_path to node_id
        std::string path_fwd;
        uint prev_id = 0;
        uint level = 0;
        uint node_to_use = 0;
    	uint stats_fwd = 0;

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
                if (path_map[path_fwd] == 0)
                {
                    // new path
                    node_to_use = add_vertex(m_graph);
                    path_map[path_fwd] = node_to_use;
                    m_graph[node_to_use].label = criterium.m_value;
                    m_graph[node_to_use].level = level;
                    m_graph[node_to_use].path = path_fwd;
                    vertexes[level][dictionnary[criterium.m_index][criterium.m_value]].insert(node_to_use);
                }
                else
                {
                    // use existing path
                    node_to_use = path_map[path_fwd];
                    stats_fwd++;
                }
                boost::remove_edge(prev_id, node_to_use, m_graph);
                boost::add_edge(prev_id, node_to_use, m_graph);
                m_graph[node_to_use].parents.insert(prev_id);
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
                vertexes[level][dictionnary[rule.m_criteria.size()][rule.m_content]].insert(node_to_use);
            }
            else
                node_to_use = path_map[rule.m_content];

            boost::remove_edge(prev_id, node_to_use, m_graph);
            boost::add_edge(prev_id, node_to_use, m_graph);
            m_graph[node_to_use].parents.insert(prev_id);
        }
    }
}