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

library tools;
use tools.std_pkg.all;

library bre;
use bre.engine_pkg.all;
use bre.core_pkg.all;

entity ederah_wrapper is
    generic (
        G_DATA_BUS_WIDTH : integer := 512;
        G_INOUT_LATENCY  : integer := 2
    );
    port (
        clk_i        :  in std_logic;
        rst_i        :  in std_logic;
        -- stats option
        stats_on_i   :  in std_logic;
        -- input bus
        rd_data_i    :  in std_logic_vector(G_DATA_BUS_WIDTH - 1 downto 0);
        rd_valid_i   :  in std_logic;
        rd_last_i    :  in std_logic; -- not in use
        rd_stype_i   :  in std_logic;
        rd_ready_o   : out std_logic;
        -- output bus
        wr_data_o    : out std_logic_vector(G_DATA_BUS_WIDTH - 1 downto 0);
        wr_valid_o   : out std_logic;
        wr_last_o    : out std_logic;
        wr_ready_i   :  in std_logic
    );
end ederah_wrapper;

architecture rtl of ederah_wrapper is
    constant CFG_RD_TYPE_NFA      : std_logic := '0'; -- related to rd_stype_i
    constant CFG_RD_TYPE_QUERY    : std_logic := '1'; -- related to rd_stype_i
    constant C_QUERY_PARTITIONS   : integer := G_DATA_BUS_WIDTH / CFG_RAW_QUERY_WIDTH;
    constant C_EDGES_PARTITIONS   : integer := G_DATA_BUS_WIDTH / CFG_EDGE_BRAM_WIDTH;
    constant C_RESULTS_PARTITIONS : integer := G_DATA_BUS_WIDTH / CFG_RAW_RESULTS_WIDTH;
    constant C_STATS_PARTITIONS   : integer := G_DATA_BUS_WIDTH / CFG_RAW_RESULT_STATS_WIDTH;
    --
    type result_value_array is array (CFG_ENGINES_NUMBER - 1 downto 0) of std_logic_vector(CFG_MEM_ADDR_WIDTH - 1 downto 0);
    type result_stats_array is array (CFG_ENGINES_NUMBER - 1 downto 0) of result_stats_type;
    --
    signal sig_query_id       : std_logic_vector(CFG_QUERY_ID_WIDTH - 1 downto 0);
    signal sig_query_ready    : std_logic_vector(CFG_ENGINES_NUMBER - 1 downto 0);
    signal sig_query_wr       : std_logic_vector(CFG_ENGINES_NUMBER - 1 downto 0);
    --
    signal sig_result_ready   : std_logic_vector(CFG_ENGINES_NUMBER - 1 downto 0);
    signal sig_result_last    : std_logic_vector(CFG_ENGINES_NUMBER - 1 downto 0);
    signal sig_result_valid   : std_logic_vector(CFG_ENGINES_NUMBER - 1 downto 0);
    signal sig_result_value   : result_value_array;
    signal sig_result_stats   : result_stats_array;
    signal sig_resstats_value : std_logic_vector(CFG_RAW_RESULT_STATS_WIDTH - 1 downto 0);
    --
    type flow_ctrl_type is (FLW_CTRL_WAIT, FLW_CTRL_READ, FLW_CTRL_WRITE, FLW_CTRL_DLAY);
    --
    type query_reg_type is record
        flow_ctrl       : flow_ctrl_type;
        query_array     : query_in_array_type;
        query_last      : std_logic;
        counter         : integer range 0 to CFG_ENGINE_NCRITERIA;
        ready           : std_logic;
        wr_en           : std_logic;
    end record;
    --
    type nfa_reg_type is record
        flow_ctrl       : flow_ctrl_type;
        ready           : std_logic;
        cnt_criterium   : integer range 0 to CFG_ENGINE_NCRITERIA;
        cnt_edge        : std_logic_vector(CFG_MEM_ADDR_WIDTH - 1 downto 0);
        cnt_slice       : integer range 0 to C_EDGES_PARTITIONS;
        mem_addr        : std_logic_vector(CFG_MEM_ADDR_WIDTH - 1 downto 0);
        mem_data        : std_logic_vector(CFG_EDGE_BRAM_WIDTH - 1 downto 0);
        mem_wren        : std_logic_vector(CFG_ENGINE_NCRITERIA - 1 downto 0);
        engine_rst      : std_logic;
    end record;

    type result_reg_type is record
        flow_ctrl       : flow_ctrl_type;
        value           : std_logic_vector(G_DATA_BUS_WIDTH - 1 downto 0);
        valid           : std_logic;
        slice           : integer range 0 to C_RESULTS_PARTITIONS;
        ready           : std_logic;
        last            : std_logic;
    end record;

    signal query_r, query_rin   : query_reg_type;
    signal nfa_r, nfa_rin       : nfa_reg_type;
    signal result_r, result_rin : result_reg_type;

    -- IN/OUT REGISTER WRAPPER (REDUCE ROUTING TIMES)
    type inout_wrapper_type is record
        -- stats option
        stats_on   : std_logic;
        -- nfa to mem
        mem_data   : std_logic_vector(CFG_EDGE_BRAM_WIDTH - 1 downto 0);
        mem_wren   : std_logic_vector(CFG_ENGINE_NCRITERIA - 1 downto 0);
        mem_addr   : std_logic_vector(CFG_MEM_ADDR_WIDTH - 1 downto 0);
    end record;
    type inout_wrapper_array is array (G_INOUT_LATENCY - 1 downto 0) of inout_wrapper_type;

    signal inout_r, inout_rin : inout_wrapper_array;
    signal io_r : inout_wrapper_type;

    --
    -- DOPIO
    type dopio_reg_type is record
        core_running    : std_logic_vector(CFG_ENGINES_NUMBER - 1 downto 0);
        --
        query_flow_ctrl : integer range 0 to CFG_ENGINES_NUMBER;
        reslt_flow_ctrl : integer range 0 to CFG_ENGINES_NUMBER;
        --
        result_value    : std_logic_vector(CFG_MEM_ADDR_WIDTH - 1 downto 0);
        result_valid    : std_logic;
        result_last     : std_logic;
    end record;
    signal dopio_r, dopio_rin   : dopio_reg_type;

