library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

library bre;
use bre.engine_pkg.all;
use bre.core_pkg.all;
USE bre.cfg_criteria.all;

library tools;
use tools.std_pkg.all;

entity engine is
    port (
        clk_i             :  in std_logic;
        rst_i             :  in std_logic; -- rst low active
        --
        query_i           :  in query_in_array_type;
        query_last_i      :  in std_logic;
        query_wr_en_i     :  in std_logic;
        query_ready_o     : out std_logic;
        --
        mem_i             :  in std_logic_vector(CFG_EDGE_BRAM_WIDTH - 1 downto 0);
        mem_wren_i        :  in std_logic_vector(CFG_ENGINE_NCRITERIA - 1 downto 0);
        mem_addr_i        :  in std_logic_vector(CFG_MEM_ADDR_WIDTH - 1 downto 0);
        --
        result_ready_i    :  in std_logic;
        result_stats_o    : out result_stats_type;
        result_valid_o    : out std_logic;
        result_last_o     : out std_logic;
        result_value_o    : out std_logic_vector(CFG_MEM_ADDR_WIDTH - 1 downto 0)
    );
end engine;

architecture behavioural of engine is
    type CORE_PARAM_ARRAY is array (0 to CFG_ENGINE_NCRITERIA - 1) of core_parameters_type;

    -- CORE INTERFACE ARRAYS
    type edge_buffer_array  is array (CFG_ENGINE_NCRITERIA - 1 downto 0) of edge_buffer_type;
    type edge_buffer_arrayp1 is array (CFG_ENGINE_NCRITERIA downto 0) of edge_buffer_type;
    type edge_store_array   is array (CFG_ENGINE_NCRITERIA - 1 downto 0) of edge_store_type;
    type mem_addr_array     is array (CFG_ENGINE_NCRITERIA - 1 downto 0) of std_logic_vector(CFG_MEM_ADDR_WIDTH - 1 downto 0);
    type mem_data_array     is array (CFG_ENGINE_NCRITERIA - 1 downto 0) of std_logic_vector(CFG_EDGE_BRAM_WIDTH - 1 downto 0);
    type query_buffer_array is array (CFG_ENGINE_NCRITERIA - 1 downto 0) of query_buffer_type;
    --
    -- CORE INTERFACE DOPIO
    type edge_buffer_dopio  is array (CFG_ENGINE_DOPIO_CORES - 1 downto 0) of edge_buffer_array;
    type edge_buffer_dopiop1 is array (CFG_ENGINE_DOPIO_CORES - 1 downto 0) of edge_buffer_arrayp1;
    type edge_store_dopio   is array (CFG_ENGINE_DOPIO_CORES - 1 downto 0) of edge_store_array;
    type mem_addr_dopio     is array (CFG_ENGINE_DOPIO_CORES - 1 downto 0) of mem_addr_array;
    type mem_data_dopio     is array (CFG_ENGINE_DOPIO_CORES - 1 downto 0) of mem_data_array;
    type query_buffer_dopio is array (CFG_ENGINE_DOPIO_CORES - 1 downto 0) of query_buffer_array;
    type ncrieria_dopio     is array (CFG_ENGINE_DOPIO_CORES - 1 downto 0) of std_logic_vector(0 to CFG_ENGINE_NCRITERIA - 1);
    type ncrieria_dopio_p1  is array (CFG_ENGINE_DOPIO_CORES - 1 downto 0) of std_logic_vector(0 to CFG_ENGINE_NCRITERIA);
    type edge_buffer_ardopio is array (CFG_ENGINE_DOPIO_CORES - 1 downto 0) of edge_buffer_type;
    type mem_data_ardopio   is array (CFG_ENGINE_DOPIO_CORES - 1 downto 0) of mem_data_array;
    type result_stats_dopio is array (CFG_ENGINE_DOPIO_CORES - 1 downto 0) of result_stats_type;
    --
    signal pe_idle         : ncrieria_dopio;
    signal prev_idle       : ncrieria_dopio;
    signal prev_empty      : ncrieria_dopio_p1;
    signal prev_read       : ncrieria_dopio_p1;
    signal prev_data       : edge_buffer_dopiop1;
    signal query           : query_buffer_dopio;
    signal query_full      : ncrieria_dopio;
    signal query_empty     : ncrieria_dopio;
    signal query_read      : ncrieria_dopio;
    signal mem_edge        : edge_store_dopio;
    signal mem_addr        : mem_addr_dopio;
    signal mem_en          : ncrieria_dopio;
    signal next_full       : ncrieria_dopio;
    signal next_data       : edge_buffer_dopio;
    signal next_write      : ncrieria_dopio;
    --
    signal query_wr_en     : std_logic_vector(CFG_ENGINE_DOPIO_CORES - 1 downto 0);
    --
    -- result reducer
    signal resred_value    : edge_buffer_ardopio;
    signal resred_stats    : result_stats_dopio;
    signal resred_valid    : std_logic_vector(CFG_ENGINE_DOPIO_CORES - 1 downto 0);
    signal resred_last     : std_logic_vector(CFG_ENGINE_DOPIO_CORES - 1 downto 0);
    signal resred_ready    : std_logic_vector(CFG_ENGINE_DOPIO_CORES - 1 downto 0);
    --
    signal sig_cores_idle  : std_logic_vector(CFG_ENGINE_DOPIO_CORES - 1 downto 0);
    --
    -- BRAM INTERFACE ARRAYS
    signal uram_rd_data    : mem_data_ardopio;
    --
    -- CORNER CASE SIGNALS
    signal sig_origin_node : edge_buffer_ardopio;
    --
    -- DOPIO
    -- type flow_ctrl_type is (FLW_CTRL_A, FLW_CTRL_B);
    type dopio_reg_type is record
        -- rd_flow_ctrl    : flow_ctrl_type;
        -- wr_flow_ctrl    : flow_ctrl_type;
        query_ready     : std_logic;
        core_running    : std_logic_vector(CFG_ENGINE_DOPIO_CORES - 1 downto 0);
        --
        query_flow_ctrl : integer range 0 to CFG_ENGINE_DOPIO_CORES;
        reslt_flow_ctrl : integer range 0 to CFG_ENGINE_DOPIO_CORES;
    end record;
    signal dopio_r, dopio_rin   : dopio_reg_type;
    signal sig_dopio_res : std_logic_vector(CFG_ENGINE_DOPIO_CORES - 1 downto 0);
