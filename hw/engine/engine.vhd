library ieee;
use ieee.std_logic_1164.all;

library bre;
use bre.engine_pkg.all;
use bre.core_pkg.all;

library tools;
use tools.std_pkg.all;

entity engine is
    port (
        clk_i             :  in std_logic;
        rst_i             :  in std_logic; -- rst low active
        --
        query_i           :  in query_in_array_type;
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
        result_value_o    : out std_logic_vector(CFG_MEM_ADDR_WIDTH - 1 downto 0);
        --
        stats_idle_time_o : out std_logic_vector(CFG_DBG_COUNTERS_WIDTH - 1 downto 0)
    );
end engine;

architecture behavioural of engine is
    type CORE_PARAM_ARRAY is array (0 to CFG_ENGINE_NCRITERIA - 1) of core_parameters_type;

    -- CORE PARAMETERS
    constant CORE_PARAM_0 : core_parameters_type := (
        G_RAM_DEPTH           => 4096,
        G_MATCH_STRCT         => STRCT_SIMPLE,
        G_MATCH_FUNCTION_A    => FNCTR_SIMP_EQU,
        G_MATCH_FUNCTION_B    => FNCTR_SIMP_NOP,
        G_MATCH_FUNCTION_PAIR => FNCTR_PAIR_NOP,
        G_MATCH_MODE          => MODE_STRICT_MATCH,
        G_WEIGHT              => 0,
        G_WILDCARD_ENABLED    => '0'
    );
    constant CORE_PARAM_1 : core_parameters_type := (
        G_RAM_DEPTH           => 4096,
        G_MATCH_STRCT         => STRCT_SIMPLE,
        G_MATCH_FUNCTION_A    => FNCTR_SIMP_EQU,
        G_MATCH_FUNCTION_B    => FNCTR_SIMP_NOP,
        G_MATCH_FUNCTION_PAIR => FNCTR_PAIR_NOP,
        G_MATCH_MODE          => MODE_STRICT_MATCH,
        G_WEIGHT              => 0,
        G_WILDCARD_ENABLED    => '0'
    );
    constant CORE_PARAM_2 : core_parameters_type := (
        G_RAM_DEPTH           => 8192,
        G_MATCH_STRCT         => STRCT_SIMPLE,
        G_MATCH_FUNCTION_A    => FNCTR_SIMP_EQU,
        G_MATCH_FUNCTION_B    => FNCTR_SIMP_NOP,
        G_MATCH_FUNCTION_PAIR => FNCTR_PAIR_NOP,
        G_MATCH_MODE          => MODE_STRICT_MATCH,
        G_WEIGHT              => 512,
        G_WILDCARD_ENABLED    => '1'
    );
    constant CORE_PARAM_3 : core_parameters_type := (
        G_RAM_DEPTH           => 8192,
        G_MATCH_STRCT         => STRCT_SIMPLE,
        G_MATCH_FUNCTION_A    => FNCTR_SIMP_EQU,
        G_MATCH_FUNCTION_B    => FNCTR_SIMP_NOP,
        G_MATCH_FUNCTION_PAIR => FNCTR_PAIR_NOP,
        G_MATCH_MODE          => MODE_STRICT_MATCH,
        G_WEIGHT              => 524288,
        G_WILDCARD_ENABLED    => '1'
    );
    constant CORE_PARAM_4 : core_parameters_type := (
        G_RAM_DEPTH           => 16384,
        G_MATCH_STRCT         => STRCT_PAIR,
        G_MATCH_FUNCTION_A    => FNCTR_SIMP_GEQ,
        G_MATCH_FUNCTION_B    => FNCTR_SIMP_LEQ,
        G_MATCH_FUNCTION_PAIR => FNCTR_PAIR_AND,
        G_MATCH_MODE          => MODE_FULL_ITERATION,
        G_WEIGHT              => 256,
        G_WILDCARD_ENABLED    => '1'
    );
    constant CORE_PARAM_5 : core_parameters_type := (
        G_RAM_DEPTH           => 32768,
        G_MATCH_STRCT         => STRCT_PAIR,
        G_MATCH_FUNCTION_A    => FNCTR_SIMP_GEQ,
        G_MATCH_FUNCTION_B    => FNCTR_SIMP_LEQ,
        G_MATCH_FUNCTION_PAIR => FNCTR_PAIR_AND,
        G_MATCH_MODE          => MODE_FULL_ITERATION,
        G_WEIGHT              => 262144,
        G_WILDCARD_ENABLED    => '1'
    );
    constant CORE_PARAM_6 : core_parameters_type := (
        G_RAM_DEPTH           => 16384,
        G_MATCH_STRCT         => STRCT_SIMPLE,
        G_MATCH_FUNCTION_A    => FNCTR_SIMP_EQU,
        G_MATCH_FUNCTION_B    => FNCTR_SIMP_NOP,
        G_MATCH_FUNCTION_PAIR => FNCTR_PAIR_NOP,
        G_MATCH_MODE          => MODE_STRICT_MATCH,
        G_WEIGHT              => 65536,
        G_WILDCARD_ENABLED    => '1'
    );
    constant CORE_PARAM_7 : core_parameters_type := (
        G_RAM_DEPTH           => 16384,
        G_MATCH_STRCT         => STRCT_SIMPLE,
        G_MATCH_FUNCTION_A    => FNCTR_SIMP_EQU,
        G_MATCH_FUNCTION_B    => FNCTR_SIMP_NOP,
        G_MATCH_FUNCTION_PAIR => FNCTR_PAIR_NOP,
        G_MATCH_MODE          => MODE_STRICT_MATCH,
        G_WEIGHT              => 64,
        G_WILDCARD_ENABLED    => '1'
    );
    constant CORE_PARAM_8 : core_parameters_type := (
        G_RAM_DEPTH           => 16384,
        G_MATCH_STRCT         => STRCT_PAIR,
        G_MATCH_FUNCTION_A    => FNCTR_SIMP_GEQ,
        G_MATCH_FUNCTION_B    => FNCTR_SIMP_LEQ,
        G_MATCH_FUNCTION_PAIR => FNCTR_PAIR_AND,
        G_MATCH_MODE          => MODE_FULL_ITERATION,
        G_WEIGHT              => 1,
        G_WILDCARD_ENABLED    => '1'
    );
    constant CORE_PARAM_9 : core_parameters_type := (
        G_RAM_DEPTH           => 32768,
        G_MATCH_STRCT         => STRCT_SIMPLE,
        G_MATCH_FUNCTION_A    => FNCTR_SIMP_EQU,
        G_MATCH_FUNCTION_B    => FNCTR_SIMP_NOP,
        G_MATCH_FUNCTION_PAIR => FNCTR_PAIR_NOP,
        G_MATCH_MODE          => MODE_STRICT_MATCH,
        G_WEIGHT              => 128,
        G_WILDCARD_ENABLED    => '1'
    );
    constant CORE_PARAM_10 : core_parameters_type := (
        G_RAM_DEPTH           => 32768,
        G_MATCH_STRCT         => STRCT_SIMPLE,
        G_MATCH_FUNCTION_A    => FNCTR_SIMP_EQU,
        G_MATCH_FUNCTION_B    => FNCTR_SIMP_NOP,
        G_MATCH_FUNCTION_PAIR => FNCTR_PAIR_NOP,
        G_MATCH_MODE          => MODE_STRICT_MATCH,
        G_WEIGHT              => 131072,
        G_WILDCARD_ENABLED    => '1'
    );
    constant CORE_PARAM_11 : core_parameters_type := (
        G_RAM_DEPTH           => 32768,
        G_MATCH_STRCT         => STRCT_SIMPLE,
        G_MATCH_FUNCTION_A    => FNCTR_SIMP_EQU,
        G_MATCH_FUNCTION_B    => FNCTR_SIMP_NOP,
        G_MATCH_FUNCTION_PAIR => FNCTR_PAIR_NOP,
        G_MATCH_MODE          => MODE_STRICT_MATCH,
        G_WEIGHT              => 16,
        G_WILDCARD_ENABLED    => '1'
    );
    constant CORE_PARAM_12 : core_parameters_type := (
        G_RAM_DEPTH           => 16384,
        G_MATCH_STRCT         => STRCT_SIMPLE,
        G_MATCH_FUNCTION_A    => FNCTR_SIMP_EQU,
        G_MATCH_FUNCTION_B    => FNCTR_SIMP_NOP,
        G_MATCH_FUNCTION_PAIR => FNCTR_PAIR_NOP,
        G_MATCH_MODE          => MODE_STRICT_MATCH,
        G_WEIGHT              => 16384,
        G_WILDCARD_ENABLED    => '1'
    );
    constant CORE_PARAM_13 : core_parameters_type := (
        G_RAM_DEPTH           => 8192,
        G_MATCH_STRCT         => STRCT_SIMPLE,
        G_MATCH_FUNCTION_A    => FNCTR_SIMP_EQU,
        G_MATCH_FUNCTION_B    => FNCTR_SIMP_NOP,
        G_MATCH_FUNCTION_PAIR => FNCTR_PAIR_NOP,
        G_MATCH_MODE          => MODE_STRICT_MATCH,
        G_WEIGHT              => 2,
        G_WILDCARD_ENABLED    => '1'
    );
    constant CORE_PARAM_14 : core_parameters_type := (
        G_RAM_DEPTH           => 16384,
        G_MATCH_STRCT         => STRCT_SIMPLE,
        G_MATCH_FUNCTION_A    => FNCTR_SIMP_EQU,
        G_MATCH_FUNCTION_B    => FNCTR_SIMP_NOP,
        G_MATCH_FUNCTION_PAIR => FNCTR_PAIR_NOP,
        G_MATCH_MODE          => MODE_STRICT_MATCH,
        G_WEIGHT              => 4,
        G_WILDCARD_ENABLED    => '1'
    );
    constant CORE_PARAM_15 : core_parameters_type := (
        G_RAM_DEPTH           => 16384,
        G_MATCH_STRCT         => STRCT_SIMPLE,
        G_MATCH_FUNCTION_A    => FNCTR_SIMP_EQU,
        G_MATCH_FUNCTION_B    => FNCTR_SIMP_NOP,
        G_MATCH_FUNCTION_PAIR => FNCTR_PAIR_NOP,
        G_MATCH_MODE          => MODE_STRICT_MATCH,
        G_WEIGHT              => 4096,
        G_WILDCARD_ENABLED    => '1'
    );
    constant CORE_PARAM_16 : core_parameters_type := (
        G_RAM_DEPTH           => 8192,
        G_MATCH_STRCT         => STRCT_SIMPLE,
        G_MATCH_FUNCTION_A    => FNCTR_SIMP_EQU,
        G_MATCH_FUNCTION_B    => FNCTR_SIMP_NOP,
        G_MATCH_FUNCTION_PAIR => FNCTR_PAIR_NOP,
        G_MATCH_MODE          => MODE_STRICT_MATCH,
        G_WEIGHT              => 2048,
        G_WILDCARD_ENABLED    => '1'
    );
    constant CORE_PARAM_17 : core_parameters_type := (
        G_RAM_DEPTH           => 4096,
        G_MATCH_STRCT         => STRCT_SIMPLE,
        G_MATCH_FUNCTION_A    => FNCTR_SIMP_EQU,
        G_MATCH_FUNCTION_B    => FNCTR_SIMP_NOP,
        G_MATCH_FUNCTION_PAIR => FNCTR_PAIR_NOP,
        G_MATCH_MODE          => MODE_STRICT_MATCH,
        G_WEIGHT              => 32768,
        G_WILDCARD_ENABLED    => '1'
    );
    constant CORE_PARAM_18 : core_parameters_type := (
        G_RAM_DEPTH           => 4096,
        G_MATCH_STRCT         => STRCT_SIMPLE,
        G_MATCH_FUNCTION_A    => FNCTR_SIMP_EQU,
        G_MATCH_FUNCTION_B    => FNCTR_SIMP_NOP,
        G_MATCH_FUNCTION_PAIR => FNCTR_PAIR_NOP,
        G_MATCH_MODE          => MODE_STRICT_MATCH,
        G_WEIGHT              => 32,
        G_WILDCARD_ENABLED    => '1'
    );
    constant CORE_PARAM_19 : core_parameters_type := (
        G_RAM_DEPTH           => 8192,
        G_MATCH_STRCT         => STRCT_SIMPLE,
        G_MATCH_FUNCTION_A    => FNCTR_SIMP_EQU,
        G_MATCH_FUNCTION_B    => FNCTR_SIMP_NOP,
        G_MATCH_FUNCTION_PAIR => FNCTR_PAIR_NOP,
        G_MATCH_MODE          => MODE_STRICT_MATCH,
        G_WEIGHT              => 0,
        G_WILDCARD_ENABLED    => '0'
    );
    constant CORE_PARAM_20 : core_parameters_type := (
        G_RAM_DEPTH           => 1024,
        G_MATCH_STRCT         => STRCT_SIMPLE,
        G_MATCH_FUNCTION_A    => FNCTR_SIMP_EQU,
        G_MATCH_FUNCTION_B    => FNCTR_SIMP_NOP,
        G_MATCH_FUNCTION_PAIR => FNCTR_PAIR_NOP,
        G_MATCH_MODE          => MODE_STRICT_MATCH,
        G_WEIGHT              => 8192,
        G_WILDCARD_ENABLED    => '1'
    );
    constant CORE_PARAM_21 : core_parameters_type := (
        G_RAM_DEPTH           => 512,
        G_MATCH_STRCT         => STRCT_SIMPLE,
        G_MATCH_FUNCTION_A    => FNCTR_SIMP_EQU,
        G_MATCH_FUNCTION_B    => FNCTR_SIMP_NOP,
        G_MATCH_FUNCTION_PAIR => FNCTR_PAIR_NOP,
        G_MATCH_MODE          => MODE_STRICT_MATCH,
        G_WEIGHT              => 8,
        G_WILDCARD_ENABLED    => '1'
    );

    constant CFG_CORE_PARAM_ARRAY : CORE_PARAM_ARRAY := (
        CORE_PARAM_0,  CORE_PARAM_1,  CORE_PARAM_2,  CORE_PARAM_3,  CORE_PARAM_4,  CORE_PARAM_5, 
        CORE_PARAM_6,  CORE_PARAM_7,  CORE_PARAM_8,  CORE_PARAM_9,  CORE_PARAM_10, CORE_PARAM_11,
        CORE_PARAM_12, CORE_PARAM_13, CORE_PARAM_14, CORE_PARAM_15, CORE_PARAM_16, CORE_PARAM_17,
        CORE_PARAM_18, CORE_PARAM_19, CORE_PARAM_20, CORE_PARAM_21
    );

    -- CORE INTERFACE ARRAYS
    type edge_buffer_array  is array (CFG_ENGINE_NCRITERIA - 1 downto 0) of edge_buffer_type;
    type edge_buffer_arrayp1 is array (CFG_ENGINE_NCRITERIA downto 0) of edge_buffer_type;
    type edge_store_array   is array (CFG_ENGINE_NCRITERIA - 1 downto 0) of edge_store_type;
    type weight_array       is array (CFG_ENGINE_NCRITERIA - 1 downto 0) of integer;
    type mem_addr_array     is array (CFG_ENGINE_NCRITERIA - 1 downto 0) of std_logic_vector(CFG_MEM_ADDR_WIDTH - 1 downto 0);
    type mem_data_array     is array (CFG_ENGINE_NCRITERIA - 1 downto 0) of std_logic_vector(CFG_EDGE_BRAM_WIDTH - 1 downto 0);
    type query_buffer_array is array (CFG_ENGINE_NCRITERIA - 1 downto 0) of query_buffer_type;
    --
    signal idle            : std_logic_vector(0 to CFG_ENGINE_NCRITERIA - 1);
    signal prev_empty      : std_logic_vector(0 to CFG_ENGINE_NCRITERIA);
    signal prev_read       : std_logic_vector(0 to CFG_ENGINE_NCRITERIA);
    signal prev_data       : edge_buffer_arrayp1;
    signal query           : query_buffer_array;
    signal query_full      : std_logic_vector(0 to CFG_ENGINE_NCRITERIA - 1);
    signal query_empty     : std_logic_vector(0 to CFG_ENGINE_NCRITERIA - 1);
    signal query_read      : std_logic_vector(0 to CFG_ENGINE_NCRITERIA - 1);
    signal weight_filter   : weight_array;
    signal weight_driver   : weight_array;
    signal mem_edge        : edge_store_array;
    signal mem_addr        : mem_addr_array;
    signal mem_en          : std_logic_vector(0 to CFG_ENGINE_NCRITERIA - 1);
    signal next_full       : std_logic_vector(0 to CFG_ENGINE_NCRITERIA - 1);
    signal next_data       : edge_buffer_array;
    signal next_write      : std_logic_vector(0 to CFG_ENGINE_NCRITERIA - 1);
    -- result reducer
    signal resred_value    : edge_buffer_type;
    --
    signal sig_engine_idle : std_logic;
    signal sig_engine_time : std_logic_vector(CFG_DBG_COUNTERS_WIDTH - 1 downto 0);
    --
    -- BRAM INTERFACE ARRAYS
    signal uram_rd_data    : mem_data_array;
    --
    -- CORNER CASE SIGNALS
    signal sig_origin_node : edge_buffer_type;