begin

rd_ready_o <= query_r.ready or nfa_r.ready;

----------------------------------------------------------------------------------------------------
-- QUERY DESERIALISER                                                                             --
----------------------------------------------------------------------------------------------------
-- extract input query criteria from the rd_data_i bus. each query has CFG_ENGINE_NCRITERIA criteria
-- and each criterium has two operands of CFG_CRITERION_VALUE_WIDTH width

query_comb : process(query_r, rd_stype_i, rd_valid_i, rd_data_i, rd_last_i, sig_query_ready,
    dopio_r.query_flow_ctrl, sig_query_id)
    constant C_SLICES_REM     : integer := CFG_ENGINE_NCRITERIA / C_QUERY_PARTITIONS;
    constant C_SLICES_MOD     : integer := CFG_ENGINE_NCRITERIA mod C_QUERY_PARTITIONS;
    --
    variable v : query_reg_type;
    --
    variable useful    : integer range 1 to C_QUERY_PARTITIONS;
    variable remaining : integer range 0 to CFG_ENGINE_NCRITERIA;
begin
    v := query_r;

    case query_r.flow_ctrl is

      when FLW_CTRL_WAIT =>

            v.ready := '0';
            v.wr_en := '0';

            if rd_stype_i = CFG_RD_TYPE_QUERY and rd_valid_i = '1' then
                v.flow_ctrl := FLW_CTRL_READ;
                v.counter   :=  0;
                v.ready     := '1';
            end if;

      when FLW_CTRL_READ =>

            v.wr_en := '0';
            v.ready := '1';

            if rd_valid_i = '1' then
                remaining := CFG_ENGINE_NCRITERIA - query_r.counter;
                if (remaining > C_QUERY_PARTITIONS) then
                    useful := C_QUERY_PARTITIONS;
                    -- full slices
                    for idx in 0 to C_QUERY_PARTITIONS - 1 loop
                        v.query_array(query_r.counter + idx).operand := 
                            rd_data_i
                            (
                                (idx * CFG_RAW_QUERY_WIDTH) + CFG_CRITERION_VALUE_WIDTH - 1
                                downto
                                (idx * CFG_RAW_QUERY_WIDTH)
                            );
                        v.query_array(query_r.counter + idx).query_id := my_conv_integer(sig_query_id);
                    end loop;
                else
                    useful := remaining;
                    -- total mod piece slices
                    for idx in 0 to C_SLICES_MOD - 1 loop
                        v.query_array(query_r.counter + idx).operand := 
                            rd_data_i
                            (
                                (idx * CFG_RAW_QUERY_WIDTH) + CFG_CRITERION_VALUE_WIDTH - 1
                                downto
                                (idx * CFG_RAW_QUERY_WIDTH)
                            );
                        v.query_array(query_r.counter + idx).query_id := my_conv_integer(sig_query_id);
                    end loop;
                end if;
                
                v.query_last := rd_last_i;

                v.counter := query_r.counter + useful;
                if (v.counter = CFG_ENGINE_NCRITERIA) then
                    v.flow_ctrl := FLW_CTRL_WRITE;
                    v.ready := '0';
                end if;

            end if;


      when FLW_CTRL_WRITE => 

            v.ready := '0';
            v.wr_en := '0';

            if sig_query_ready(dopio_r.query_flow_ctrl) = '1' then
                v.wr_en := '1';
                v.flow_ctrl := FLW_CTRL_WAIT;
            end if;

      when others =>
            v.flow_ctrl := FLW_CTRL_WAIT;
            v.ready     := '0';
            v.wr_en     := '0';

    end case;

    query_rin <= v;