begin

----------------------------------------------------------------------------------------------------
-- NFA-BRE ENGINE TOP LEVEL                                                                       --
----------------------------------------------------------------------------------------------------

gen_dopio: for D in 0 to CFG_ENGINE_DOPIO_CORES - 1 generate

  gen_stages: for I in 0 to CFG_ENGINE_NCRITERIA - 1 generate
    
    mem_edge(D)(I) <= deserialise_edge_store(uram_rd_data(D)(I));

    buff_query_g : buffer_query generic map
    (
        G_DEPTH         => CFG_EDGE_BUFFERS_DEPTH
    )
    port map
    (
        rst_i           => rst_i,
        clk_i           => clk_i,
        --
        wr_en_i         => query_wr_en(D),
        wr_data_i       => query_i(I),
        full_o          => query_full(D)(I),
        --
        rd_en_i         => query_read(D)(I),
        rd_data_o       => query(D)(I),
        empty_o         => query_empty(D)(I)
    );

    pe_g : core generic map
    (
        G_MATCH_STRCT         => CFG_CORE_PARAM_ARRAY(I).G_MATCH_STRCT,
        G_MATCH_FUNCTION_A    => CFG_CORE_PARAM_ARRAY(I).G_MATCH_FUNCTION_A,
        G_MATCH_FUNCTION_B    => CFG_CORE_PARAM_ARRAY(I).G_MATCH_FUNCTION_B,
        G_MATCH_FUNCTION_PAIR => CFG_CORE_PARAM_ARRAY(I).G_MATCH_FUNCTION_PAIR,
        G_MATCH_MODE          => CFG_CORE_PARAM_ARRAY(I).G_MATCH_MODE,
        G_MEM_RD_LATENCY      => CFG_CORE_PARAM_ARRAY(I).G_RAM_LATENCY,
        G_WEIGHT              => CFG_CORE_PARAM_ARRAY(I).G_WEIGHT,
        G_WILDCARD_ENABLED    => CFG_CORE_PARAM_ARRAY(I).G_WILDCARD_ENABLED
    )
    port map
    (
        rst_i           => rst_i,
        clk_i           => clk_i,
        idle_o          => pe_idle(D)(I),
        prev_idle_i     => prev_idle(D)(I),
        -- FIFO buffer from previous level
        prev_empty_i    => prev_empty(D)(I),
        prev_data_i     => prev_data(D)(I),
        prev_read_o     => prev_read(D)(I),
        -- FIFO query buffer
        query_i         => query(D)(I),
        query_empty_i   => query_empty(D)(I),
        query_read_o    => query_read(D)(I),
        -- MEMORY
        mem_edge_i      => mem_edge(D)(I),
        mem_addr_o      => mem_addr(D)(I),
        mem_en_o        => mem_en(D)(I),
        -- FIFO buffer to next level
        next_full_i     => next_full(D)(I),
        next_data_o     => next_data(D)(I),
        next_write_o    => next_write(D)(I)
    );

    buff_edge_g : buffer_edge generic map
    (
        G_DEPTH         => CFG_EDGE_BUFFERS_DEPTH,
        G_ALMST         => CFG_CORE_PARAM_ARRAY(I).G_RAM_LATENCY + 2
    )
    port map
    (
        rst_i           => rst_i,
        clk_i           => clk_i,
        --
        wr_en_i         => next_write(D)(I),
        wr_data_i       => next_data(D)(I),
        almost_full_o   => next_full(D)(I),
        full_o          => open,
        --
        rd_en_i         => prev_read(D)(I+1),
        rd_data_o       => prev_data(D)(I+1),
        empty_o         => prev_empty(D)(I+1)
    );

  end generate gen_stages;

    ------------------------------------------------------------------------------------------------
    -- RESULT REDUCER                                                                             --
    ------------------------------------------------------------------------------------------------

    reducer : result_reducer port map
    (
        clk_i           => clk_i,
        rst_i           => rst_i,
        engine_idle_i   => sig_cores_idle(D),
        --
        interim_empty_i => prev_empty(D)(CFG_ENGINE_NCRITERIA),
        interim_data_i  => prev_data(D)(CFG_ENGINE_NCRITERIA),
        interim_read_o  => prev_read(D)(CFG_ENGINE_NCRITERIA),
        -- final result to TOP
        result_ready_i  => resred_ready(D),
        result_data_o   => resred_value(D),
        result_last_o   => resred_last(D),
        result_stats_o  => resred_stats(D),
        result_valid_o  => resred_valid(D)
    );

    prev_idle(D) <= query_last_i & (pe_idle(D)(0 to CFG_ENGINE_NCRITERIA - 2) and not next_write(D)(0 to CFG_ENGINE_NCRITERIA - 2));

    sig_cores_idle(D) <= v_and(pe_idle(D)) and not v_or(next_write(D)) and query_last_i;

    -- ORIGIN
    sig_origin_node(D).query_id     <= query(D)(0).query_id;
    sig_origin_node(D).weight       <= (others => '0');
    sig_origin_node(D).clock_cycles <= (others => '0');
    sig_origin_node(D).has_match    <= '1';
    prev_empty(D)(0) <= query_empty(D)(0);
    prev_data(D)(0)  <= sig_origin_node(D);

    -- ORIGIN LOOK-UP
    gen_lookup : if CFG_FIRST_CRITERION_LOOKUP generate
        sig_origin_node(D).pointer  <= (CFG_MEM_ADDR_WIDTH - 1 downto CFG_CRITERION_VALUE_WIDTH => '0') & query(D)(0).operand;
    end generate gen_lookup;

    gen_lookup_n : if not CFG_FIRST_CRITERION_LOOKUP generate
        sig_origin_node(D).pointer  <= (others => '0');
    end generate gen_lookup_n;

    -- DOPIO
    query_wr_en(D) <= query_wr_en_i when dopio_r.query_flow_ctrl = D else '0';
    resred_ready(D) <= result_ready_i when dopio_r.reslt_flow_ctrl = D else '0';

