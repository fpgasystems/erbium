library IEEE;
use IEEE.STD_LOGIC_1164.all;

library tools;
use tools.std_pkg.all;

library bre;
use bre.engine_pkg.all;
use bre.core_pkg.all;

entity core is
    generic (
        G_MATCH_STRCT         : match_structure_type := STRCT_SIMPLE;
        G_MATCH_FUNCTION_A    : match_simp_function := FNCTR_SIMP_NOP;
        G_MATCH_FUNCTION_B    : match_simp_function := FNCTR_SIMP_NOP;
        G_MATCH_FUNCTION_PAIR : match_pair_function := FNCTR_PAIR_NOP
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
end core;

architecture behavioural of core is
    signal sig_exe_match_result   : std_logic;
    signal fetch_r, fetch_rin     : fetch_out_type;
    signal execute_r, execute_rin : execute_out_type;
begin

----------------------------------------------------------------------------------------------------
-- FETCH                                                                                          --
----------------------------------------------------------------------------------------------------

abv_read_o <= mem_edge_i.last;
mem_addr_o <= fetch_r.mem_addr;
mem_en_o   <= '1';

fetch_comb: process(fetch_r, rst_i, mem_edge_i.last, abv_data_i)
    variable v : fetch_out_type;
begin
    v := fetch_r;

    if rst_i = '1' then
        -- reset
        v.mem_addr := (others => '0');

    elsif mem_edge_i.last = '1' then
        -- from stack if there no other children from current node
        v.mem_addr := abv_data_i.pointer;
    else
        -- PC+4 (iterate the edges)
        v.mem_addr := increment(fetch_r.mem_addr);
    end if;
    
    fetch_rin <= v;
end process;

fetch_seq: process(clk_i)
begin
    if rising_edge(clk_i) then
        if rst_i = '1' then
            fetch_r.mem_addr <= (others => '0');
        else
            fetch_r <= fetch_rin;
        end if;
    end if;
end process;

----------------------------------------------------------------------------------------------------
-- EXECUTE                                                                                        --
----------------------------------------------------------------------------------------------------

blw_data_o.pointer <= mem_edge_i.pointer;
blw_write_o        <= execute_r.inference_res;

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
    opA_query_i     => query_opA_i,
    opB_rule_i      => mem_edge_i.operand_b,
    opB_query_i     => query_opB_i,
    match_result_o  => sig_exe_match_result
);

execute_comb : process(execute_r, mem_edge_i.weight, weight_filter_i, sig_exe_match_result)
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
    v.inference_res := sig_exe_match_result and v_weight_check;
    -- TODO check if it's not a NOP!!!!!!!!!!!

    execute_rin <= v;
end process;

execute_seq: process(clk_i)
begin
    if rising_edge(clk_i) then
        if rst_i = '1' then
            execute_r.inference_res <= '0';
        else
            execute_r <= execute_rin;
        end if;
    end if;
end process;

end architecture behavioural;