end process;

query_seq: process(clk_i)
begin
    if rising_edge(clk_i) then
        if rst_i = '0' then
            query_r.flow_ctrl   <= FLW_CTRL_WAIT;
            query_r.ready       <= '0';
            query_r.wr_en       <= '0';
            query_r.query_last  <= '1';
        else
            query_r <= query_rin;
        end if;
    end if;
end process;

----------------------------------------------------------------------------------------------------
-- NFA-EDGES DESERIALISER                                                                         --
----------------------------------------------------------------------------------------------------
-- extract nfa edges from the rd_data_i bus and assign them to the nfa_mem_data bus, setting both
-- nfa_mem_wren and nfa_mem_addr accordingly. each criterium level has its own memory bank storing
-- the respective edges. each edge is 64-bit wide. edges of a single criteria level are aligned at
-- cache line boundaries.

nfa_comb : process(nfa_r, rd_stype_i, rd_valid_i, rd_data_i)
    variable v : nfa_reg_type;
begin
    v := nfa_r;

    -- default
    v.mem_wren   := (others => '0');
    v.engine_rst := '1';
    v.ready      := '0';

    case nfa_r.flow_ctrl is

      when FLW_CTRL_WAIT =>

            v.ready := '0';
            if rd_stype_i = CFG_RD_TYPE_NFA and rd_valid_i = '1' then
                v.flow_ctrl     := FLW_CTRL_READ;
                v.cnt_criterium :=  0 ;
                v.engine_rst    := '0';
            end if;

      when FLW_CTRL_READ =>

            if rd_stype_i = CFG_RD_TYPE_NFA and rd_valid_i = '1' then
                -- Once per criterium
                v.ready     := '0';
                v.mem_wren  := (others => '0');
                v.mem_addr  := (others => '0');
                v.mem_data  := rd_data_i(2*CFG_EDGE_BRAM_WIDTH-1 downto CFG_EDGE_BRAM_WIDTH);
                v.cnt_edge  := rd_data_i(CFG_MEM_ADDR_WIDTH - 1 downto 0);
                v.cnt_slice := 2;

                if nfa_r.cnt_criterium = CFG_ENGINE_NCRITERIA then
                    v.flow_ctrl  := FLW_CTRL_WAIT;
                    v.mem_wren   := (others => '0');
                else
                    v.flow_ctrl := FLW_CTRL_WRITE;
                    v.mem_wren(nfa_r.cnt_criterium) := '1';
                end if;
            end if;

      when FLW_CTRL_WRITE =>

            if rd_valid_i = '1' then
                -- Once per edge
                v.ready     := '0';
                v.mem_addr  := increment(nfa_r.mem_addr);
                v.mem_data  := rd_data_i(((nfa_r.cnt_slice+1)*CFG_EDGE_BRAM_WIDTH)-1
                                         downto
                                         (nfa_r.cnt_slice*CFG_EDGE_BRAM_WIDTH));
                v.cnt_slice := nfa_r.cnt_slice + 1;
                v.mem_wren(nfa_r.cnt_criterium) := '1';
                
                if v.cnt_slice = C_EDGES_PARTITIONS then
                    v.flow_ctrl := FLW_CTRL_DLAY; -- then go to FLW_CTRL_WRITE
                    v.cnt_slice :=  0;
                    v.ready     := '1';
                end if;

                if v.mem_addr = nfa_r.cnt_edge - 1 then
                    v.flow_ctrl     := FLW_CTRL_DLAY; -- then go to FLW_CTRL_READ
                    v.cnt_criterium := nfa_r.cnt_criterium + 1;
                    v.ready         := '1';
                end if;
            end if;

      when FLW_CTRL_DLAY =>
            -- So the ready='1' signal can be perceived
            v.ready    := '0';
            v.mem_wren := (others => '0');

            if nfa_r.mem_addr = nfa_r.cnt_edge - 1 then
                v.flow_ctrl := FLW_CTRL_READ;
            else
                v.flow_ctrl := FLW_CTRL_WRITE;
            end if;

    end case;

    nfa_rin <= v;