end generate gen_dopio;

gen_stages_mem: for I in 0 to CFG_ENGINE_NCRITERIA - 1 generate

  gen_dp_core: if CFG_ENGINE_DOPIO_CORES = 1 generate

    uram_g : uram_wrapper generic map
    (
        G_RAM_WIDTH     => CFG_EDGE_BRAM_WIDTH,
        G_RAM_DEPTH     => CFG_CORE_PARAM_ARRAY(I).G_RAM_DEPTH,
        G_RD_LATENCY    => CFG_CORE_PARAM_ARRAY(I).G_RAM_LATENCY
    )
    port map
    (
        clk_i         => clk_i,
        core_a_en_i   => mem_en(0)(I),
        core_a_addr_i => mem_addr(0)(I)(clogb2(CFG_CORE_PARAM_ARRAY(I).G_RAM_DEPTH)-1 downto 0),
        core_a_data_o => uram_rd_data(0)(I),
        core_b_en_i   => '0',
        core_b_addr_i => (others => '0'),
        core_b_data_o => open,
        wr_en_i       => mem_wren_i(I),
        wr_addr_i     => mem_addr_i(clogb2(CFG_CORE_PARAM_ARRAY(I).G_RAM_DEPTH)-1 downto 0),
        wr_data_i     => mem_i
    );

  end generate gen_dp_core;

  gen_dp_cores: if CFG_ENGINE_DOPIO_CORES = 2 generate

    uram_g : uram_wrapper generic map
    (
        G_RAM_WIDTH     => CFG_EDGE_BRAM_WIDTH,
        G_RAM_DEPTH     => CFG_CORE_PARAM_ARRAY(I).G_RAM_DEPTH,
        G_RD_LATENCY    => CFG_CORE_PARAM_ARRAY(I).G_RAM_LATENCY
    )
    port map
    (
        clk_i         => clk_i,
        core_a_en_i   => mem_en(0)(I),
        core_a_addr_i => mem_addr(0)(I)(clogb2(CFG_CORE_PARAM_ARRAY(I).G_RAM_DEPTH)-1 downto 0),
        core_a_data_o => uram_rd_data(0)(I),
        core_b_en_i   => mem_en(1)(I),
        core_b_addr_i => mem_addr(1)(I)(clogb2(CFG_CORE_PARAM_ARRAY(I).G_RAM_DEPTH)-1 downto 0),
        core_b_data_o => uram_rd_data(1)(I),
        wr_en_i       => mem_wren_i(I),
        wr_addr_i     => mem_addr_i(clogb2(CFG_CORE_PARAM_ARRAY(I).G_RAM_DEPTH)-1 downto 0),
        wr_data_i     => mem_i
    );

  end generate gen_dp_cores;

