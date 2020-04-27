----------------------------------------------------------------------------------------------------
--  ERBium - Business Rule Engine Hardware Accelerator
--  Copyright (C) 2020 Fabio Maschi - Systems Group, ETH Zurich

--  This program is free software: you can redistribute it and/or modify it under the terms of the
--  GNU Affero General Public License as published by the Free Software Foundation, either version 3
--  of the License, or (at your option) any later version.

--  This software is provided by the copyright holders and contributors "AS IS" and any express or
--  implied warranties, including, but not limited to, the implied warranties of merchantability and
--  fitness for a particular purpose are disclaimed. In no event shall the copyright holder or
--  contributors be liable for any direct, indirect, incidental, special, exemplary, or
--  consequential damages (including, but not limited to, procurement of substitute goods or
--  services; loss of use, data, or profits; or business interruption) however caused and on any
--  theory of liability, whether in contract, strict liability, or tort (including negligence or
--  otherwise) arising in any way out of the use of this software, even if advised of the 
--  possibility of such damage. See the GNU Affero General Public License for more details.

--  You should have received a copy of the GNU Affero General Public License along with this
--  program. If not, see <http://www.gnu.org/licenses/agpl-3.0.en.html>.
----------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library tools;
use tools.std_pkg.all;

library erbium;
use erbium.engine_pkg.all;
use erbium.core_pkg.all;

entity erbium_wrapper is
    generic (
        G_DATA_BUS_WIDTH : integer := 512;
        G_INOUT_LATENCY  : integer := 2 -- NOT AUTOMATIC, TODO
    );
    port (
        clk_i        :  in std_logic;
        rst_i        :  in std_logic;
        -- input bus
        rd_data_i    :  in std_logic_vector(G_DATA_BUS_WIDTH - 1 downto 0);
        rd_valid_i   :  in std_logic;
        rd_last_i    :  in std_logic;
        rd_stype_i   :  in std_logic;
        rd_ready_o   : out std_logic;
        -- output bus
        wr_data_o    : out std_logic_vector(G_DATA_BUS_WIDTH - 1 downto 0);
        wr_valid_o   : out std_logic;
        wr_last_o    : out std_logic;
        wr_ready_i   :  in std_logic
    );
end erbium_wrapper;