end process;

nfa_seq : process(clk_i)
begin
    if rising_edge(clk_i) then
        if rst_i = '0' then
            nfa_r.flow_ctrl       <= FLW_CTRL_WAIT;
            nfa_r.ready           <= '0';
            nfa_r.mem_wren        <= (others => '0');
            nfa_r.engine_rst      <= '0';
        else
            nfa_r <= nfa_rin;
        end if;
    end if;
end process;

----------------------------------------------------------------------------------------------------
-- RESULT OUTPUT SERIALISER                                                                       --
----------------------------------------------------------------------------------------------------
-- consume the outputed sig_result_value and fill in a cache line to write back on the wr_data_o bus
-- A query result consists of the index of the content it points to. This result value occupies
-- CFG_MEM_ADDR_WIDTH bits (into a CFG_RAW_RESULTS_WIDTH bits field).

sig_resstats_value <= (CFG_RAW_RESULT_STATS_WIDTH - 1
                        downto
                      CFG_RAW_RESULT_STATS_WIDTH - (CFG_RAW_RESULTS_WIDTH - CFG_MEM_ADDR_WIDTH) => '0')
                      & dopio_r.result_value
                      & sig_result_stats(dopio_r.reslt_flow_ctrl).clock_cycle_counter
                      & sig_result_stats(dopio_r.reslt_flow_ctrl).match_higher_weight
                      & sig_result_stats(dopio_r.reslt_flow_ctrl).match_lower_weight;

wr_data_o  <= result_r.value;
wr_valid_o <= result_r.valid;
wr_last_o  <= result_r.last;

result_comb : process(result_r, wr_ready_i, io_r.stats_on, sig_resstats_value,
    dopio_r.result_value, dopio_r.result_valid, dopio_r.result_last)
    variable v : result_reg_type;
