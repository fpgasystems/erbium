library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library std;
use std.textio.all;

library bre;
use bre.engine_pkg.all;

package core_pkg is

----------------------------------------------------------------------------------------------------
-- TYPES                                                                                          --
----------------------------------------------------------------------------------------------------

    -- TODO define range of integer QUERY_ID as a subtype ;)
    constant C_INIT_QUERY_ID : integer := 2**CFG_QUERY_ID_WIDTH - 1;

    type match_structure_type is (STRCT_SIMPLE, STRCT_PAIR);
    type match_pair_function is (FNCTR_PAIR_NOP, FNCTR_PAIR_AND, FNCTR_PAIR_OR, FNCTR_PAIR_XOR, FNCTR_PAIR_NAND, FNCTR_PAIR_NOR);
    type match_simp_function is (FNCTR_SIMP_NOP, FNCTR_SIMP_EQU, FNCTR_SIMP_NEQ, FNCTR_SIMP_GRT, FNCTR_SIMP_GEQ, FNCTR_SIMP_LES, FNCTR_SIMP_LEQ);
    type match_mode_type is (MODE_STRICT_MATCH, MODE_FULL_ITERATION);

    type core_flow_control is (FLW_CTRL_BUFFER, FLW_CTRL_MEM);

    type edge_store_type is record
        operand_a       : std_logic_vector(CFG_CRITERION_VALUE_WIDTH - 1 downto 0);
        operand_b       : std_logic_vector(CFG_CRITERION_VALUE_WIDTH - 1 downto 0);
        pointer         : std_logic_vector(CFG_MEM_ADDR_WIDTH - 1 downto 0);
        last            : std_logic;
    end record;

    type edge_buffer_type is record
        pointer         : std_logic_vector(CFG_MEM_ADDR_WIDTH - 1 downto 0);
        query_id        : integer range 0 to 2**CFG_QUERY_ID_WIDTH - 1;
        weight          : std_logic_vector(CFG_WEIGHT_WIDTH - 1 downto 0);
        clock_cycles    : std_logic_vector(CFG_DBG_N_OF_CLK_CYCS_WIDTH - 1 downto 0);
        has_match       : std_logic;
    end record;

    type query_buffer_type is record
        operand         : std_logic_vector(CFG_CRITERION_VALUE_WIDTH - 1 downto 0);
        query_id        : integer range 0 to 2**CFG_QUERY_ID_WIDTH - 1;
    end record;
    type query_in_array_type is array(0 to CFG_ENGINE_NCRITERIA - 1) of query_buffer_type;

    type query_flow_type is record
        read_en         : std_logic;
        query           : query_buffer_type;
        first           : std_logic;
    end record;

    type fetch_out_type is record
        buffer_rd_en    : std_logic;
        mem_rd_en       : std_logic;
        mem_addr        : std_logic_vector(CFG_MEM_ADDR_WIDTH - 1 downto 0);
        flow_ctrl       : core_flow_control;
        query_id        : integer range 0 to 2**CFG_QUERY_ID_WIDTH - 1;
        weight          : std_logic_vector(CFG_WEIGHT_WIDTH - 1 downto 0);
        clock_cycles    : std_logic_vector(CFG_DBG_N_OF_CLK_CYCS_WIDTH - 1 downto 0);
        idle            : std_logic;
    end record;

    type execute_out_type is record
        inference_res   : std_logic;
        writing_edge    : edge_buffer_type;
        has_match       : std_logic;
        empty           : std_logic;
    end record;

    type mem_out_type is record
        rd_addr         : std_logic_vector(CFG_MEM_ADDR_WIDTH - 1 downto 0);
        rd_en           : std_logic;
        wr_addr         : std_logic_vector(CFG_MEM_ADDR_WIDTH - 1 downto 0);
        wr_en           : std_logic;
        wr_data         : edge_store_type;
    end record;

    type core_parameters_type is record
        G_RAM_DEPTH           : integer;
        G_RAM_LATENCY         : integer;
        G_MATCH_STRCT         : match_structure_type;
        G_MATCH_FUNCTION_A    : match_simp_function;
        G_MATCH_FUNCTION_B    : match_simp_function;
        G_MATCH_FUNCTION_PAIR : match_pair_function;
        G_MATCH_MODE          : match_mode_type;
        G_WEIGHT              : std_logic_vector(CFG_WEIGHT_WIDTH - 1 downto 0);
        G_WILDCARD_ENABLED    : std_logic;
    end record;

