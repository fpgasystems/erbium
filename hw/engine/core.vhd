----------------------------------------------------------------------------------------------------
-- project : 
--  author : 
--    date : 
--    file : core.vhd
--  design : 
----------------------------------------------------------------------------------------------------
-- Description : 
----------------------------------------------------------------------------------------------------
-- $Log$
----------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library bre;
use bre.engine_pkg.all;
use bre.core_pkg.all;

library tools;
use tools.std_pkg.all;

entity core is
    generic (
        G_MATCH_STRCT         : match_structure_type := STRCT_SIMPLE;
        G_MATCH_FUNCTION_A    : match_simp_function  := FNCTR_SIMP_NOP;
        G_MATCH_FUNCTION_B    : match_simp_function  := FNCTR_SIMP_NOP;
        G_MATCH_FUNCTION_PAIR : match_pair_function  := FNCTR_PAIR_NOP;
        G_MATCH_MODE          : match_mode_type      := MODE_FULL_ITERATION;
        G_WEIGHT              : integer              :=  0;
        G_WILDCARD_ENABLED    : std_logic            := '1'
    );
    port (
        clk_i           :  in std_logic;
        rst_i           :  in std_logic; -- low active
        idle_o          : out std_logic;
        -- FIFO edge buffer from previous level
        prev_empty_i    :  in std_logic;
        prev_data_i     :  in edge_buffer_type;
        prev_read_o     : out std_logic;
        -- FIFO query buffer
        query_i         :  in query_buffer_type;
        query_empty_i   :  in std_logic;
        query_read_o    : out std_logic;
        --
        weight_filter_i :  in integer;
        weight_filter_o :  in integer; -- only used in last level
        -- MEMORY
        mem_edge_i      :  in edge_store_type;
        mem_addr_o      : out std_logic_vector(CFG_MEM_ADDR_WIDTH - 1 downto 0);
        mem_en_o        : out std_logic;
        -- FIFO edge buffer to next level
        next_full_i     :  in std_logic;
        next_data_o     : out edge_buffer_type;
        next_write_o    : out std_logic
    );
end core;

architecture behavioural of core is
    signal sig_exe_match_result   : std_logic;
    signal sig_exe_match_wildcard : std_logic;
    signal sig_exe_branch         : std_logic;
    signal fetch_r, fetch_rin     : fetch_out_type;
    signal execute_r, execute_rin : execute_out_type;
    signal query_r, query_rin     : query_flow_type;
    signal mem_r, mem_rin         : mem_delay_type;
begin

----------------------------------------------------------------------------------------------------
-- QUERY                                                                                          --
----------------------------------------------------------------------------------------------------

query_read_o <= query_r.read_en;

query_comb: process(query_r, prev_data_i.query_id, fetch_r.buffer_rd_en, query_i, query_empty_i)
    variable v : query_flow_type;
begin
    v := query_r;

    v.read_en := '0';
    if query_empty_i = '0' then
        if query_r.first = '1' or (fetch_r.buffer_rd_en = '1' and prev_data_i.query_id /= query_r.query.query_id) then
            v.read_en := '1';
            v.query   := query_i;
            v.first   := '0';
        end if;
    end if;
    
    query_rin <= v;
end process;

query_seq: process(clk_i)
begin
    if rising_edge(clk_i) then
        if rst_i = '0' then
            query_r.read_en <= '0';
            query_r.first   <= '1';
        else
            query_r <= query_rin;
        end if;
    end if;
end process;

----------------------------------------------------------------------------------------------------
-- FETCH                                                                                          --
----------------------------------------------------------------------------------------------------

prev_read_o <= fetch_r.buffer_rd_en;
mem_addr_o  <= fetch_r.mem_addr;
mem_en_o    <= fetch_r.mem_rd_en;

fetch_comb: process(fetch_r, prev_data_i, prev_empty_i, query_empty_i, mem_edge_i.last, mem_r.valid, sig_exe_branch, next_full_i, query_r.query.query_id)
    variable v        : fetch_out_type;
    variable v_empty  : std_logic;
    variable v_branch : std_logic;