begin
    v := result_r;

    case result_r.flow_ctrl is

      when FLW_CTRL_READ =>

            v.ready := '1';
            v.valid := '0';

            if dopio_r.result_valid = '1' and io_r.stats_on = '0' then

                v.slice := result_r.slice + 1;

                -- this is ugly, but it's a Xilinx problem
                -- https://forums.xilinx.com/t5/Synthesis/Vivado2013-2-Synth-8-27-complex-assignment-not-supported/td-p/345805
                case result_r.slice is
                  when  0 =>
                        v.value(CFG_RAW_RESULTS_WIDTH - 1 downto  0)
                            := (CFG_RAW_RESULTS_WIDTH - 1 downto CFG_MEM_ADDR_WIDTH => '0') & dopio_r.result_value;
                  when  1 =>
                        v.value(( 1 + 1) * CFG_RAW_RESULTS_WIDTH - 1 downto  1 * CFG_RAW_RESULTS_WIDTH)
                            := (CFG_RAW_RESULTS_WIDTH - 1 downto CFG_MEM_ADDR_WIDTH => '0') & dopio_r.result_value;
                  when  2 =>
                        v.value(( 2 + 1) * CFG_RAW_RESULTS_WIDTH - 1 downto  2 * CFG_RAW_RESULTS_WIDTH)
                            := (CFG_RAW_RESULTS_WIDTH - 1 downto CFG_MEM_ADDR_WIDTH => '0') & dopio_r.result_value;
                  when  3 =>
                        v.value(( 3 + 1) * CFG_RAW_RESULTS_WIDTH - 1 downto  3 * CFG_RAW_RESULTS_WIDTH)
                            := (CFG_RAW_RESULTS_WIDTH - 1 downto CFG_MEM_ADDR_WIDTH => '0') & dopio_r.result_value;
                  when  4 =>
                        v.value(( 4 + 1) * CFG_RAW_RESULTS_WIDTH - 1 downto  4 * CFG_RAW_RESULTS_WIDTH)
                            := (CFG_RAW_RESULTS_WIDTH - 1 downto CFG_MEM_ADDR_WIDTH => '0') & dopio_r.result_value;
                  when  5 =>
                        v.value(( 5 + 1) * CFG_RAW_RESULTS_WIDTH - 1 downto  5 * CFG_RAW_RESULTS_WIDTH)
                            := (CFG_RAW_RESULTS_WIDTH - 1 downto CFG_MEM_ADDR_WIDTH => '0') & dopio_r.result_value;
                  when  6 =>
                        v.value(( 6 + 1) * CFG_RAW_RESULTS_WIDTH - 1 downto  6 * CFG_RAW_RESULTS_WIDTH)
                            := (CFG_RAW_RESULTS_WIDTH - 1 downto CFG_MEM_ADDR_WIDTH => '0') & dopio_r.result_value;
                  when  7 =>
                        v.value(( 7 + 1) * CFG_RAW_RESULTS_WIDTH - 1 downto  7 * CFG_RAW_RESULTS_WIDTH)
                            := (CFG_RAW_RESULTS_WIDTH - 1 downto CFG_MEM_ADDR_WIDTH => '0') & dopio_r.result_value;
                  when  8 =>
                        v.value(( 8 + 1) * CFG_RAW_RESULTS_WIDTH - 1 downto  8 * CFG_RAW_RESULTS_WIDTH)
                            := (CFG_RAW_RESULTS_WIDTH - 1 downto CFG_MEM_ADDR_WIDTH => '0') & dopio_r.result_value;
                  when  9 =>
                        v.value(( 9 + 1) * CFG_RAW_RESULTS_WIDTH - 1 downto  9 * CFG_RAW_RESULTS_WIDTH)
                            := (CFG_RAW_RESULTS_WIDTH - 1 downto CFG_MEM_ADDR_WIDTH => '0') & dopio_r.result_value;
                  when 10 =>
                        v.value((10 + 1) * CFG_RAW_RESULTS_WIDTH - 1 downto 10 * CFG_RAW_RESULTS_WIDTH)
                            := (CFG_RAW_RESULTS_WIDTH - 1 downto CFG_MEM_ADDR_WIDTH => '0') & dopio_r.result_value;
                  when 11 =>
                        v.value((11 + 1) * CFG_RAW_RESULTS_WIDTH - 1 downto 11 * CFG_RAW_RESULTS_WIDTH)
                            := (CFG_RAW_RESULTS_WIDTH - 1 downto CFG_MEM_ADDR_WIDTH => '0') & dopio_r.result_value;
                  when 12 =>
                        v.value((12 + 1) * CFG_RAW_RESULTS_WIDTH - 1 downto 12 * CFG_RAW_RESULTS_WIDTH)
                            := (CFG_RAW_RESULTS_WIDTH - 1 downto CFG_MEM_ADDR_WIDTH => '0') & dopio_r.result_value;
                  when 13 =>
                        v.value((13 + 1) * CFG_RAW_RESULTS_WIDTH - 1 downto 13 * CFG_RAW_RESULTS_WIDTH)
                            := (CFG_RAW_RESULTS_WIDTH - 1 downto CFG_MEM_ADDR_WIDTH => '0') & dopio_r.result_value;
                  when 14 =>
                        v.value((14 + 1) * CFG_RAW_RESULTS_WIDTH - 1 downto 14 * CFG_RAW_RESULTS_WIDTH)
                            := (CFG_RAW_RESULTS_WIDTH - 1 downto CFG_MEM_ADDR_WIDTH => '0') & dopio_r.result_value;
                  when 15 =>
                        v.value((15 + 1) * CFG_RAW_RESULTS_WIDTH - 1 downto 15 * CFG_RAW_RESULTS_WIDTH)
                            := (CFG_RAW_RESULTS_WIDTH - 1 downto CFG_MEM_ADDR_WIDTH => '0') & dopio_r.result_value;
                  when 16 =>
                        v.value((16 + 1) * CFG_RAW_RESULTS_WIDTH - 1 downto 16 * CFG_RAW_RESULTS_WIDTH)
                            := (CFG_RAW_RESULTS_WIDTH - 1 downto CFG_MEM_ADDR_WIDTH => '0') & dopio_r.result_value;
                  when 17 =>
                        v.value((17 + 1) * CFG_RAW_RESULTS_WIDTH - 1 downto 17 * CFG_RAW_RESULTS_WIDTH)
                            := (CFG_RAW_RESULTS_WIDTH - 1 downto CFG_MEM_ADDR_WIDTH => '0') & dopio_r.result_value;
                  when 18 =>
                        v.value((18 + 1) * CFG_RAW_RESULTS_WIDTH - 1 downto 18 * CFG_RAW_RESULTS_WIDTH)
                            := (CFG_RAW_RESULTS_WIDTH - 1 downto CFG_MEM_ADDR_WIDTH => '0') & dopio_r.result_value;
                  when 19 =>
                        v.value((19 + 1) * CFG_RAW_RESULTS_WIDTH - 1 downto 19 * CFG_RAW_RESULTS_WIDTH)
                            := (CFG_RAW_RESULTS_WIDTH - 1 downto CFG_MEM_ADDR_WIDTH => '0') & dopio_r.result_value;
                  when 20 =>
                        v.value((20 + 1) * CFG_RAW_RESULTS_WIDTH - 1 downto 20 * CFG_RAW_RESULTS_WIDTH)
                            := (CFG_RAW_RESULTS_WIDTH - 1 downto CFG_MEM_ADDR_WIDTH => '0') & dopio_r.result_value;
                  when 21 =>
                        v.value((21 + 1) * CFG_RAW_RESULTS_WIDTH - 1 downto 21 * CFG_RAW_RESULTS_WIDTH)
                            := (CFG_RAW_RESULTS_WIDTH - 1 downto CFG_MEM_ADDR_WIDTH => '0') & dopio_r.result_value;
                  when 22 =>
                        v.value((22 + 1) * CFG_RAW_RESULTS_WIDTH - 1 downto 22 * CFG_RAW_RESULTS_WIDTH)
                            := (CFG_RAW_RESULTS_WIDTH - 1 downto CFG_MEM_ADDR_WIDTH => '0') & dopio_r.result_value;
                  when 23 =>
                        v.value((23 + 1) * CFG_RAW_RESULTS_WIDTH - 1 downto 23 * CFG_RAW_RESULTS_WIDTH)
                            := (CFG_RAW_RESULTS_WIDTH - 1 downto CFG_MEM_ADDR_WIDTH => '0') & dopio_r.result_value;
                  when 24 =>
                        v.value((24 + 1) * CFG_RAW_RESULTS_WIDTH - 1 downto 24 * CFG_RAW_RESULTS_WIDTH)
                            := (CFG_RAW_RESULTS_WIDTH - 1 downto CFG_MEM_ADDR_WIDTH => '0') & dopio_r.result_value;
                  when 25 =>
                        v.value((25 + 1) * CFG_RAW_RESULTS_WIDTH - 1 downto 25 * CFG_RAW_RESULTS_WIDTH)
                            := (CFG_RAW_RESULTS_WIDTH - 1 downto CFG_MEM_ADDR_WIDTH => '0') & dopio_r.result_value;
                  when 26 =>
                        v.value((26 + 1) * CFG_RAW_RESULTS_WIDTH - 1 downto 26 * CFG_RAW_RESULTS_WIDTH)
                            := (CFG_RAW_RESULTS_WIDTH - 1 downto CFG_MEM_ADDR_WIDTH => '0') & dopio_r.result_value;
                  when 27 =>
                        v.value((27 + 1) * CFG_RAW_RESULTS_WIDTH - 1 downto 27 * CFG_RAW_RESULTS_WIDTH)
                            := (CFG_RAW_RESULTS_WIDTH - 1 downto CFG_MEM_ADDR_WIDTH => '0') & dopio_r.result_value;
                  when 28 =>
                        v.value((28 + 1) * CFG_RAW_RESULTS_WIDTH - 1 downto 28 * CFG_RAW_RESULTS_WIDTH)
                            := (CFG_RAW_RESULTS_WIDTH - 1 downto CFG_MEM_ADDR_WIDTH => '0') & dopio_r.result_value;
                  when 29 =>
                        v.value((29 + 1) * CFG_RAW_RESULTS_WIDTH - 1 downto 29 * CFG_RAW_RESULTS_WIDTH)
                            := (CFG_RAW_RESULTS_WIDTH - 1 downto CFG_MEM_ADDR_WIDTH => '0') & dopio_r.result_value;
                  when 30 =>
                        v.value((30 + 1) * CFG_RAW_RESULTS_WIDTH - 1 downto 30 * CFG_RAW_RESULTS_WIDTH)
                            := (CFG_RAW_RESULTS_WIDTH - 1 downto CFG_MEM_ADDR_WIDTH => '0') & dopio_r.result_value;
                  when 31 =>
                        v.value((31 + 1) * CFG_RAW_RESULTS_WIDTH - 1 downto 31 * CFG_RAW_RESULTS_WIDTH)
                            := (CFG_RAW_RESULTS_WIDTH - 1 downto CFG_MEM_ADDR_WIDTH => '0') & dopio_r.result_value;
                  when others =>
                end case;

                if v.slice = C_RESULTS_PARTITIONS or dopio_r.result_last = '1' then
                    v.ready := '0';
                    v.valid := '1';
                    v.last := dopio_r.result_last;
                    v.flow_ctrl := FLW_CTRL_WRITE;
                end if;

            elsif dopio_r.result_valid = '1' and io_r.stats_on = '1' then
                
                v.slice := result_r.slice + 1;

                case result_r.slice is
                  when  0 =>
                        v.value(CFG_RAW_RESULT_STATS_WIDTH - 1 downto  0)
                            := sig_resstats_value;
                  when  1 =>
                        v.value(( 1 + 1) * CFG_RAW_RESULT_STATS_WIDTH - 1 downto  1 * CFG_RAW_RESULT_STATS_WIDTH)
                            := sig_resstats_value;
                  when  2 =>
                        v.value(( 2 + 1) * CFG_RAW_RESULT_STATS_WIDTH - 1 downto  2 * CFG_RAW_RESULT_STATS_WIDTH)
                            := sig_resstats_value;
                  when  3 =>
                        v.value(( 3 + 1) * CFG_RAW_RESULT_STATS_WIDTH - 1 downto  3 * CFG_RAW_RESULT_STATS_WIDTH)
                            := sig_resstats_value;
                  when  4 =>
                        v.value(( 4 + 1) * CFG_RAW_RESULT_STATS_WIDTH - 1 downto  4 * CFG_RAW_RESULT_STATS_WIDTH)
                            := sig_resstats_value;
                  when  5 =>
                        v.value(( 5 + 1) * CFG_RAW_RESULT_STATS_WIDTH - 1 downto  5 * CFG_RAW_RESULT_STATS_WIDTH)
                            := sig_resstats_value;
                  when  6 =>
                        v.value(( 6 + 1) * CFG_RAW_RESULT_STATS_WIDTH - 1 downto  6 * CFG_RAW_RESULT_STATS_WIDTH)
                            := sig_resstats_value;
                  when  7 =>
                        v.value(( 7 + 1) * CFG_RAW_RESULT_STATS_WIDTH - 1 downto  7 * CFG_RAW_RESULT_STATS_WIDTH)
                            := sig_resstats_value;
                  when others =>
                end case;

                if v.slice = C_STATS_PARTITIONS or dopio_r.result_last = '1' then
                    v.ready := '0';
                    v.valid := '1';
                    v.last  := dopio_r.result_last;
                    v.flow_ctrl := FLW_CTRL_WRITE;
                end if;
            end if;

      when FLW_CTRL_WRITE =>

            v.ready := '0';
            v.slice :=  0 ;
            v.valid := '1';

            if wr_ready_i = '1' then
                v.ready := '1';
                v.valid := '0';
                v.last  := '0';
                v.flow_ctrl := FLW_CTRL_READ;
            end if;
        
      when others =>

            v.ready := '1';
            v.slice :=  0 ;
            v.valid := '0';
            v.last  := '0';
            v.flow_ctrl := FLW_CTRL_READ;

    end case;

    result_rin <= v;