architecture rtl of erbium_wrapper is
    constant CFG_RD_TYPE_NFA      : std_logic := '0'; -- related to rd_stype_i
    constant CFG_RD_TYPE_QUERY    : std_logic := '1'; -- related to rd_stype_i
    constant C_QUERY_PARTITIONS   : integer := G_DATA_BUS_WIDTH / CFG_RAW_OPERAND_WIDTH;
    constant C_EDGES_PARTITIONS   : integer := G_DATA_BUS_WIDTH / CFG_EDGE_BRAM_WIDTH;
    constant C_RESULTS_PARTITIONS : integer := G_DATA_BUS_WIDTH / CFG_RAW_RESULTS_WIDTH;
    --
    type result_value_array is array (CFG_ENGINES_NUMBER - 1 downto 0) of std_logic_vector(CFG_TRANSITION_POINTER_WIDTH - 1 downto 0);
    type query_value_array is array (CFG_ENGINES_NUMBER - 1 downto 0) of std_logic_vector(C_QUERYARRAY_WIDTH - 1 downto 0);
    --
    signal sig_query_id           : std_logic_vector(CFG_QUERY_ID_WIDTH - 1 downto 0);
    signal sig_query_ready        : std_logic_vector(CFG_ENGINES_NUMBER - 1 downto 0);
    signal sig_query_wr           : std_logic_vector(CFG_ENGINES_NUMBER - 1 downto 0);
    signal sig_query_serialised   : std_logic_vector(C_QUERYARRAY_WIDTH - 1 downto 0);
    --
    signal sig_fifo_query_ready   : std_logic_vector(CFG_ENGINES_NUMBER - 1 downto 0);
    signal sig_fifo_query_valid   : std_logic_vector(CFG_ENGINES_NUMBER - 1 downto 0);
    signal sig_fifo_query_last    : std_logic_vector(CFG_ENGINES_NUMBER - 1 downto 0);
    signal sig_fifo_query_value   : query_value_array;
    --
    signal sig_fifo_result_ready  : std_logic_vector(CFG_ENGINES_NUMBER - 1 downto 0);
    signal sig_fifo_result_valid  : std_logic_vector(CFG_ENGINES_NUMBER - 1 downto 0);
    signal sig_fifo_result_last   : std_logic_vector(CFG_ENGINES_NUMBER - 1 downto 0);
    signal sig_fifo_result_value  : result_value_array;
    --
    signal sig_result_ready       : std_logic_vector(CFG_ENGINES_NUMBER - 1 downto 0);
    signal sig_result_last        : std_logic_vector(CFG_ENGINES_NUMBER - 1 downto 0);
    signal sig_result_valid       : std_logic_vector(CFG_ENGINES_NUMBER - 1 downto 0);
    signal sig_result_value       : result_value_array;
    signal sig_result_temp        : std_logic_vector(CFG_RAW_RESULTS_WIDTH - 1 downto 0);
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
        cnt_edge        : std_logic_vector(CFG_TRANSITION_POINTER_WIDTH - 1 downto 0);
        cnt_slice       : integer range 0 to C_EDGES_PARTITIONS;
        mem_addr        : std_logic_vector(CFG_TRANSITION_POINTER_WIDTH - 1 downto 0);
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
        -- nfa to mem
        mem_data        : std_logic_vector(CFG_EDGE_BRAM_WIDTH - 1 downto 0);
        mem_wren        : std_logic_vector(CFG_ENGINE_NCRITERIA - 1 downto 0);
        mem_addr        : std_logic_vector(CFG_TRANSITION_POINTER_WIDTH - 1 downto 0);
        engine_rst      : std_logic;
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
        result_value    : std_logic_vector(CFG_TRANSITION_POINTER_WIDTH - 1 downto 0);
        result_valid    : std_logic;
        result_last     : std_logic;
    end record;
    signal dopio_r, dopio_rin : dopio_reg_type;

begin

rd_ready_o <= query_r.ready or nfa_r.ready;

----------------------------------------------------------------------------------------------------
-- QUERY DESERIALISER                                                                             --
----------------------------------------------------------------------------------------------------
-- extract input query criteria from the rd_data_i bus. each query has CFG_ENGINE_NCRITERIA criteria
-- and each criterium has two operands of CFG_CRITERION_VALUE_WIDTH width

sig_query_serialised <= serialise_query_array(query_r.query_array);

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
                                (idx * CFG_RAW_OPERAND_WIDTH) + CFG_CRITERION_VALUE_WIDTH - 1
                                downto
                                (idx * CFG_RAW_OPERAND_WIDTH)
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
                                (idx * CFG_RAW_OPERAND_WIDTH) + CFG_CRITERION_VALUE_WIDTH - 1
                                downto
                                (idx * CFG_RAW_OPERAND_WIDTH)
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
                v.cnt_edge  := rd_data_i(CFG_TRANSITION_POINTER_WIDTH - 1 downto 0);
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
-- CFG_TRANSITION_POINTER_WIDTH bits (into a CFG_RAW_RESULTS_WIDTH bits field).

wr_data_o  <= result_r.value;
wr_valid_o <= result_r.valid;
wr_last_o  <= result_r.last;

sig_result_temp <= (CFG_RAW_RESULTS_WIDTH - 1 downto CFG_TRANSITION_POINTER_WIDTH => '0') & dopio_r.result_value;

result_comb : process(result_r, wr_ready_i, sig_result_temp, dopio_r.result_valid, dopio_r.result_last)
    variable v : result_reg_type;
begin
    v := result_r;

    case result_r.flow_ctrl is

      when FLW_CTRL_READ =>

            v.ready := '1';
            v.valid := '0';

            if dopio_r.result_valid = '1' then

                v.slice := result_r.slice + 1;
                v.value := insert_into_vector(v.value,
                    sig_result_temp,
                    result_r.slice * CFG_RAW_RESULTS_WIDTH);

                if v.slice = C_RESULTS_PARTITIONS or dopio_r.result_last = '1' then
                    v.ready := '0';
                    v.valid := '1';
                    v.last := dopio_r.result_last;
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

