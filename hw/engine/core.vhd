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
        G_MATCH_FUNCTION_PAIR : match_pair_function  := FNCTR_PAIR_NOP
    );
    port (
        clk_i           :  in std_logic;
        rst_i           :  in std_logic; -- low active
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
    signal fetch_r, fetch_rin     : fetch_out_type;
    signal execute_r, execute_rin : execute_out_type;
    signal query_r, query_rin     : query_flow_type;
begin

----------------------------------------------------------------------------------------------------
-- QUERY                                                                                          --
----------------------------------------------------------------------------------------------------

query_read_o <= query_r.read_en;

query_comb: process(query_empty_i, fetch_r.buffer_rd_en, query_i, query_r)
    variable v : query_flow_type;
begin

    v := query_r;

    -- default
    v.read_en := '0';

    -- state machine
    case query_r.flow_ctrl is

      when FLW_CTRL_BUFFER =>

            if query_empty_i = '0' then
                v.flow_ctrl := FLW_CTRL_MEM;
                v.query := query_i;
                v.read_en := '1';
            end if;

      when FLW_CTRL_MEM =>

            if fetch_r.buffer_rd_en = '1' and prev_data_i.query_id /= query_r.query.query_id then

                if query_empty_i = '0' then
                    v.flow_ctrl := FLW_CTRL_MEM;
                    v.query := query_i;
                    v.read_en := '1';
                else
                    v.flow_ctrl := FLW_CTRL_BUFFER;
                end if;                

            end if;

    end case;
    
    query_rin <= v;
end process;

query_seq: process(clk_i)
begin
    if rising_edge(clk_i) then
        if rst_i = '0' then
            query_r.flow_ctrl       <= FLW_CTRL_BUFFER;
            query_r.query.query_id  <= 0;
            query_r.read_en         <= '0';
        else
            query_r <= query_rin;
        end if;
    end if;
end process;

----------------------------------------------------------------------------------------------------
-- FETCH                                                                                          --
----------------------------------------------------------------------------------------------------

prev_read_o <= fetch_r.buffer_rd_en;
mem_addr_o <= fetch_r.mem_addr when fetch_r.flow_ctrl = FLW_CTRL_MEM else
              (others => 'Z');
mem_en_o   <= '1' when fetch_r.flow_ctrl = FLW_CTRL_MEM else
              '0';

fetch_comb: process(fetch_r, rst_i, mem_edge_i.last, prev_data_i, prev_empty_i, next_full_i)
    variable v : fetch_out_type;
begin
    v := fetch_r;

    -- default
    v.buffer_rd_en := '0';

    -- state machine
    case fetch_r.flow_ctrl is

      when FLW_CTRL_BUFFER =>

            if prev_empty_i = '0' and next_full_i = '0' then
                v.buffer_rd_en := '1';
                v.flow_ctrl    := FLW_CTRL_MEM;
                v.mem_addr     := prev_data_i.pointer;
                v.query_id     := prev_data_i.query_id;
            end if;

      when FLW_CTRL_MEM =>

            if mem_edge_i.last = '1' then

                if prev_empty_i = '0' and next_full_i = '0' then
                    v.buffer_rd_en := '1';
                    v.flow_ctrl    := FLW_CTRL_MEM;
                    v.mem_addr     := prev_data_i.pointer;
                    v.query_id     := prev_data_i.query_id;
                else
                    v.flow_ctrl := FLW_CTRL_BUFFER;
                    v.mem_addr  := (others => '0');
                    v.query_id  := 0;
                end if;

            elsif next_full_i = '0' then
                v.mem_addr := increment(fetch_r.mem_addr);
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
            fetch_r.query_id     <=  0;
        else
            fetch_r <= fetch_rin;
        end if;
    end if;
end process;

----------------------------------------------------------------------------------------------------
-- EXECUTE                                                                                        --
----------------------------------------------------------------------------------------------------

next_data_o  <= execute_r.writing_edge;
next_write_o <= '1' when execute_r.inference_res = '1' and next_full_i = '0' else
               '0';
exe_matcher: matcher generic map
(
    G_STRUCTURE     => G_MATCH_STRCT,
    G_FUNCTION_A    => G_MATCH_FUNCTION_A,
    G_FUNCTION_B    => G_MATCH_FUNCTION_B,
    G_FUNCTION_PAIR => G_MATCH_FUNCTION_PAIR
)
port map
(
    opA_rule_i      => mem_edge_i.operand_a,
    opA_query_i     => query_r.query.operand_a,
    opB_rule_i      => mem_edge_i.operand_b,
    opB_query_i     => query_r.query.operand_b,
    match_result_o  => sig_exe_match_result
);

execute_comb : process(execute_r, mem_edge_i.weight, weight_filter_i, sig_exe_match_result, fetch_r)
    variable v : execute_out_type;
    variable v_weight_check : std_logic;
begin
    v := execute_r;

    -- weight_control
    if mem_edge_i.weight >= weight_filter_i then
        v_weight_check := '1';
    else
        v_weight_check := '0';
    end if;

    -- result of EXE
    if (fetch_r.flow_ctrl = FLW_CTRL_MEM) then
        v.inference_res := sig_exe_match_result and v_weight_check;
    else
        v.inference_res := '0';
    end if;

    -- TODO check if it's not a NOP!!!!!!!!!!!

    v.writing_edge.pointer := mem_edge_i.pointer;
    v.writing_edge.query_id := fetch_r.query_id;

    -- effectively used only in the last level instance
    if v.inference_res = '1' then
        v.weight_filter := mem_edge_i.weight;
    end if;

    execute_rin <= v;
end process;

execute_seq: process(clk_i)
begin
    if rising_edge(clk_i) then
        if rst_i = '0' then
            execute_r.inference_res         <= '0';
            execute_r.weight_filter         <= 0;
        else
            execute_r <= execute_rin;
        end if;
    end if;
end process;

end architecture behavioural;