begin
    v := fetch_r;

    if (prev_data_i.query_id /= query_r.query.query_id) then
        v_empty  := prev_empty_i or query_empty_i;
    else
        v_empty  := prev_empty_i;
    end if;
    v_branch := (mem_edge_i.last and mem_r.valid) or sig_exe_branch;

    -- state machine
    case fetch_r.flow_ctrl is

      when FLW_CTRL_BUFFER =>

            v.buffer_rd_en := '0';
            v.mem_rd_en    := '0';

            if v_empty = '0' and next_full_i = '0' then
                v.buffer_rd_en := '1';
                v.mem_rd_en    := prev_data_i.has_match;
                v.mem_addr     := prev_data_i.pointer;
                v.query_id     := prev_data_i.query_id;
                v.weight       := prev_data_i.weight;
                v.clock_cycles := prev_data_i.clock_cycles;
                v.flow_ctrl    := FLW_CTRL_MEM;
            end if;

      when FLW_CTRL_MEM =>

            if v_branch = '1' then
                if (v_empty or next_full_i) = '0' then
                    v.buffer_rd_en := '1';
                    v.mem_rd_en    := prev_data_i.has_match;
                    v.mem_addr     := prev_data_i.pointer;
                    v.query_id     := prev_data_i.query_id;
                    v.weight       := prev_data_i.weight;
                    v.clock_cycles := prev_data_i.clock_cycles;
                    v.flow_ctrl    := FLW_CTRL_MEM;
                else
                    v.buffer_rd_en := '0';
                    v.mem_rd_en    := '0';
                    v.flow_ctrl    := FLW_CTRL_BUFFER;
                end if;
            else
                v.buffer_rd_en := '0';
                v.mem_rd_en    := not next_full_i;
                v.flow_ctrl    := FLW_CTRL_MEM;
                if next_full_i = '0' then
                    v.mem_addr     := increment(fetch_r.mem_addr);
                    v.clock_cycles := increment(fetch_r.clock_cycles);
                end if;
            end if;

    end case;
    
    fetch_rin <= v;
end process;

fetch_seq: process(clk_i)
begin
    if rising_edge(clk_i) then
        if rst_i = '0' then
            fetch_r.flow_ctrl    <= FLW_CTRL_BUFFER;
            fetch_r.buffer_rd_en <= '0';
            fetch_r.mem_rd_en    <= '0';
            fetch_r.query_id     <=  C_INIT_QUERY_ID;
        else
            fetch_r <= fetch_rin;
        end if;
    end if;
end process;

----------------------------------------------------------------------------------------------------
-- MEMORY DELAY (3 CYCLES)                                                                        --
----------------------------------------------------------------------------------------------------

mem_comb: process(mem_r, fetch_r.mem_rd_en, mem_edge_i.last, sig_exe_branch)
    variable v        : mem_delay_type;
    variable v_branch : std_logic;
begin
    v := mem_r;

    v_branch := (mem_edge_i.last and mem_r.valid) or sig_exe_branch;

    -- delay it
    v.rden_dlay := fetch_r.mem_rd_en & mem_r.rden_dlay(CFG_MEM_RD_LATENCY - 2 downto 1);
    v.last_dlay := v_branch & mem_r.last_dlay(CFG_MEM_RD_LATENCY - 2 downto 1);

    if (v_branch or v_or(mem_r.last_dlay)) = '1' then
        v.valid := '0';
    else
        v.valid := mem_r.rden_dlay(0);
    end if;

    mem_rin <= v;
end process;

mem_seq: process(clk_i)
begin
    if rising_edge(clk_i) then
        if rst_i = '0' then
            mem_r.valid     <= '0';
            mem_r.rden_dlay <= (others => '0');
            mem_r.last_dlay <= (others => '0');
        else
            mem_r <= mem_rin;
        end if;
    end if;