end process;

result_seq : process(clk_i)
begin
    if rising_edge(clk_i) then
        if rst_i = '0' then
            -- default rst
            result_r.ready     <= '1';
            result_r.slice     <=  0 ;
            result_r.valid     <= '0';
            result_r.last      <= '0';
            result_r.flow_ctrl <= FLW_CTRL_READ;
        else
            result_r <= result_rin;
        end if;
    end if;
end process;

----------------------------------------------------------------------------------------------------
-- DOPIO ENGINE                                                                                   --
----------------------------------------------------------------------------------------------------

dopio_comb: process(dopio_r, query_r.wr_en, sig_result_valid, result_r.ready, sig_result_last)
    variable v : dopio_reg_type;
begin
    v := dopio_r;

    -- reslt_flow_ctrl
    if (sig_result_valid(dopio_r.reslt_flow_ctrl) and result_r.ready) = '1' then
        v.core_running(dopio_r.reslt_flow_ctrl) := not sig_result_last(dopio_r.reslt_flow_ctrl);
        v.reslt_flow_ctrl := dopio_r.reslt_flow_ctrl + 1;
        if v.reslt_flow_ctrl = CFG_ENGINES_NUMBER then
            v.reslt_flow_ctrl := 0;
        end if;
    end if;

    -- query_flow_ctrl
    if query_r.wr_en = '1' then
        v.core_running(dopio_r.query_flow_ctrl) := '1';
        v.query_flow_ctrl := dopio_r.query_flow_ctrl + 1;
        if v.query_flow_ctrl = CFG_ENGINES_NUMBER then
            v.query_flow_ctrl := 0;
        end if;
    end if;

    -- result value
    if (result_r.ready = '1') then
        if (sig_result_valid(dopio_r.reslt_flow_ctrl) = '1') then
            v.result_value := sig_result_value(dopio_r.reslt_flow_ctrl);
            v.result_valid := sig_result_valid(dopio_r.reslt_flow_ctrl) and result_r.ready;
            v.result_last  := (not v_or((power_of_two(dopio_r.reslt_flow_ctrl, CFG_ENGINES_NUMBER) and sig_result_last)
                               xor dopio_r.core_running)) and sig_result_last(dopio_r.reslt_flow_ctrl);
        else
            v.result_valid := '0';
            v.result_last  := '0';
        end if;
    end if;
    dopio_rin <= v;
