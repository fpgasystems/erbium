----------------------------------------------------------------------------------------------------
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
----------------------------------------------------------------------------------------------------

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

    type query_in_array_type is array(2*CFG_ENGINE_NCRITERIA-1 downto 0) of std_logic_vector(CFG_ENGINE_CRITERIUM_WIDTH-1 downto 0);

    type match_structure_type is (STRCT_SIMPLE, STRCT_PAIR);
    type match_pair_function is (FNCTR_PAIR_NOP, FNCTR_PAIR_AND, FNCTR_PAIR_OR, FNCTR_PAIR_XOR, FNCTR_PAIR_NAND, FNCTR_PAIR_NOR);
    type match_simp_function is (FNCTR_SIMP_NOP, FNCTR_SIMP_EQU, FNCTR_SIMP_NEQ, FNCTR_SIMP_GRT, FNCTR_SIMP_GEQ, FNCTR_SIMP_LES, FNCTR_SIMP_LEQ);

    type core_flow_control is (FLW_CTRL_BUFFER, FLW_CTRL_MEM);

    type edge_store_type is record
        weight          : integer range 0 to 2**CFG_WEIGHT_WIDTH - 1;
        operand_a       : std_logic_vector(CFG_ENGINE_CRITERIUM_WIDTH - 1 downto 0);
        operand_b       : std_logic_vector(CFG_ENGINE_CRITERIUM_WIDTH - 1 downto 0);
        pointer         : std_logic_vector(CFG_MEM_ADDR_WIDTH - 1 downto 0);
        last            : std_logic;
    end record;

    type edge_buffer_type is record
        pointer         : std_logic_vector(CFG_MEM_ADDR_WIDTH - 1 downto 0);
        query_id        : integer;
        -- computed weight
    end record;

    type query_buffer_type is record
        operand_a       : std_logic_vector(CFG_ENGINE_CRITERIUM_WIDTH - 1 downto 0);
        operand_b       : std_logic_vector(CFG_ENGINE_CRITERIUM_WIDTH - 1 downto 0);
        query_id        : integer;
    end record;

    type fetch_out_type is record
        buffer_rd_en    : std_logic;
        mem_addr        : std_logic_vector(CFG_MEM_ADDR_WIDTH - 1 downto 0);
        flow_ctrl       : core_flow_control;
    end record;

    type execute_out_type is record
        inference_res   : std_logic;
        writing_edge    : edge_buffer_type;
        weight_filter   : integer;
    end record;

    type mem_out_type is record
        rd_addr         : std_logic_vector(CFG_MEM_ADDR_WIDTH - 1 downto 0);
        rd_en           : std_logic;
        wr_addr         : std_logic_vector(CFG_MEM_ADDR_WIDTH - 1 downto 0);
        wr_en           : std_logic;
        wr_data         : edge_store_type;
    end record;

