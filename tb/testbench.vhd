library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;

library abr;
use abr.pkg_abr.all;

entity nfabre_testbench is
end nfabre_testbench;

architecture testbench of nfabre_testbench is
    constant CLK_PERIOD : time := 100 ns;

    signal sys_clk    : std_logic := '0';
    signal sys_rst    : std_logic := '0';
    signal queries    : query_in_array_type;
    signal results    : std_logic_vector(157 downto 0);
    signal z_mem      : std_logic_vector(200 downto 0);
    signal z_en       : std_logic_vector(5 downto 0) := (others => '0');
begin

sim : process
begin
    wait until rising_edge(sys_clk);
    wait until rising_edge(sys_clk);
    queries(C_QUERY_RULE)  <= (others => '0');
    queries(C_QUERY_MRKTA) <= (others => '0');
    queries(C_QUERY_MRKTB) <= (others => '0');
    queries(C_QUERY_DATEA) <= (others => '0');
    queries(C_QUERY_DATEB) <= (others => '0');
    queries(C_QUERY_CABIN) <= (others => '0');
    queries(C_QUERY_OPAIR) <= (others => '0');
    queries(C_QUERY_FLGRP) <= (others => '0');
    queries(C_QUERY_BKG)   <= (others => '0');
    wait until rising_edge(sys_clk);
    queries(C_QUERY_RULE)  <= C_RULE_A;
    queries(C_QUERY_MRKTA) <= conv_std_logic_vector(C_LBL_MKT_OSL, C_ENGINE_CRITERIUM_WIDTH);
    queries(C_QUERY_MRKTB) <= conv_std_logic_vector(C_LBL_MKT_EWR, C_ENGINE_CRITERIUM_WIDTH);
    queries(C_QUERY_DATEA) <= C_DT_07JUL2009;
    queries(C_QUERY_DATEB) <= C_DT_01JAN9999;
    queries(C_QUERY_CABIN) <= conv_std_logic_vector(C_LBL_CAB_M, C_ENGINE_CRITERIUM_WIDTH);
    queries(C_QUERY_OPAIR) <= conv_std_logic_vector(C_LBL_OPAIR_2X, C_ENGINE_CRITERIUM_WIDTH);
    queries(C_QUERY_FLGRP) <= conv_std_logic_vector(C_LBL_FG_RMSOND, C_ENGINE_CRITERIUM_WIDTH);
    queries(C_QUERY_BKG)   <= conv_std_logic_vector(C_LBL_BKG_OFF, C_ENGINE_CRITERIUM_WIDTH);
    wait until rising_edge(sys_clk);
    queries(C_QUERY_RULE)  <= C_RULE_A;
    queries(C_QUERY_MRKTA) <= conv_std_logic_vector(C_LBL_MKT_EWR, C_ENGINE_CRITERIUM_WIDTH);
    queries(C_QUERY_MRKTB) <= conv_std_logic_vector(C_LBL_MKT_CPH, C_ENGINE_CRITERIUM_WIDTH);
    queries(C_QUERY_DATEA) <= C_DT_07JUL2009;
    queries(C_QUERY_DATEB) <= C_DT_01JAN9999;
    queries(C_QUERY_CABIN) <= conv_std_logic_vector(C_LBL_CAB_M, C_ENGINE_CRITERIUM_WIDTH);
    queries(C_QUERY_OPAIR) <= conv_std_logic_vector(C_LBL_OPAIR_2X, C_ENGINE_CRITERIUM_WIDTH);
    queries(C_QUERY_FLGRP) <= conv_std_logic_vector(C_LBL_FG_RMSOND, C_ENGINE_CRITERIUM_WIDTH);
    queries(C_QUERY_BKG)   <= conv_std_logic_vector(C_LBL_BKG_OFF, C_ENGINE_CRITERIUM_WIDTH);
    wait until rising_edge(sys_clk);
    queries(C_QUERY_RULE)  <= C_RULE_A;
    queries(C_QUERY_MRKTA) <= conv_std_logic_vector(C_LBL_MKT_CPH, C_ENGINE_CRITERIUM_WIDTH);
    queries(C_QUERY_MRKTB) <= conv_std_logic_vector(C_LBL_MKT_EWR, C_ENGINE_CRITERIUM_WIDTH);
    queries(C_QUERY_DATEA) <= C_DT_07JUL2009;
    queries(C_QUERY_DATEB) <= C_DT_01JAN9999;
    queries(C_QUERY_CABIN) <= conv_std_logic_vector(C_LBL_CAB_M, C_ENGINE_CRITERIUM_WIDTH);
    queries(C_QUERY_OPAIR) <= conv_std_logic_vector(C_LBL_OPAIR_2X, C_ENGINE_CRITERIUM_WIDTH);
    queries(C_QUERY_FLGRP) <= conv_std_logic_vector(C_LBL_FG_RMSOND, C_ENGINE_CRITERIUM_WIDTH);
    queries(C_QUERY_BKG)   <= conv_std_logic_vector(C_LBL_BKG_OFF, C_ENGINE_CRITERIUM_WIDTH);
    wait until rising_edge(sys_clk);
    queries(C_QUERY_RULE)  <= C_RULE_B;
    queries(C_QUERY_MRKTA) <= conv_std_logic_vector(C_LBL_MKT_WORLD, C_ENGINE_CRITERIUM_WIDTH);
    queries(C_QUERY_MRKTB) <= conv_std_logic_vector(C_LBL_MKT_WORLD, C_ENGINE_CRITERIUM_WIDTH);
    queries(C_QUERY_DATEA) <= C_DT_04MAY2007;
    queries(C_QUERY_DATEB) <= C_DT_01JAN9999;
    queries(C_QUERY_CABIN) <= conv_std_logic_vector(C_LBL_CAB_F, C_ENGINE_CRITERIUM_WIDTH);
    queries(C_QUERY_OPAIR) <= conv_std_logic_vector(C_LBL_OPAIR_2X, C_ENGINE_CRITERIUM_WIDTH);
    queries(C_QUERY_FLGRP) <= conv_std_logic_vector(C_LBL_FG_PRODSLAALLFLTS, C_ENGINE_CRITERIUM_WIDTH);
    queries(C_QUERY_BKG)   <= conv_std_logic_vector(C_LBL_BKG_S, C_ENGINE_CRITERIUM_WIDTH);
    wait;
    
end process sim;

dut : entity abr.top_bram port map(
    clk_i    => sys_clk,
    rst_i    => sys_rst,
    query_i  => queries,
    result_o => results,
    mem_i    => z_mem,
    meme_i   => z_en);

sys_clk <= not sys_clk after CLK_PERIOD / 2;
sys_rst <= '1' after 0 ps, '0' after CLK_PERIOD;

z_mem <= (others => '0');

end architecture testbench;