end process;

dopio_seq: process(clk_i)
begin
    if rising_edge(clk_i) then
        if rst_i = '0' then
            dopio_r.core_running <= (others => '0');
            dopio_r.query_flow_ctrl <= 0;
            dopio_r.reslt_flow_ctrl <= 0;
            dopio_r.result_valid <= '0';
            dopio_r.result_last  <= '0';
        else
            dopio_r <= dopio_rin;
        end if;
    end if;
end process;

----------------------------------------------------------------------------------------------------
-- NFA-BRE ENGINE TOP                                                                             --
----------------------------------------------------------------------------------------------------
gen_engines: for D in 0 to CFG_ENGINES_NUMBER - 1 generate

    mct_engine_top: entity bre.engine port map 
    (
        clk_i           => clk_i,
        rst_i           => nfa_r.engine_rst,
        --
        query_i         => query_r.query_array,
        query_last_i    => query_r.query_last,
        query_wr_en_i   => sig_query_wr(D),
        query_ready_o   => sig_query_ready(D),
        --
        mem_i           => io_r.mem_data,
        mem_wren_i      => io_r.mem_wren,
        mem_addr_i      => io_r.mem_addr,
        --
        result_ready_i  => sig_result_ready(D),
        result_stats_o  => sig_result_stats(D),
        result_valid_o  => sig_result_valid(D),
        result_last_o   => sig_result_last(D),
        result_value_o  => sig_result_value(D)
    );

    -- DOPIO
    sig_query_wr(D)     <= query_r.wr_en  when dopio_r.query_flow_ctrl = D else '0';
    sig_result_ready(D) <= result_r.ready when dopio_r.reslt_flow_ctrl = D else '0';