----------------------------------------------------------------------------------------------------
-- COMPONENTS                                                                                     --
----------------------------------------------------------------------------------------------------

    component functor is
        generic (
            G_FUNCTION          : match_simp_function  := FNCTR_SIMP_NOP;
            G_WILDCARD          : std_logic            := '0'
        );
        port (
            rule_i              :  in std_logic_vector(CFG_CRITERION_VALUE_WIDTH-1 downto 0);
            query_i             :  in std_logic_vector(CFG_CRITERION_VALUE_WIDTH-1 downto 0);
            funct_o             : out std_logic;
            stopscan_o          : out std_logic;
            wildcard_o          : out std_logic
        );
    end component;

    component matcher is
        generic (
            G_STRUCTURE         : match_structure_type := STRCT_SIMPLE;
            G_FUNCTION_A        : match_simp_function  := FNCTR_SIMP_NOP;
            G_FUNCTION_B        : match_simp_function  := FNCTR_SIMP_NOP;
            G_FUNCTION_PAIR     : match_pair_function  := FNCTR_PAIR_NOP;
            G_WILDCARD          : std_logic            := '0'
        );
        port (
            op_query_i          :  in std_logic_vector(CFG_CRITERION_VALUE_WIDTH-1 downto 0);
            opA_rule_i          :  in std_logic_vector(CFG_CRITERION_VALUE_WIDTH-1 downto 0);
            opB_rule_i          :  in std_logic_vector(CFG_CRITERION_VALUE_WIDTH-1 downto 0);
            match_result_o      : out std_logic;
            stopscan_o          : out std_logic;
            wildcard_o          : out std_logic
        );
    end component;

    component bram_edge_store is
        generic (
            G_RAM_WIDTH : integer := 64;                      -- Specify RAM witdh (number of bits per row)
            G_RAM_DEPTH : integer := 1024;                    -- Specify RAM depth (number of entries)
            G_RAM_PERFORMANCE : string := "LOW_LATENCY";      -- Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
            G_INIT_FILE : string := "RAM_INIT.dat"            -- Specify name/location of RAM initialization file if using one (leave blank if not)
        );
        port (
            clk_i        :  in std_logic;
            ram_reg_en_i :  in std_logic; -- Output register enable
            ram_en_i     :  in std_logic; -- RAM Enable, for additional power savings, disable port when not in use
            addr_i       :  in std_logic_vector(CFG_MEM_ADDR_WIDTH - 1 downto 0);
            wr_data_i    :  in edge_store_type;
            wr_en_i      :  in std_logic;
            rd_data_o    : out edge_store_type
        );
    end component;

    component core is
        generic (
            G_MATCH_STRCT         : match_structure_type := STRCT_SIMPLE;
            G_MATCH_FUNCTION_A    : match_simp_function  := FNCTR_SIMP_NOP;
            G_MATCH_FUNCTION_B    : match_simp_function  := FNCTR_SIMP_NOP;
            G_MATCH_FUNCTION_PAIR : match_pair_function  := FNCTR_PAIR_NOP;
            G_MATCH_MODE          : match_mode_type      := MODE_FULL_ITERATION;
            G_MEM_RD_LATENCY      : integer              := 2;
            G_WEIGHT              : std_logic_vector(CFG_WEIGHT_WIDTH - 1 downto 0) := (others=>'0');
            G_WILDCARD_ENABLED    : std_logic            := '1'
        );
        port (
            clk_i           :  in std_logic;
            rst_i           :  in std_logic; -- low active
            idle_o          : out std_logic;
            prev_idle_i     :  in std_logic;
            -- FIFO edge buffer from previous level
            prev_empty_i    :  in std_logic;
            prev_data_i     :  in edge_buffer_type;
            prev_read_o     : out std_logic;
            -- FIFO query buffer
            query_i         :  in query_buffer_type;
            query_empty_i   :  in std_logic;
            query_read_o    : out std_logic;
            -- MEMORY
            mem_edge_i      :  in edge_store_type;
            mem_addr_o      : out std_logic_vector(CFG_MEM_ADDR_WIDTH - 1 downto 0);
            mem_en_o        : out std_logic;
            -- FIFO edge buffer to next level
            next_full_i     :  in std_logic;
            next_data_o     : out edge_buffer_type;
            next_write_o    : out std_logic
        );
    end component;

    component result_reducer is
    port (
        clk_i           :  in std_logic;
        rst_i           :  in std_logic; -- low active
        engine_idle_i   :  in std_logic;
        -- interim result from NFA-PE
        interim_empty_i :  in std_logic;
        interim_data_i  :  in edge_buffer_type;
        interim_read_o  : out std_logic;
        -- final result to TOP
        result_ready_i  :  in std_logic;
        result_data_o   : out edge_buffer_type;
        result_last_o   : out std_logic;
        result_valid_o  : out std_logic
    );
    end component;

    component buffer_edge is
        generic (
            G_DEPTH   : integer := 32;
            G_ALMST   : integer := 1
        );
        port (
            rst_i         :  in std_logic;
            clk_i         :  in std_logic;
            -- FIFO Write Interface
            wr_en_i       :  in std_logic;
            wr_data_i     :  in edge_buffer_type;
            full_o        : out std_logic;
            almost_full_o : out std_logic;
            -- FIFO Read Interface
            rd_en_i       :  in std_logic;
            rd_data_o     : out edge_buffer_type;
            empty_o       : out std_logic
        );
    end component;

    component buffer_query is
        generic (
            G_DEPTH   : integer := 32;
            G_ALMST   : integer := 1
        );
        port (
            rst_i         :  in std_logic;
            clk_i         :  in std_logic;
            -- FIFO Write Interface
            wr_en_i       :  in std_logic;
            wr_data_i     :  in query_buffer_type;
            full_o        : out std_logic;
            almost_full_o : out std_logic;
            -- FIFO Read Interface
            rd_en_i       :  in std_logic;
            rd_data_o     : out query_buffer_type;
            empty_o       : out std_logic
        );
    end component;

----------------------------------------------------------------------------------------------------
-- FUNCTIONS                                                                                      --
----------------------------------------------------------------------------------------------------

    function deserialise_edge_store(vec : std_logic_vector) return edge_store_type;

end core_pkg;

package body core_pkg is

function deserialise_edge_store(vec : std_logic_vector) return edge_store_type is
    variable res : edge_store_type;
    variable line_v   : line;
    variable vec_buff : std_logic_vector(CFG_EDGE_BRAM_WIDTH - 1 downto 0);
  begin
    vec_buff      := vec;
    res.operand_a := vec_buff(RNG_BRAM_EDGE_STORE_OPERAND_A);
    res.operand_b := vec_buff(RNG_BRAM_EDGE_STORE_OPERAND_B);
    res.pointer   := vec_buff(RNG_BRAM_EDGE_STORE_POINTER);
    res.last      := vec_buff(RNG_BRAM_EDGE_STORE_LAST'left);
    return res;
end deserialise_edge_store;

end core_pkg;