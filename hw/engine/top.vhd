library ieee;
use ieee.std_logic_1164.all;

library bre;
use bre.engine_pkg.all;
use bre.core_pkg.all;

entity top is
    port (
        clk_i          :  in std_logic;
        rst_i          :  in std_logic; -- rst low active
        --
        query_i        :  in query_in_array_type;
        query_wr_en_i  :  in std_logic;
        query_ready_o  : out std_logic;
        --
        mem_i          :  in std_logic_vector(CFG_EDGE_BRAM_WIDTH - 1 downto 0);
        mem_wren_i     :  in std_logic_vector(CFG_ENGINE_NCRITERIA - 1 downto 0);
        mem_addr_i     :  in std_logic_vector(CFG_MEM_ADDR_WIDTH - 1 downto 0);
        --
        result_ready_i :  in std_logic;
        result_valid_o : out std_logic;
        result_value_o : out std_logic_vector(CFG_MEM_ADDR_WIDTH - 1 downto 0)
    );
end top;

architecture behavioural of top is
    -- GENERICS
    type MATCH_STRCT_ARRAY          is array (CFG_ENGINE_NCRITERIA - 1 downto 0) of match_structure_type;
    type MATCH_SIMP_FUNCTION_ARRAY  is array (CFG_ENGINE_NCRITERIA - 1 downto 0) of match_simp_function;
    type MATCH_PAIR_FUNCTION_ARRAY  is array (CFG_ENGINE_NCRITERIA - 1 downto 0) of match_pair_function;
    type RAM_DEPTH_ARRAY            is array (CFG_ENGINE_NCRITERIA - 1 downto 0) of integer;
    --
    constant ary_match_struct        : MATCH_STRCT_ARRAY := (STRCT_SIMPLE,
                                                             STRCT_SIMPLE,
                                                             STRCT_SIMPLE,
                                                             STRCT_SIMPLE,
                                                             STRCT_SIMPLE,
                                                             STRCT_SIMPLE,
                                                             STRCT_SIMPLE,
                                                             STRCT_SIMPLE,
                                                             STRCT_SIMPLE,
                                                             STRCT_SIMPLE,
                                                             STRCT_SIMPLE,
                                                             STRCT_SIMPLE,
                                                             STRCT_SIMPLE,
                                                             STRCT_PAIR,
                                                             STRCT_SIMPLE,
                                                             STRCT_SIMPLE,
                                                             STRCT_PAIR,
                                                             STRCT_PAIR,
                                                             STRCT_SIMPLE,
                                                             STRCT_SIMPLE,
                                                             STRCT_SIMPLE,
                                                             STRCT_SIMPLE);
    constant ary_match_function_a    : MATCH_SIMP_FUNCTION_ARRAY := (FNCTR_SIMP_EQU,
                                                                     FNCTR_SIMP_EQU,
                                                                     FNCTR_SIMP_EQU,
                                                                     FNCTR_SIMP_EQU,
                                                                     FNCTR_SIMP_EQU,
                                                                     FNCTR_SIMP_EQU,
                                                                     FNCTR_SIMP_EQU,
                                                                     FNCTR_SIMP_EQU,
                                                                     FNCTR_SIMP_EQU,
                                                                     FNCTR_SIMP_EQU,
                                                                     FNCTR_SIMP_EQU,
                                                                     FNCTR_SIMP_EQU,
                                                                     FNCTR_SIMP_EQU,
                                                                     FNCTR_SIMP_GEQ,
                                                                     FNCTR_SIMP_EQU,
                                                                     FNCTR_SIMP_EQU,
                                                                     FNCTR_SIMP_GEQ,
                                                                     FNCTR_SIMP_GEQ,
                                                                     FNCTR_SIMP_EQU,
                                                                     FNCTR_SIMP_EQU,
                                                                     FNCTR_SIMP_EQU,
                                                                     FNCTR_SIMP_EQU);
    constant ary_match_function_b    : MATCH_SIMP_FUNCTION_ARRAY := (FNCTR_SIMP_NOP,
                                                                     FNCTR_SIMP_NOP,
                                                                     FNCTR_SIMP_NOP,
                                                                     FNCTR_SIMP_NOP,
                                                                     FNCTR_SIMP_NOP,
                                                                     FNCTR_SIMP_NOP,
                                                                     FNCTR_SIMP_NOP,
                                                                     FNCTR_SIMP_NOP,
                                                                     FNCTR_SIMP_NOP,
                                                                     FNCTR_SIMP_NOP,
                                                                     FNCTR_SIMP_NOP,
                                                                     FNCTR_SIMP_NOP,
                                                                     FNCTR_SIMP_NOP,
                                                                     FNCTR_SIMP_LEQ,
                                                                     FNCTR_SIMP_NOP,
                                                                     FNCTR_SIMP_NOP,
                                                                     FNCTR_SIMP_LEQ,
                                                                     FNCTR_SIMP_LEQ,
                                                                     FNCTR_SIMP_NOP,
                                                                     FNCTR_SIMP_NOP,
                                                                     FNCTR_SIMP_NOP,
                                                                     FNCTR_SIMP_NOP);
    constant ary_match_function_pair : MATCH_PAIR_FUNCTION_ARRAY := (FNCTR_PAIR_NOP,
                                                                     FNCTR_PAIR_NOP,
                                                                     FNCTR_PAIR_NOP,
                                                                     FNCTR_PAIR_NOP,
                                                                     FNCTR_PAIR_NOP,
                                                                     FNCTR_PAIR_NOP,
                                                                     FNCTR_PAIR_NOP,
                                                                     FNCTR_PAIR_NOP,
                                                                     FNCTR_PAIR_NOP,
                                                                     FNCTR_PAIR_NOP,
                                                                     FNCTR_PAIR_NOP,
                                                                     FNCTR_PAIR_NOP,
                                                                     FNCTR_PAIR_NOP,
                                                                     FNCTR_PAIR_AND,
                                                                     FNCTR_PAIR_NOP,
                                                                     FNCTR_PAIR_NOP,
                                                                     FNCTR_PAIR_AND,
                                                                     FNCTR_PAIR_AND,
                                                                     FNCTR_PAIR_NOP,
                                                                     FNCTR_PAIR_NOP,
                                                                     FNCTR_PAIR_NOP,
                                                                     FNCTR_PAIR_NOP);