end generate gen_engines;

----------------------------------------------------------------------------------------------------
-- QUERY ID GENERATOR                                                                             --
----------------------------------------------------------------------------------------------------
query_id_gen : simple_counter generic map
(
    G_WIDTH   => CFG_QUERY_ID_WIDTH
)
port  map
(
    clk_i     => clk_i,
    rst_i     => rst_i,
    enable_i  => query_r.wr_en,
    counter_o => sig_query_id
);

----------------------------------------------------------------------------------------------------
-- IN/OUT REGISTER WRAPPER (REDUCE ROUTING TIMES)                                                 --
----------------------------------------------------------------------------------------------------

ior_comb : process(inout_r, stats_on_i, nfa_r.mem_data, nfa_r.mem_wren, nfa_r.mem_addr)
    variable v : inout_wrapper_array;
begin
    
    v := inout_r;
    
    v(0) := v(1);

    v(1).stats_on := stats_on_i;
    v(1).mem_data := nfa_r.mem_data;
    v(1).mem_wren := nfa_r.mem_wren;
    v(1).mem_addr := nfa_r.mem_addr;

    inout_rin <= v;

end process;

ior_seq : process(clk_i)
begin
    if rising_edge(clk_i) then
        if rst_i = '0' then
            -- default rst
            inout_r(0).mem_wren <= (others => '0');
            inout_r(1).mem_wren <= (others => '0');
        else
            inout_r <= inout_rin;
        end if;
    end if;
end process;

-- assign
io_r <= inout_r(0);

end architecture rtl;