end process;

----------------------------------------------------------------------------------------------------
-- EXECUTE                                                                                        --
----------------------------------------------------------------------------------------------------

next_data_o  <= execute_r.writing_edge;
next_write_o <= execute_r.inference_res;

exe_matcher: matcher generic map
(
    G_STRUCTURE     => G_MATCH_STRCT,
    G_FUNCTION_A    => G_MATCH_FUNCTION_A,
    G_FUNCTION_B    => G_MATCH_FUNCTION_B,
    G_FUNCTION_PAIR => G_MATCH_FUNCTION_PAIR,
    G_WILDCARD      => G_WILDCARD_ENABLED
)
port map
(
    op_query_i      => query_r.query.operand,
    opA_rule_i      => mem_edge_i.operand_a,
    opB_rule_i      => mem_edge_i.operand_b,
    match_result_o  => sig_exe_match_result,
    wildcard_o      => sig_exe_match_wildcard
);

execute_comb : process(execute_r, weight_filter_i, sig_exe_match_result, fetch_r, mem_r.valid,
    mem_edge_i, fetch_r.clock_cycles, query_r.read_en)
    variable v : execute_out_type;
    variable v_wildcard : std_logic;
begin
    v := execute_r;

    -- weight_control    
    -- if mem_edge_i.weight >= weight_filter_i then
    --     v_weight_check := '1';
    -- else
    --     v_weight_check := '0';
    -- end if;
    -- v.inference_res := sig_exe_match_result and v_weight_check and mem_r.valid;

    -- result of EXE
    v.inference_res             := sig_exe_match_result and mem_r.valid;
    v.writing_edge.pointer      := mem_edge_i.pointer;
    v.writing_edge.query_id     := fetch_r.query_id;
    v.writing_edge.clock_cycles := increment(fetch_r.clock_cycles);

    if v.inference_res = '1' and sig_exe_match_wildcard = '0' then
        v.writing_edge.weight := fetch_r.weight + G_WEIGHT;
    else
        v.writing_edge.weight := fetch_r.weight;
    end if;

    -- effectively used only in the last level instance
    if v.inference_res = '1' then
        v.weight_filter := mem_edge_i.weight;
    end if;

    -- has match check
    if v.inference_res = '1' then
        v.has_match := '1';
    end if;

    if query_r.read_en = '1' then
        -- trigger
        if v.has_match = '0' then
            v.inference_res := '1'; -- write a 'no match edge'
        end if;
        v.has_match := '0';
    end if;

    v.writing_edge.has_match := v.has_match;

    execute_rin <= v;
end process;

execute_seq: process(clk_i)
begin
    if rising_edge(clk_i) then
        if rst_i = '0' then
            execute_r.inference_res <= '0';
            execute_r.weight_filter <=  0 ;
            execute_r.has_match     <= '1';
        else
            execute_r <= execute_rin;
        end if;
    end if;
end process;

----------------------------------------------------------------------------------------------------
-- MATCH MODE                                                                                     --
----------------------------------------------------------------------------------------------------

gen_mode_strict_match : if G_MATCH_MODE = MODE_STRICT_MATCH generate

    -- if mandatory: to only one match (strict match)
    -- if non-mandatory: to only two (wildcard and strict match)
    --    wildcard for mandatory is always '0'
    sig_exe_branch <= sig_exe_match_result and mem_r.valid and not sig_exe_match_wildcard;

end generate;

gen_mode_full_iteration : if G_MATCH_MODE = MODE_FULL_ITERATION generate

    -- if numeric: no limit
    sig_exe_branch <= '0';

end generate;

----------------------------------------------------------------------------------------------------
-- IDLE SIGNAL                                                                                    --
----------------------------------------------------------------------------------------------------

idle_o <= prev_empty_i and query_empty_i when (fetch_r.flow_ctrl = FLW_CTRL_BUFFER)
          else '0';