begin

----------------------------------------------------------------------------------------------------
-- NFA-BRE ENGINE TOP LEVEL                                                                       --
----------------------------------------------------------------------------------------------------

gen_stages: for I in 0 to CFG_ENGINE_NCRITERIA - 1 generate
    
    mem_edge(I) <= deserialise_edge_store(uram_rd_data(I));

    buff_query_g : buffer_query generic map
    (
        G_DEPTH         => CFG_EDGE_BUFFERS_DEPTH
    )
    port map
    (
        rst_i           => rst_i,
        clk_i           => clk_i,
        --
        wr_en_i         => query_wr_en_i,
        wr_data_i       => query_i(I),
        full_o          => query_full(I),
        --
        rd_en_i         => query_read(I),
        rd_data_o       => query(I),
        empty_o         => query_empty(I)
    );

    pe_g : core generic map
    (
        G_MATCH_STRCT         => CFG_CORE_PARAM_ARRAY(I).G_MATCH_STRCT,
        G_MATCH_FUNCTION_A    => CFG_CORE_PARAM_ARRAY(I).G_MATCH_FUNCTION_A,
        G_MATCH_FUNCTION_B    => CFG_CORE_PARAM_ARRAY(I).G_MATCH_FUNCTION_B,
        G_MATCH_FUNCTION_PAIR => CFG_CORE_PARAM_ARRAY(I).G_MATCH_FUNCTION_PAIR,
        G_MATCH_MODE          => CFG_CORE_PARAM_ARRAY(I).G_MATCH_MODE,
        G_WEIGHT              => CFG_CORE_PARAM_ARRAY(I).G_WEIGHT,
        G_WILDCARD_ENABLED    => CFG_CORE_PARAM_ARRAY(I).G_WILDCARD_ENABLED
    )
    port map
    (
        rst_i           => rst_i,
        clk_i           => clk_i,
        idle_o          => idle(I),
        -- FIFO buffer from previous level
        prev_empty_i    => prev_empty(I),
        prev_data_i     => prev_data(I),
        prev_read_o     => prev_read(I),
        -- FIFO query buffer
        query_i         => query(I),
        query_empty_i   => query_empty(I),
        query_read_o    => query_read(I),
        --
        weight_filter_i => weight_filter(I),
        weight_filter_o => weight_driver(I),
        -- MEMORY
        mem_edge_i      => mem_edge(I),
        mem_addr_o      => mem_addr(I),
        mem_en_o        => mem_en(I),
        -- FIFO buffer to next level
        next_full_i     => next_full(I),
        next_data_o     => next_data(I),
        next_write_o    => next_write(I)
    );

    uram_g : uram_wrapper generic map
    (
        G_RAM_WIDTH     => CFG_EDGE_BRAM_WIDTH,
        G_RAM_DEPTH     => CFG_CORE_PARAM_ARRAY(I).G_RAM_DEPTH
    )
    port map
    (
        clk_i           => clk_i,
        rd_en_i         => mem_en(I),
        rd_addr_i       => mem_addr(I)(clogb2(CFG_CORE_PARAM_ARRAY(I).G_RAM_DEPTH)-1 downto 0),
        rd_data_o       => uram_rd_data(I),
        wr_en_i         => mem_wren_i(I),
        wr_addr_i       => mem_addr_i(clogb2(CFG_CORE_PARAM_ARRAY(I).G_RAM_DEPTH)-1 downto 0),
        wr_data_i       => mem_i
    );
    
    -- gen_fwd : if I /= CFG_ENGINE_NCRITERIA - 1 generate -- from I to I+1
    -- 
    --     weight_filter(I) <= weight_driver(CFG_ENGINE_NCRITERIA - 1);
    -- 
    -- end generate gen_fwd;

    buff_edge_g : buffer_edge generic map
    (
        G_DEPTH         => CFG_EDGE_BUFFERS_DEPTH
    )
    port map
    (
        rst_i           => rst_i,
        clk_i           => clk_i,
        --
        wr_en_i         => next_write(I),
        wr_data_i       => next_data(I),
        full_o          => next_full(I),
        --
        rd_en_i         => prev_read(I+1),
        rd_data_o       => prev_data(I+1),
        empty_o         => prev_empty(I+1)
    );