----------------------------------------------------------------------------------------------------
-- COMPONENTS
----------------------------------------------------------------------------------------------------

    component functor is
        generic (
            G_FUNCTION          : match_simp_function := FNCTR_SIMP_NOP
        );
        port (
            rule_i              :  in std_logic_vector(CFG_ENGINE_CRITERIUM_WIDTH-1 downto 0);
            query_i             :  in std_logic_vector(CFG_ENGINE_CRITERIUM_WIDTH-1 downto 0);
            funct_o             : out std_logic
        );
    end component;

    component matcher is
        generic (
            G_STRUCTURE         : match_structure_type := STRCT_SIMPLE;
            G_FUNCTION_A        : match_simp_function := FNCTR_SIMP_NOP;
            G_FUNCTION_B        : match_simp_function := FNCTR_SIMP_NOP;
            G_FUNCTION_PAIR     : match_pair_function := FNCTR_PAIR_NOP
        );
        port (
            opA_rule_i          :  in std_logic_vector(CFG_ENGINE_CRITERIUM_WIDTH-1 downto 0);
            opA_query_i         :  in std_logic_vector(CFG_ENGINE_CRITERIUM_WIDTH-1 downto 0);
            opB_rule_i          :  in std_logic_vector(CFG_ENGINE_CRITERIUM_WIDTH-1 downto 0);
            opB_query_i         :  in std_logic_vector(CFG_ENGINE_CRITERIUM_WIDTH-1 downto 0);
            match_result_o      : out std_logic
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
            G_MATCH_STRCT         : match_structure_type := STRCT_SIMPLE;
            G_MATCH_FUNCTION_A    : match_simp_function  := FNCTR_SIMP_NOP;
            G_MATCH_FUNCTION_B    : match_simp_function  := FNCTR_SIMP_NOP;
            G_MATCH_FUNCTION_PAIR : match_pair_function  := FNCTR_PAIR_NOP
        );
        port (
            rst_i           :  in std_logic;
            clk_i           :  in std_logic;
            -- FIFO buffer from above
            abv_empty_i     :  in std_logic;
            abv_data_i      :  in edge_buffer_type;
            abv_read_o      : out std_logic;
            -- current
            query_i         :  in query_buffer_type;
            weight_filter_i :  in integer;
            weight_filter_o :  in integer; -- only used in last level
            -- MEMORY
            mem_edge_i      :  in edge_store_type;
            mem_addr_o      : out std_logic_vector(CFG_MEM_ADDR_WIDTH - 1 downto 0);
            mem_en_o        : out std_logic;
            -- FIFO buffer to below
            blw_full_i      :  in std_logic;
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

    component buffer_query is
        generic (
            G_DEPTH : integer := 32
        );
        port (
            rst_i      :  in std_logic;
            clk_i      :  in std_logic;
            -- FIFO Write Interface
            wr_en_i    :  in std_logic;
            wr_data_i  :  in query_buffer_type;
            full_o     : out std_logic;
            -- FIFO Read Interface
            rd_en_i    :  in std_logic;
            rd_data_o  : out query_buffer_type;
            empty_o    : out std_logic
        );
    end component;
----------------------------------------------------------------------------------------------------
-- FUNCTIONS
----------------------------------------------------------------------------------------------------
    function deserialise_edge_store(vec : std_logic_vector) return edge_store_type;

end core_pkg;

package body core_pkg is

function to_bstring(sl : std_logic) return string is
  variable sl_str_v : string(1 to 3);  -- std_logic image with quotes around
begin
  sl_str_v := std_logic'image(sl);
  return "" & sl_str_v(2);  -- "" & character to get string
end function;

function to_bstring(slv : std_logic_vector) return string is
  alias    slv_norm : std_logic_vector(1 to slv'length) is slv;
  variable sl_str_v : string(1 to 1);  -- String of std_logic
  variable res_v    : string(1 to slv'length);
begin
  for idx in slv_norm'range loop
    sl_str_v := to_bstring(slv_norm(idx));
    res_v(idx) := sl_str_v(1);
  end loop;
  return res_v;
end function;

function deserialise_edge_store(vec : std_logic_vector) return edge_store_type is
    variable res : edge_store_type;
    variable line_v   : line;
    file     out_file : text open append_mode is "out.txt";
  begin
    --write(line_v, to_bstring(vec));
    --writeline(out_file, line_v);
    res.operand_a := vec(RNG_BRAM_EDGE_STORE_OPERAND_A);
    res.operand_b := vec(RNG_BRAM_EDGE_STORE_OPERAND_B);
    res.pointer   := vec(RNG_BRAM_EDGE_STORE_POINTER);
    res.weight    := to_integer(unsigned(vec(RNG_BRAM_EDGE_STORE_WEIGHT)));
    res.last      := vec(RNG_BRAM_EDGE_STORE_LAST'left);

    return res;
end deserialise_edge_store;


end core_pkg;