----------------------------------------------------------------------------------------------------
-- FAILURE CHECKS                                                                                 --
----------------------------------------------------------------------------------------------------

-- -- synthesis translate_off 
-- p_assert : process (clk_i) is
-- begin
--     if rising_edge(clk_i) then
--         if mem_r.valid = '1' then -- fetch_r.buffer_rd_en = '0' and query_r.read_en = '0' and
--             if query_i.query_id /= fetch_r.query_id then
--                 report "ASSERT FAILURE - QUERY AND EDGE ARE NOT SYNCHRONISED! " severity failure;
--             end if;
--         end if;
--     end if;
-- end process p_assert;
-- -- synthesis translate_on

-- counter_queries: simple_counter generic map
-- (
--     G_WIDTH   => CFG_DBG_COUNTERS_WIDTH
-- )
-- port map
-- (
--     clk_i     => clk_i,
--     rst_i     => rst_i,
--     enable_i  => query_r.read_en,
--     counter_o => sig_queries_in
-- );

end architecture behavioural;

----------------------------------------------------------------------------------------------------
-- FETCH                                                                                          --
----------------------------------------------------------------------------------------------------
--  state | v_branch | v_empty | n_full | v_buff | v_mem | v_flow | addr
--   BUF  |     0         0        0    |   1    |   1   |  MEM   | POINTER
--   BUF  |     0         0        1    |   0    |   0   |  BUFF  | --     
--   BUF  |     0         1        0    |   0    |   0   |  BUFF  | --     
--   BUF  |     0         1        1    |   0    |   0   |  BUFF  | --     
--   BUF  |     1         0        0    |  xxx   |  xxx  |  xxx   | xxx    
--   BUF  |     1         0        1    |  xxx   |  xxx  |  xxx   | xxx    
--   BUF  |     1         1        0    |  xxx   |  xxx  |  xxx   | xxx    
--   BUF  |     1         1        1    |  xxx   |  xxx  |  xxx   | xxx    
--   MEM  |     0         0        0    |   0    |   1   |  MEM   | INC    
--   MEM  |     0         0        1    |   0    |   0   |  MEM   | KEEP   
--   MEM  |     0         1        0    |   0    |   1   |  MEM   | INC    
--   MEM  |     0         1        1    |   0    |   0   |  MEM   | KEEP   
--   MEM  |     1         0        0    |   1    |   1   |  MEM   | POINTER
--   MEM  |     1         0        1    |   0    |   0   |  BUFF  | --
--   MEM  |     1         1        0    |   0    |   0   |  BUFF  | --     
--   MEM  |     1         1        1    |   0    |   0   |  BUFF  | --     
-- 
-- 
-- ADDR ... ... AAA BBB CCC AAA BBB CCC AAA BBB CCC ... AAA BBB CCC      -- fetch_r.mem_addr
-- DATA ... ... ... ... AAA ... ... AAA ... ... AAA ... ... ... AAA      -- mem_i
-- LAST ... ... ... ...  1  ... ...  1  ... ...  1  ... ... ...  1       -- mem_i.last
-- VALD  0   0   0   0   1   0   0   1   0   0   1   0   0   0   1       -- fetch_r.mem_rd_en
-- BUFF  0   0   1   0   0   1   0   0   1   0   0   0   1   0   0       -- fetch_r.buffer_rd_en
-- QRRD  0   0   0   0   0   0   1   0   0   1   0   0   0   1   0       -- query_r.read_en 
-- MPTY  1   0   0   0   0   0   0   0   0   1   1   0   0   1   1       -- v_empty
-- QERY ... AAA AAA AAA AAA AAA AAA BBB BBB BBB CCC CCC CCC CCC DDD      -- query_i
-- EDGE ... AAA AAA BBB BBB BBB CCC CCC CCC ... ... DDD DDD ... ...      -- prev_data_i
-- FETC ... ... AAA AAA AAA BBB BBB BBB CCC CCC CCC ... DDD DDD DDD      -- fetch_r.query