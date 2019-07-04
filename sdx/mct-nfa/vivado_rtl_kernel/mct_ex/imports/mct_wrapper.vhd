----------------------------------------------------------------------------------------------------
--                                                                                                --
--                                                                                                --
--                                                                                                --
--                                                                                                --
--                                                                                                --
--                                                                                                --
----------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library bre;
use bre.engine_pkg.all;
use bre.core_pkg.all;

entity mct_wrapper is
    port (
        clk_i        :  in std_logic;
        rst_i        :  in std_logic;

        -- input bus
        rd_data_i    :  in std_logic_vector(511 downto 0);
        rd_valid_i   :  in std_logic;
        rd_last_i    :  in std_logic;
        rd_stype_i   :  in std_logic;
        rd_ready_o   : out std_logic;

        -- output bus
        wr_data_o    : out std_logic_vector(511 downto 0);
        wr_valid_o   : out std_logic;
        wr_ready_i   :  in std_logic
    );
end mct_wrapper;

architecture rtl of mct_wrapper is

    constant CFG_DATA_BUS_WIDTH : integer   := 512;
    constant CFG_RD_TYPE_NFA    : std_logic := '0'; -- related to rd_stype_i
    constant CFG_RD_TYPE_QUERY  : std_logic := '1'; -- related to rd_stype_i
    constant C_QUERY_PARTITIONS : integer := CFG_DATA_BUS_WIDTH rem (2*CFG_ENGINE_CRITERIUM_WIDTH);
    --
    signal sig_engine_rst     : std_logic;
    signal sig_query_ready    : std_logic;
    --
    signal sig_mem_wr_en      : std_logic_vector(CFG_ENGINE_NCRITERIA - 1 downto 0);
    signal sig_mem_addr       : std_logic_vector(CFG_MEM_ADDR_WIDTH - 1 downto 0);
    --
    signal sig_result_ready   : std_logic;
    signal sig_result_valid   : std_logic;
    signal sig_result_value   : std_logic_vector(CFG_MEM_ADDR_WIDTH - 1 downto 0);
    signal sig_result_query   : integer;


    type flow_ctrl_type is (FLW_CTRL_WAIT, FLW_CTRL_READ, FLW_CTRL_WRITE);
    type query_reg_type is record
        flow_ctrl       : flow_ctrl_type;
        query_array     : query_in_array_type;
        counter         : integer range 1 to CFG_ENGINE_NCRITERIA;
        ready           : std_logic;
        wr_en           : std_logic;
    end record;

    type nfa_reg_type is record
        flow_ctrl       : flow_ctrl_type;
    end record;

    signal query_r, query_rin : query_reg_type;

begin

----------------------------------------------------------------------------------------------------
-- QUERY DESERIALISER                                                                             --
----------------------------------------------------------------------------------------------------
-- extract input query criteria from the rd_data_i bus. each query has CFG_ENGINE_NCRITERIA criteria
-- and each criterium has two operands of CFG_ENGINE_CRITERIUM_WIDTH width

query_comb : process(query_r, rd_stype_i, rd_valid_i, rd_data_i, sig_query_ready)
    variable v : query_reg_type;
    --
    variable useful    : integer range 1 to C_QUERY_PARTITIONS;
    variable remaining : integer range 0 to CFG_ENGINE_NCRITERIA;
begin
    v := query_r;

    case query_r.flow_ctrl is

      when FLW_CTRL_WAIT =>

            v.ready := '1';
            v.wr_en := '0';

            if rd_stype_i = CFG_RD_TYPE_QUERY and rd_valid_i = '1' then
                v.flow_ctrl := FLW_CTRL_READ;
                v.counter   := 0;
                -- TODO increment query_id
            end if;

      when FLW_CTRL_READ =>

            v.ready := '1';
            v.wr_en := '0';

            remaining := CFG_ENGINE_NCRITERIA - query_r.counter;
            if (remaining > C_QUERY_PARTITIONS) then
                useful := C_QUERY_PARTITIONS;
            else
                useful := remaining;
            end if;
            
            v.counter := query_r.counter + useful;
            if (v.counter = CFG_ENGINE_NCRITERIA) then
                v.flow_ctrl := FLW_CTRL_WRITE;
                v.ready := '0';
            end if;

            for idx in 0 to useful loop
                v.query_array(idx).operand_a := rd_data_i(idx*2*CFG_ENGINE_CRITERIUM_WIDTH to idx*2*CFG_ENGINE_CRITERIUM_WIDTH+CFG_ENGINE_CRITERIUM_WIDTH-1);
                v.query_array(idx).operand_b := rd_data_i(idx*2*CFG_ENGINE_CRITERIUM_WIDTH+CFG_ENGINE_CRITERIUM_WIDTH to (idx+1)*2CFG_ENGINE_CRITERIUM_WIDTH-1);
                --v.query_array(idx).query_id  := ; -- TODO query_id
            end loop;

      when FLW_CTRL_WRITE => 

            v.ready := '0';
            v.wr_en := '0';

            if sig_query_ready = '1' then
                v.wr_en := '1';
                v.flow_ctrl := FLW_CTRL_WAIT;
            end if;

    end case;

    query_rin <= v;
end process;

query_seq: process(clk_i)
begin
    if rising_edge(clk_i) then
        if rst_i = '1' then
            query_r.flow_ctrl   <= FLW_CTRL_WAIT;
            query_r.counter     <= 0;
            query_r.ready       <= '1';
            query_r.wr_en       <= '0';
        else
            query_r <= query_rin;
        end if;
    end if;
end process;

----------------------------------------------------------------------------------------------------
-- NFA-EDGES DESERIALISER                                                                         --
----------------------------------------------------------------------------------------------------

-- extract nfa edges from the input rd_data bus and assign it to the nfa_mem_data bus. 
-- Each criteria level consists of number of edges where each edge is 64-bits. edges of a single
-- criteria level are aligned at cache line boundaries. 

nfa_comb : process()
begin
    case query_r.flow_ctrl is

      when FLW_CTRL_WAIT =>
end process;

nfa_seq : process(clk_i)
begin

end process;


-- TODO drive sig_engine_rst

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-- consume the outputed mct_result and fill in a cache line to write back on the wr_data bus. 
-- A query result consists of the mct value and matching rule ID? they both occupy 32-bits. 


----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- NFA-BRE ENGINE TOP                                                                             --
----------------------------------------------------------------------------------------------------
mct_engine_top: top port map 
(
    clk_i           => clk_i,
    rst_i           => sig_engine_rst,
    --
    query_i         => query_r.query_array,
    query_wr_en_i   => query_r.wr_en,
    query_ready_o   => sig_query_ready,
    --
    mem_i           => nfa_mem_data,
    mem_wren_i      => nfa_mem_wren,
    mem_addr_i      => nfa_mem_addr,
    --
    result_ready_i  => mct_result_ready,
    result_valid_o  => mcr_result_valid,
    result_value_o  => mct_result_value,
    result_query_o  => mct_result_ruleid
);

end architecture rtl;