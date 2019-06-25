----------------------------------------------------------------------------------------------
--
--      Input file         : core_pkg.vhd
--      Design name        : core_pkg
--      Author             : Tamar Kranenburg
--      Company            : Delft University of Technology
--                         : Faculty EEMCS, Department ME&CE
--                         : Systems and Circuits group
--
--      Description        : Package with components and type definitions for the interface
--                           of the components
--
--
----------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library bre;
use bre.engine_pkg.all;

package core_pkg is

----------------------------------------------------------------------------------------------
-- TYPES USED IN NFA-BRE
----------------------------------------------------------------------------------------------

    type query_in_array_type is array(CFG_ENGINE_NCRITERIA-1 downto 0) of std_logic_vector(CFG_ENGINE_CRITERIUM_WIDTH-1 downto 0);

    type match_structure_type is (STRCT_SIMPLE, STRCT_PAIR);
    type match_pair_function is (FNCTR_PAIR_NOP, FNCTR_PAIR_AND, FNCTR_PAIR_OR, FNCTR_PAIR_XOR, FNCTR_PAIR_NAND, FNCTR_PAIR_NOR);
    type match_simp_function is (FNCTR_SIMP_NOP, FNCTR_SIMP_EQU, FNCTR_SIMP_NEQ, FNCTR_SIMP_GRT, FNCTR_SIMP_GEQ, FNCTR_SIMP_LES, FNCTR_SIMP_LEQ);

    type edge_store_type is record
        operand_a       : std_logic_vector(CFG_ENGINE_CRITERIUM_WIDTH - 1 downto 0);
        operand_b       : std_logic_vector(CFG_ENGINE_CRITERIUM_WIDTH - 1 downto 0);
        weight          : integer;
        pointer         : std_logic_vector(CFG_MEM_ADDR_WIDTH - 1 downto 0);
        last            : std_logic;
    end record;

    type edge_buffer_type is record
        pointer         : std_logic_vector(CFG_MEM_ADDR_WIDTH - 1 downto 0);
        -- query_id
    end record;

    type fetch_out_type is record
        mem_addr        : std_logic_vector(CFG_MEM_ADDR_WIDTH - 1 downto 0);
    end record;

    type execute_out_type is record
        inference_res   : std_logic;
    end record;

    type mem_out_type is record
        rd_addr         : std_logic_vector(CFG_MEM_ADDR_WIDTH - 1 downto 0);
        rd_en           : std_logic;
        wr_addr         : std_logic_vector(CFG_MEM_ADDR_WIDTH - 1 downto 0);
        wr_en           : std_logic;
        wr_data         : edge_store_type;
    end record;

----------------------------------------------------------------------------------------------
-- COMPONENTS USED IN MB-LITE
----------------------------------------------------------------------------------------------

    component matcher is
        generic (
            G_STRUCTURE         : match_structure_type;
            G_FUNCTION_A        : match_simp_function;
            G_FUNCTION_B        : match_simp_function;
            G_FUNCTION_PAIR     : match_pair_function
        );
        port (
            opA_rule_i          :  in std_logic_vector(CFG_ENGINE_CRITERIUM_WIDTH-1 downto 0);
            opA_query_i         :  in std_logic_vector(CFG_ENGINE_CRITERIUM_WIDTH-1 downto 0);
            opB_rule_i          :  in std_logic_vector(CFG_ENGINE_CRITERIUM_WIDTH-1 downto 0);
            opB_query_i         :  in std_logic_vector(CFG_ENGINE_CRITERIUM_WIDTH-1 downto 0);
            match_result_o      : out std_logic
        );
    end component;

    component functor is
        generic (
            G_FUNCTION      : match_simp_function
        );
        port (
            rule_i          :  in std_logic_vector(CFG_ENGINE_CRITERIUM_WIDTH-1 downto 0);
            query_i         :  in std_logic_vector(CFG_ENGINE_CRITERIUM_WIDTH-1 downto 0);
            funct_o         : out std_logic
        );
    end component;

    component bram_edge_store is
        generic (
            RAM_DEPTH : integer := 1024;                    -- Specify RAM depth (number of entries)
            RAM_PERFORMANCE : string := "LOW_LATENCY";      -- Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
            INIT_FILE : string := "RAM_INIT.dat"            -- Specify name/location of RAM initialization file if using one (leave blank if not)
        ); port (
            clk_i        :  in std_logic;
            rst_i        :  in std_logic;
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
            G_MATCH_STRCT         : match_structure_type;
            G_MATCH_FUNCTION_A    : match_simp_function;
            G_MATCH_FUNCTION_B    : match_simp_function;
            G_MATCH_FUNCTION_PAIR : match_pair_function
        );
        port (
            rst_i           :  in std_logic;
            clk_i           :  in std_logic;
            -- FIFO buffer from above
            abv_data_i      :  in edge_buffer_type;
            abv_read_o      : out std_logic;
            -- current
            query_opA_i     :  in std_logic_vector(CFG_ENGINE_CRITERIUM_WIDTH - 1 downto 0);
            query_opB_i     :  in std_logic_vector(CFG_ENGINE_CRITERIUM_WIDTH - 1 downto 0);
            weight_filter_i :  in integer;
            -- MEMORY
            mem_edge_i      :  in edge_store_type;
            mem_addr_o      : out std_logic_vector(CFG_MEM_ADDR_WIDTH - 1 downto 0);
            mem_en_o        : out std_logic;
            -- FIFO buffer to below
            blw_data_o      : out edge_buffer_type;
            blw_write_o     : out std_logic
        );
    end component;

    component buffer_edge is
        generic (
            G_DEPTH : integer := 32
        );
        port (
            rst_i      :  in std_logic;
            clk_i      :  in std_logic;
            -- FIFO Write Interface
            wr_en_i    :  in std_logic;
            wr_data_i  :  in edge_buffer_type;
            full_o     : out std_logic;
            -- FIFO Read Interface
            rd_en_i    :  in std_logic;
            rd_data_o  : out edge_buffer_type;
            empty_o    : out std_logic
        );
    end component;
----------------------------------------------------------------------------------------------
-- FUNCTIONS USED IN MB-LITE
----------------------------------------------------------------------------------------------

end core_pkg;

package body core_pkg is

end core_pkg;