--    constant ary_ram_depth : RAM_DEPTH_ARRAY := (
--                                                
--                                                );
    --
    -- CORE INTERFACE ARRAYS
    type edge_buffer_array  is array (CFG_ENGINE_NCRITERIA - 1 downto 0) of edge_buffer_type;
    type edge_store_array   is array (CFG_ENGINE_NCRITERIA - 1 downto 0) of edge_store_type;
    type weight_array       is array (CFG_ENGINE_NCRITERIA - 1 downto 0) of integer;
    type mem_addr_array     is array (CFG_ENGINE_NCRITERIA - 1 downto 0) of std_logic_vector(CFG_MEM_ADDR_WIDTH - 1 downto 0);
    type mem_data_array     is array (CFG_ENGINE_NCRITERIA - 1 downto 0) of std_logic_vector(CFG_EDGE_BRAM_WIDTH - 1 downto 0);
    type query_buffer_array is array (CFG_ENGINE_NCRITERIA - 1 downto 0) of query_buffer_type;
    --
    signal prev_empty    : std_logic_vector(0 to CFG_ENGINE_NCRITERIA - 1);
    signal prev_read     : std_logic_vector(0 to CFG_ENGINE_NCRITERIA - 1);
    signal prev_data     : edge_buffer_array;
    signal query         : query_buffer_array;
    signal query_full    : std_logic_vector(0 to CFG_ENGINE_NCRITERIA - 1);
    signal query_empty   : std_logic_vector(0 to CFG_ENGINE_NCRITERIA - 1);
    signal query_read    : std_logic_vector(0 to CFG_ENGINE_NCRITERIA - 1);
    signal weight_filter : weight_array;
    signal weight_driver : weight_array;
    signal mem_edge      : edge_store_array;
    signal mem_addr      : mem_addr_array;
    signal mem_en        : std_logic_vector(0 to CFG_ENGINE_NCRITERIA - 1);
    signal next_full     : std_logic_vector(0 to CFG_ENGINE_NCRITERIA - 1);
    signal next_data     : edge_buffer_array;
    signal next_write    : std_logic_vector(0 to CFG_ENGINE_NCRITERIA - 1);
    -- result reducer
    signal resred_value  : edge_buffer_type;
    signal resred_ready  : std_logic;
    --
    -- BRAM INTERFACE ARRAYS
    signal uram_rd_data  : mem_data_array;
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
        G_MATCH_STRCT         => ary_match_struct(I),
        G_MATCH_FUNCTION_A    => ary_match_function_a(I),
        G_MATCH_FUNCTION_B    => ary_match_function_b(I),
        G_MATCH_FUNCTION_PAIR => ary_match_function_pair(I)
    )
    port map
    (
        rst_i           => rst_i,
        clk_i           => clk_i,
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
        G_RAM_DEPTH     => CFG_EDGE_BRAM_DEPTH
    )
    port map
    (
        clk_i           => clk_i,
        rd_en_i         => mem_en(I),
        rd_addr_i       => mem_addr(I),
        rd_data_o       => uram_rd_data(I),
        wr_en_i         => mem_wren_i(I),
        wr_addr_i       => mem_addr_i,
        wr_data_i       => mem_i
    );
    
    gen_fwd : if I /= CFG_ENGINE_NCRITERIA - 1 generate -- from I to I+1

        weight_filter(I) <= weight_driver(CFG_ENGINE_NCRITERIA - 1);

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

    end generate gen_fwd;

end generate gen_stages;

----------------------------------------------------------------------------------------------------
-- RESULT REDUCER                                                                                 --
----------------------------------------------------------------------------------------------------

reducer : result_reducer port map
(
    clk_i           => clk_i,
    rst_i           => rst_i,
    --
    interim_valid_i => next_write(CFG_ENGINE_NCRITERIA - 1),
    interim_data_i  => next_data(CFG_ENGINE_NCRITERIA - 1),
    interim_ready_o => resred_ready,
    -- final result to TOP
    result_ready_i  => result_ready_i, -- TODO not used yet
    result_data_o   => resred_value,
    result_valid_o  => result_valid_o
);
-- if host's often not ready (result_ready_i), deploy a fifo so the last level is less often blocked

-- ORIGIN
sig_origin_node.pointer  <= (others => '0');
sig_origin_node.query_id <= query(0).query_id;
prev_empty(0) <= query_empty(0);
prev_data(0)  <= sig_origin_node;

-- LAST
query_ready_o  <= not query_full(CFG_ENGINE_NCRITERIA - 1);
next_full(CFG_ENGINE_NCRITERIA - 1) <= not resred_ready;
result_value_o <= resred_value.pointer;

end architecture behavioural;