end generate gen_stages;

----------------------------------------------------------------------------------------------------
-- RESULT REDUCER                                                                                 --
----------------------------------------------------------------------------------------------------

reducer : result_reducer port map
(
    clk_i           => clk_i,
    rst_i           => rst_i,
    engine_idle_i   => sig_cores_idle,
    --
    interim_empty_i => prev_empty(CFG_ENGINE_NCRITERIA),
    interim_data_i  => prev_data(CFG_ENGINE_NCRITERIA),
    interim_read_o  => prev_read(CFG_ENGINE_NCRITERIA),
    -- final result to TOP
    result_ready_i  => result_ready_i,
    result_data_o   => resred_value,
    result_last_o   => result_last_o,
    result_stats_o  => result_stats_o,
    result_valid_o  => result_valid_o
);
-- TODO
-- if host's often not ready (result_ready_i), deploy a fifo so the last level is less often blocked

-- ORIGIN
sig_origin_node.query_id     <= query(0).query_id;
sig_origin_node.weight       <= 0;
sig_origin_node.clock_cycles <= (others => '0');
prev_empty(0) <= query_empty(0);
prev_data(0)  <= sig_origin_node;

-- LAST
query_ready_o  <= not query_full(CFG_ENGINE_NCRITERIA - 1);
result_value_o <= resred_value.pointer;

sig_engine_idle <= v_and(idle) and not v_or(next_write);

-- ORIGIN LOOK-UP
gen_lookup : if CFG_FIRST_CRITERION_LOOKUP generate
    sig_origin_node.pointer  <= '0' & query(0).operand;
end generate gen_lookup;

gen_lookup_n : if not CFG_FIRST_CRITERION_LOOKUP generate
    sig_origin_node.pointer  <= (others => '0');
end generate gen_lookup_n;

----------------------------------------------------------------------------------------------------
-- STATS                                                                                          --
----------------------------------------------------------------------------------------------------

-- non-idle counter
counter_computing_time: simple_counter generic map
(
    G_WIDTH   => CFG_DBG_COUNTERS_WIDTH
)
port map
(
    clk_i     => clk_i,
    rst_i     => rst_i,
    enable_i  => not sig_engine_idle,
    counter_o => sig_engine_time
);

end architecture behavioural;