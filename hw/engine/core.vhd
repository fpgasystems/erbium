library IEEE;
use IEEE.STD_LOGIC_1164.all;

library std;
use std.pkg_ram.all;

library bre;
use bre.pkg_bre.all;

entity core is
    generic (
        G_MATCH_STRCT         : integer;
        G_MATCH_FUNCTION_A    : integer;
        G_MATCH_FUNCTION_B    : integer;
        G_MATCH_FUNCTION_PAIR : integer
    );
    port (
        -- FIFO buffer from above
        abv_pointer_i   :  in std_logic_vector(CFG_MEM_ADDR_WIDTH - 1 downto 0);
        abv_read_o      : out std_logic;
        -- current
        query_opA_i     :  in std_logic_vector(CFG_ENGINE_CRITERIUM_WIDTH - 1 downto 0);
        query_opB_i     :  in std_logic_vector(CFG_ENGINE_CRITERIUM_WIDTH - 1 downto 0);
        weight_filter_i :  in integer;
        -- MEMORY
        mem_edge_i      :  in edge_store_type;
        mem_edge_o      : out mem_out_type;
        -- FIFO buffer to below
        blw_pointer_o   : out std_logic_vector(CFG_MEM_ADDR_WIDTH - 1 downto 0);
        blw_write_o     : out std_logic;
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
mem_edge_o.addr <= fetch_r.mem_addr;

fetch_comb: process(fetch_r, rst_i, mem_edge_i.last, abv_pointer_i)
    variable v : fetch_out_type;
begin
    v := fetch_r;

    if rst_i = '1' then
        -- reset
        v.mem_addr := (others => '0');

    elsif mem_edge_i.last = '1' then
        -- from stack if there no other children from current node
        v.mem_addr := abv_pointer_i;
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

blw_pointer_o <= mem_edge_i.pointer;
blw_write_o   <= execute_r.inference_res;

exe_matcher: matcher generic map
(
    G_STRUCTURE     => G_MATCH_STRCT,
    G_FUNCTION_A    => G_MATCH_FUNCTION_A,
    G_FUNCTION_B    => G_MATCH_FUNCTION_B,
    G_FUNCTION_PAIR => G_MATCH_FUNCTION_PAIR
)
port map
(
    opA_rule_i      => mem_edge_i.opA,
    opA_query_i     => query_opA_i,
    opB_rule_i      => mem_edge_i.opB,
    opB_query_i     => query_opB_i,
    match_result_o  => sig_exe_match_result
);

execute_comb : process(execute_r, mem_edge_i.weight, weight_filter_i, sig_exe_match_result)
    variable v : execute_out_type;
    variable v_weight_check : std_logic;
begin
    v := execute_r;

    -- weight_control
    v_weight_check := mem_edge_i.weight >= weight_filter_i;

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