end generate gen_stages_mem;


----------------------------------------------------------------------------------------------------
-- DOPIO ENGINE                                                                                   --
----------------------------------------------------------------------------------------------------

query_ready_o  <= dopio_rin.query_ready;

--result_last_o  <= v_or(resred_last) and not v_and(dopio_r.core_running);
result_last_o  <= not v_or((sig_dopio_res and resred_last) xor dopio_r.core_running);
result_valid_o <= v_or(resred_valid and sig_dopio_res);
result_stats_o <= resred_stats(dopio_r.reslt_flow_ctrl);
result_value_o <= resred_value(dopio_r.reslt_flow_ctrl).pointer;

sig_dopio_res <= std_logic_vector(to_unsigned(dopio_r.reslt_flow_ctrl + 1, CFG_ENGINE_DOPIO_CORES));

-- query_wr_en(0) <= query_wr_en_i when dopio_r.wr_flow_ctrl = FLW_CTRL_A else '0';
-- query_wr_en(1) <= query_wr_en_i when dopio_r.wr_flow_ctrl = FLW_CTRL_B else '0';
-- --
-- resred_ready(0) <= result_ready_i when dopio_r.rd_flow_ctrl = FLW_CTRL_A else '0';
-- resred_ready(1) <= result_ready_i when dopio_r.rd_flow_ctrl = FLW_CTRL_B else '0';
--
-- result_stats_o <= resred_stats(0) when dopio_r.rd_flow_ctrl = FLW_CTRL_A
--                   else resred_stats(1);
-- result_valid_o <= resred_valid(0) when dopio_r.rd_flow_ctrl = FLW_CTRL_A
--                   else resred_valid(1);
-- result_value_o <= resred_value(0).pointer when dopio_r.rd_flow_ctrl = FLW_CTRL_A
--                   else resred_value(1).pointer;

dopio_comb: process(dopio_r, query_wr_en_i, query_full, resred_valid, result_ready_i, resred_last)
    variable v : dopio_reg_type;
