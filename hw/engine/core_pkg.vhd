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
use bre.config_pkg.all;
use bre.pkg_std.all;

package core_pkg is

    -- MAIN PARAMETERS
    constant CFG_ENGINE_NCRITERIA         : integer := 22;
    constant CFG_ENGINE_CRITERIUM_WIDTH   : integer := 12;
    constant CFG_MEM_ADDR_WIDTH           : integer := 10;

    constant C_8_ZEROS  : std_logic_vector ( 7 downto 0) := (others => '0');
    constant C_16_ZEROS : std_logic_vector (15 downto 0) := (others => '0');
    constant C_24_ZEROS : std_logic_vector (23 downto 0) := (others => '0');
    constant C_32_ZEROS : std_logic_vector (31 downto 0) := (others => '0');

----------------------------------------------------------------------------------------------
-- TYPES USED IN NFA-BRE
----------------------------------------------------------------------------------------------

    type query_in_array_type is array(CFG_ENGINE_NCRITERIA-1 downto 0) of std_logic_vector(CFG_ENGINE_CRITERIUM_WIDTH-1 downto 0);

    -- CONTROL CODES
    constant C_STRCT_SIMPLE      : integer := 0;
    constant C_STRCT_PAIR        : integer := 1;

    -- PAIR FUNCTORS
    constant C_FNCTR_PAIR_AND    : integer := 0;
    constant C_FNCTR_PAIR_OR     : integer := 1;
    constant C_FNCTR_PAIR_XOR    : integer := 2;
    constant C_FNCTR_PAIR_NAND   : integer := 3;
    constant C_FNCTR_PAIR_NOR    : integer := 4;

    -- type alu_operation    is (ALU_ADD, ALU_OR, ALU_AND, ALU_XOR, ALU_SHIFT, ALU_SEXT8, ALU_SEXT16, ALU_MUL, ALU_BS);

    -- type imem_in_type is record
    --     dat_i : std_logic_vector(CFG_IMEM_WIDTH - 1 downto 0);
    -- end record;

    -- type imem_out_type is record
    --     adr_o : std_logic_vector(CFG_IMEM_SIZE - 1 downto 0);
    --     ena_o : std_logic;
    -- end record;

    type edge_store_type is record
        operand_a       : std_logic_vector(CFG_ENGINE_CRITERIUM_WIDTH - 1 downto 0);
        operand_b       : std_logic_vector(CFG_ENGINE_CRITERIUM_WIDTH - 1 downto 0);
        weight          : integer;
        pointer         : std_logic_vector(CFG_MEM_ADDR_WIDTH - 1 downto 0);
        last            : std_logic;
    end record;

    -- type edge_buffer_type is record
    --     pointer         : std_logic_vector(CFG_MEM_ADDR_WIDTH - 1 downto 0);
    --     -- query_id
    -- end record;

    type fetch_out_type is record
        mem_addr        : std_logic_vector(CFG_MEM_ADDR_WIDTH - 1 downto 0);
    end record;

    type execute_out_type is record
        inference_res   : std_logic;
    end record;

    type mem_out_type is record
        r_addr : std_logic_vector();
        r_en   : std_logic;
        r_data : std_logic_vector();
        w_addr : std_logic_vector();
        w_en   : std_logic;
        w_data : std_logic_vector();
    end record;
    
    -- type gprf_out_type is record
    --     dat_a_o : std_logic_vector(CFG_DMEM_WIDTH - 1 downto 0);
    --     dat_b_o : std_logic_vector(CFG_DMEM_WIDTH - 1 downto 0);
    --     dat_d_o : std_logic_vector(CFG_DMEM_WIDTH - 1 downto 0);
    -- end record;


    -- type gprf_in_type is record
    --     adr_a_i : std_logic_vector(CFG_GPRF_SIZE - 1 downto 0);
    --     adr_b_i : std_logic_vector(CFG_GPRF_SIZE - 1 downto 0);
    --     adr_d_i : std_logic_vector(CFG_GPRF_SIZE - 1 downto 0);
    --     dat_w_i : std_logic_vector(CFG_DMEM_WIDTH - 1 downto 0);
    --     adr_w_i : std_logic_vector(CFG_GPRF_SIZE - 1 downto 0);
    --     wre_i   : std_logic;
    -- end record;

    -- type execute_out_type is record
    --     alu_result      : std_logic_vector(CFG_DMEM_WIDTH - 1 downto 0);
    --     dat_d           : std_logic_vector(CFG_DMEM_WIDTH - 1 downto 0);
    --     branch          : std_logic;
    --     program_counter : std_logic_vector(CFG_IMEM_SIZE - 1 downto 0);
    --     flush_id        : std_logic;
    --     ctrl_mem        : ctrl_memory;
    --     ctrl_wrb        : forward_type;
    -- end record;

    -- type execute_in_type is record
    --     reg_a           : std_logic_vector(CFG_GPRF_SIZE  - 1 downto 0);
    --     dat_a           : std_logic_vector(CFG_DMEM_WIDTH - 1 downto 0);
    --     reg_b           : std_logic_vector(CFG_GPRF_SIZE  - 1 downto 0);
    --     dat_b           : std_logic_vector(CFG_DMEM_WIDTH - 1 downto 0);
    --     dat_d           : std_logic_vector(CFG_DMEM_WIDTH - 1 downto 0);
    --     imm             : std_logic_vector(CFG_DMEM_WIDTH - 1 downto 0);
    --     program_counter : std_logic_vector(CFG_IMEM_SIZE - 1 downto 0);
    --     fwd_dec         : forward_type;
    --     fwd_dec_result  : std_logic_vector(CFG_DMEM_WIDTH - 1 downto 0);
    --     fwd_mem         : forward_type;
    --     ctrl_ex         : ctrl_execution;
    --     ctrl_mem        : ctrl_memory;
    --     ctrl_wrb        : forward_type;
    --     ctrl_mem_wrb    : ctrl_memory_writeback_type;
    --     mem_result      : std_logic_vector(CFG_DMEM_WIDTH - 1 downto 0);
    --     alu_result      : std_logic_vector(CFG_DMEM_WIDTH - 1 downto 0);
    -- end record;

    -- type mem_in_type is record
    --     dat_d           : std_logic_vector(CFG_DMEM_WIDTH - 1 downto 0);
    --     alu_result      : std_logic_vector(CFG_DMEM_WIDTH - 1 downto 0);
    --     mem_result      : std_logic_vector(CFG_DMEM_WIDTH - 1 downto 0);
    --     program_counter : std_logic_vector(CFG_IMEM_SIZE - 1 downto 0);
    --     branch          : std_logic;
    --     ctrl_mem        : ctrl_memory;
    --     ctrl_wrb         : forward_type;
    -- end record;

    -- type mem_out_type is record
    --     alu_result  : std_logic_vector(CFG_DMEM_WIDTH - 1 downto 0);
    --     ctrl_wrb     : forward_type;
    --     ctrl_mem_wrb : ctrl_memory_writeback_type;
    -- end record;

    -- type dmem_in_type is record
    --     dat_i : std_logic_vector(CFG_DMEM_WIDTH - 1 downto 0);
    --     ena_i : std_logic;
    -- end record;

    -- type dmem_out_type is record
    --     dat_o : std_logic_vector(CFG_DMEM_WIDTH - 1 downto 0);
    --     adr_o : std_logic_vector(CFG_DMEM_SIZE - 1 downto 0);
    --     sel_o : std_logic_vector(3 downto 0);
    --     we_o  : std_logic;
    --     ena_o : std_logic;
    -- end record;

    -- type dmem_in_array_type is array(natural range <>) of dmem_in_type;
    -- type dmem_out_array_type is array(natural range <>) of dmem_out_type;

----------------------------------------------------------------------------------------------
-- COMPONENTS USED IN MB-LITE
----------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------
-- FUNCTIONS USED IN MB-LITE
----------------------------------------------------------------------------------------------

end core_pkg;

package body core_pkg is

end core_pkg;