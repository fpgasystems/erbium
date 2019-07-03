
entity mct_wrapper is
	port (
		clk			: in  std_logic;
		rst			: in  std_logic;

		-- paramaters
		numCriteria : in  std_logic_vector(7 downto 0);

		-- input bus
		rd_data		: in  std_logic_vector(511 downto 0);
		rd_valid 	: in  std_logic;
		rd_last		: in  std_logic;
		rd_stype	: in  std_logic;
		rd_ready	: out std_logic;

		-- output bus

		wr_data		: out std_logic_vector(511 downto 0);
		wr_valid 	: out std_logic;
		wr_ready 	: in  std_logic
	);
end mct_wrapper;

architecture behavioural of mct_wrapper is 


----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-- extract input query bus from the rd_data bus. each query is numCriteria long and every 
-- criteria is 4 bytes

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-- extract nfa edges from the input rd_data bus and assign it to the nfa_mem_data bus. 
-- Each criteria level consists of number of edges where each edge is 64-bits. edges of a single
-- criteria level are aligned at cache line boundaries. 

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-- consume the outputed mct_result and fill in a cache line to write back on the wr_data bus. 
-- A query result consists of the mct value and matching rule ID? they both occupy 32-bits. 


----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
mct_core_top: top 
	port map 
	(
		clk_i 			=> clk, 
		rst_i 			=> rst, 

		--
		query_i 		=> in_query, 
		query_wren_i 	=> in_query_wen, 
		query_full_o   	=> in_query_full, 

		--
		mem_i          	=> nfa_mem_data, 
        mem_wren_i     	=> nfa_mem_wren, 
        mem_addr_i     	=> nfa_mem_addr, 

        --
        result_ready_o 	=> mcr_result_valid, 
        result_value_o 	=> mct_result_value,
        result_query_o 	=> mct_result_ruleid,
        result_ready_i	=> mct_result_ready
	);

end architecture behavioural;