begin
    v := dopio_r;

    -- reslt_flow_ctrl
    if (resred_valid(dopio_r.reslt_flow_ctrl) and result_ready_i) = '1' then
        v.core_running(dopio_r.reslt_flow_ctrl) := not resred_last(dopio_r.reslt_flow_ctrl);
        v.reslt_flow_ctrl := dopio_r.reslt_flow_ctrl + 1;
        if v.reslt_flow_ctrl = CFG_ENGINE_DOPIO_CORES then
            v.reslt_flow_ctrl := 0;
        end if;
    end if;

    -- query_flow_ctrl
    if query_wr_en_i = '1' then
        v.core_running(dopio_r.query_flow_ctrl) := '1';
        v.query_flow_ctrl := dopio_r.query_flow_ctrl + 1;
        if v.query_flow_ctrl = CFG_ENGINE_DOPIO_CORES then
            v.query_flow_ctrl := 0;
        end if;
        v.query_ready := not query_full(v.query_flow_ctrl)(CFG_ENGINE_NCRITERIA - 1);
    else
        v.query_ready := not query_full(dopio_r.query_flow_ctrl)(CFG_ENGINE_NCRITERIA - 1);
    end if;

    -- -- rd state machine
    -- case dopio_r.rd_flow_ctrl is
    -- 
    --   when FLW_CTRL_A =>
    -- 
    --         if (resred_valid(0) and result_ready_i) = '1' then
    --             v.core_running(0) := not resred_last(0);
    --             --v.rd_flow_ctrl := FLW_CTRL_B;
    --         end if;
    -- 
    --   when FLW_CTRL_B =>
    -- 
    --         if (resred_valid(1) and result_ready_i) = '1' then
    --             v.rd_flow_ctrl := FLW_CTRL_A;
    --             v.core_running(1) := not resred_last(1);
    --         end if;
    -- 
    -- end case;

    -- wr state machine
    -- case dopio_r.wr_flow_ctrl is
    -- 
    --   when FLW_CTRL_A =>
    -- 
    --         if query_wr_en_i = '1' then
    --             v.core_running(0) := '1';
    --             --if CFG_ENGINE_DOPIO_CORES = 2 then
    --             --    v.wr_flow_ctrl := FLW_CTRL_B;
    --             --    v.query_ready := not query_full(1)(CFG_ENGINE_NCRITERIA - 1);-- from core B
    --             --else
    --                 v.query_ready := not query_full(0)(CFG_ENGINE_NCRITERIA - 1);-- from core A;
    --             --end if;
    --         else
    --             v.query_ready := not query_full(0)(CFG_ENGINE_NCRITERIA - 1);-- from core A;
    --         end if;
    -- 
    --   when FLW_CTRL_B =>
    -- 
    --         if query_wr_en_i = '1' then
    --             v.core_running(1) := '1';
    --             v.wr_flow_ctrl := FLW_CTRL_A;
    --             v.query_ready := not query_full(0)(CFG_ENGINE_NCRITERIA - 1);-- from core A;
    --         else
    --             v.query_ready := not query_full(1)(CFG_ENGINE_NCRITERIA - 1);-- from core B
    --         end if;
    -- 
    -- end case;
    
    dopio_rin <= v;
end process;

dopio_seq: process(clk_i)
begin
    if rising_edge(clk_i) then
        if rst_i = '0' then
            --dopio_r.rd_flow_ctrl <= FLW_CTRL_A;
            --dopio_r.wr_flow_ctrl <= FLW_CTRL_A;
            dopio_r.query_ready <= '0';
            dopio_r.core_running <= (others => '0');
            dopio_r.query_flow_ctrl <= 0;
            dopio_r.reslt_flow_ctrl <= 0;
        else
            dopio_r <= dopio_rin;
        end if;
    end if;
end process;

----------------------------------------------------------------------------------------------------
-- STATS                                                                                          --
----------------------------------------------------------------------------------------------------

-- sig_stats_en <= v_or(dopio_r.core_running);
-- 
-- -- non-idle counter
-- counter_computing_time: simple_counter generic map
-- (
--     G_WIDTH   => CFG_DBG_COUNTERS_WIDTH
-- )
-- port map
-- (
--     clk_i     => clk_i,
--     rst_i     => rst_i,
--     enable_i  => sig_stats_en,
--     counter_o => stats_idle_time_o
-- );
-- 
-- counter_queriesA: simple_counter generic map
-- (
--     G_WIDTH   => CFG_DBG_COUNTERS_WIDTH
-- )
-- port map
-- (
--     clk_i     => clk_i,
--     rst_i     => rst_i,
--     enable_i  => query_wr_en(0),
--     counter_o => sig_queries_a
-- );
-- 
-- counter_queriesB: simple_counter generic map
-- (
--     G_WIDTH   => CFG_DBG_COUNTERS_WIDTH
-- )
-- port map
-- (
--     clk_i     => clk_i,
--     rst_i     => rst_i,
--     enable_i  => query_wr_en(1),
--     counter_o => sig_queries_b
-- );

end architecture behavioural;