dopio_comb: process(dopio_r, query_r.wr_en, result_r.ready, sig_result_last, sig_result_valid,
    sig_result_value)
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
            v.result_last  := (not v_or((power_of_two(dopio_r.reslt_flow_ctrl, CFG_ENGINES_NUMBER)
                               and sig_result_last) xor dopio_r.core_running))
                               and sig_result_last(dopio_r.reslt_flow_ctrl);
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
-- ERBIUM ENGINE TOP                                                                              --
----------------------------------------------------------------------------------------------------
gen_engines: for D in 0 to CFG_ENGINES_NUMBER - 1 generate

    mct_engine_top: engine port map 
    (
        clk_i           => clk_i,
        rst_i           => io_r.engine_rst,
        --
        query_i         => deserialise_query_array(sig_fifo_query_value(D)),
        query_last_i    => sig_fifo_query_last(D),
        query_wr_en_i   => sig_fifo_query_valid(D),
        query_ready_o   => sig_fifo_query_ready(D),
        --
        mem_i           => io_r.mem_data,
        mem_wren_i      => io_r.mem_wren,
        mem_addr_i      => io_r.mem_addr,
        --
        result_ready_i  => sig_fifo_result_ready(D),
        result_valid_o  => sig_fifo_result_valid(D),
        result_last_o   => sig_fifo_result_last(D),
        result_value_o  => sig_fifo_result_value(D)
    );

    mct_engine_fifo_queries : rxtx_fifo_multi generic map
    (
        G_DATA_WIDTH    => C_QUERYARRAY_WIDTH,
        G_DEPTH         => CFG_ENGINES_NUMBER - 1
    )
    port map
    (
        clk_i           => clk_i,
        rst_i           => rst_i,
        --
        slav_ready_o    => sig_query_ready(D),
        slav_valid_i    => sig_query_wr(D),
        slav_last_i     => query_r.query_last,
        slav_value_i    => sig_query_serialised,
        --
        mast_ready_i    => sig_fifo_query_ready(D),
        mast_valid_o    => sig_fifo_query_valid(D),
        mast_last_o     => sig_fifo_query_last(D),
        mast_value_o    => sig_fifo_query_value(D)
    );

    mct_engine_fifo_result : rxtx_fifo_multi generic map
    (
        G_DATA_WIDTH    => CFG_TRANSITION_POINTER_WIDTH,
        G_DEPTH         => CFG_ENGINES_NUMBER - 1
    )
    port map
    (
        clk_i           => clk_i,
        rst_i           => rst_i,
        --
        slav_ready_o    => sig_fifo_result_ready(D),
        slav_valid_i    => sig_fifo_result_valid(D),
        slav_last_i     => sig_fifo_result_last(D),
        slav_value_i    => sig_fifo_result_value(D),
        --
        mast_ready_i    => sig_result_ready(D),
        mast_valid_o    => sig_result_valid(D),
        mast_last_o     => sig_result_last(D),
        mast_value_o    => sig_result_value(D)
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

ior_comb : process(inout_r, nfa_r.mem_data, nfa_r.mem_wren, nfa_r.mem_addr)
    variable v : inout_wrapper_array;
begin
    
    v := inout_r;
    
    v(0) := v(1);

    v(1).mem_data := nfa_r.mem_data;
    v(1).mem_wren := nfa_r.mem_wren;
    v(1).mem_addr := nfa_r.mem_addr;
    v(1).engine_rst := nfa_r.engine_rst;

    inout_rin <= v;

end process;

ior_seq : process(clk_i)
begin
    if rising_edge(clk_i) then
        if rst_i = '0' then
            -- default rst
            inout_r(0).mem_wren <= (others => '0');
            inout_r(1).mem_wren <= (others => '0');
            inout_r(0).engine_rst <= '0';
            inout_r(1).engine_rst <= '0';
        else
            inout_r <= inout_rin;
        end if;
    end if;
end process;

-- assign
io_r <= inout_r(0);

end architecture rtl;
