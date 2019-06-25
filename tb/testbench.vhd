library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library tools;
use tools.std_pkg.all;

library bre;
use bre.engine_pkg.all;
use bre.core_pkg.all;

entity testbench is
end testbench;

architecture testbench of testbench is
    constant CLK_PERIOD : time := 100 ns;

    signal sys_clk    : std_logic := '0';
    signal sys_rst    : std_logic := '0';
    signal queries    : query_in_array_type;
    signal mem_edge   : edge_store_type;
    signal mem_wren_i : std_logic_vector(1 downto 0);
    signal mem_addr_i : std_logic_vector(CFG_MEM_ADDR_WIDTH - 1 downto 0);
begin

sim : process
begin
    mem_edge.operand_a       <= (others => 'Z');
    mem_edge.operand_b       <= (others => 'Z');
    mem_edge.weight          <= 0;
    mem_edge.pointer         <= (others => 'Z');
    mem_edge.last            <= 'Z';
    wait until rising_edge(sys_clk);
    -- Bank Memory 0 load
    mem_edge.operand_a       <= x"AAA";
    mem_edge.operand_b       <= x"DDD";
    mem_edge.weight          <= 500;
    mem_edge.pointer         <= "0000100";
    mem_edge.last            <= '0';
    mem_addr_i               <= (others => '0');
    mem_wren_i               <= "01";
    wait until rising_edge(sys_clk);
    mem_edge.operand_a       <= x"EEE";
    mem_edge.operand_b       <= x"FFF";
    mem_edge.weight          <= 30;
    mem_edge.pointer         <= "1010101";
    mem_addr_i               <= increment(mem_addr_i);
    wait until rising_edge(sys_clk);
    mem_edge.operand_a       <= x"000";
    mem_edge.operand_b       <= x"111";
    mem_addr_i               <= increment(mem_addr_i);
    wait until rising_edge(sys_clk);
    mem_edge.operand_a       <= x"222";
    mem_edge.operand_b       <= x"333";
    mem_addr_i               <= increment(mem_addr_i);
    wait until rising_edge(sys_clk);
    mem_edge.operand_a       <= x"444";
    mem_edge.operand_b       <= x"555";
    mem_addr_i               <= increment(mem_addr_i);
    wait until rising_edge(sys_clk);
    mem_edge.operand_a       <= x"CCC";
    mem_edge.operand_b       <= x"000";
    mem_addr_i               <= increment(mem_addr_i);
    wait until rising_edge(sys_clk);
    mem_edge.operand_a       <= x"000";
    mem_edge.operand_b       <= x"BBB";
    mem_edge.weight          <= 100;
    mem_edge.pointer         <= "0000000";
    mem_addr_i               <= increment(mem_addr_i);
    wait until rising_edge(sys_clk);
    mem_edge.operand_a       <= x"AAA";
    mem_edge.operand_b       <= x"BBB";
    mem_edge.weight          <= 600;
    mem_edge.pointer         <= "0000000";
    mem_edge.last            <= '1';
    mem_addr_i               <= increment(mem_addr_i);
    wait until rising_edge(sys_clk);
    -- Bank Memory 1 load
    mem_edge.operand_a       <= std_logic_vector(to_unsigned(  0, mem_edge.operand_a'length));
    mem_edge.operand_b       <= std_logic_vector(to_unsigned( 10, mem_edge.operand_b'length));
    mem_edge.weight          <= 30;
    mem_edge.pointer         <= "0101010";
    mem_edge.last            <= '0';
    mem_addr_i               <= (others => '0');
    mem_wren_i               <= "10";
    wait until rising_edge(sys_clk);
    mem_edge.operand_a       <= std_logic_vector(to_unsigned(100, mem_edge.operand_a'length));
    mem_edge.operand_b       <= std_logic_vector(to_unsigned(200, mem_edge.operand_b'length));
    mem_addr_i               <= increment(mem_addr_i);
    wait until rising_edge(sys_clk);
    mem_edge.operand_a       <= std_logic_vector(to_unsigned(300, mem_edge.operand_a'length));
    mem_edge.operand_b       <= std_logic_vector(to_unsigned(500, mem_edge.operand_b'length));
    mem_addr_i               <= increment(mem_addr_i);
    wait until rising_edge(sys_clk);
    mem_edge.operand_a       <= std_logic_vector(to_unsigned(100, mem_edge.operand_a'length));
    mem_edge.operand_b       <= std_logic_vector(to_unsigned(500, mem_edge.operand_b'length));
    mem_edge.weight          <= 500;
    mem_edge.pointer         <= "0000000";
    mem_addr_i               <= increment(mem_addr_i);
    wait until rising_edge(sys_clk);
    mem_edge.operand_a       <= std_logic_vector(to_unsigned(250, mem_edge.operand_a'length));
    mem_edge.operand_b       <= std_logic_vector(to_unsigned( 30, mem_edge.operand_b'length));
    mem_edge.weight          <= 30;
    mem_edge.pointer         <= "0101010";
    mem_addr_i               <= increment(mem_addr_i);
    wait until rising_edge(sys_clk);
    mem_edge.operand_a       <= std_logic_vector(to_unsigned(250, mem_edge.operand_a'length));
    mem_edge.operand_b       <= std_logic_vector(to_unsigned(250, mem_edge.operand_b'length));
    mem_edge.weight          <= 100;
    mem_edge.pointer         <= "0000000";
    mem_edge.last            <= '1';
    mem_addr_i               <= increment(mem_addr_i);
    wait until rising_edge(sys_clk);
    mem_addr_i               <= (others => '0');
    mem_wren_i               <= (others => '0');
    mem_edge.operand_a       <= (others => 'Z');
    mem_edge.operand_b       <= (others => 'Z');
    mem_edge.weight          <= 0;
    mem_edge.pointer         <= (others => 'Z');
    mem_edge.last            <= 'Z';
    wait until rising_edge(sys_clk);
    queries(0) <= x"AAA";
    queries(1) <= x"BBB";
    queries(2) <= std_logic_vector(to_unsigned(250, mem_edge.operand_a'length));
    wait until rising_edge(sys_clk);
    -- queries(0)  <= C_RULE_A;
    -- queries(1) <= conv_std_logic_vector(C_LBL_MKT_OSL, C_ENGINE_CRITERIUM_WIDTH);
    -- queries(2) <= conv_std_logic_vector(C_LBL_MKT_EWR, C_ENGINE_CRITERIUM_WIDTH);
    -- queries(3) <= C_DT_07JUL2009;
    -- queries(4) <= C_DT_01JAN9999;
    -- queries(5) <= conv_std_logic_vector(C_LBL_CAB_M, C_ENGINE_CRITERIUM_WIDTH);
    -- queries(6) <= conv_std_logic_vector(C_LBL_OPAIR_2X, C_ENGINE_CRITERIUM_WIDTH);
    -- queries(7) <= conv_std_logic_vector(C_LBL_FG_RMSOND, C_ENGINE_CRITERIUM_WIDTH);
    -- queries(8)   <= conv_std_logic_vector(C_LBL_BKG_OFF, C_ENGINE_CRITERIUM_WIDTH);
    -- wait until rising_edge(sys_clk);
    -- queries(0)  <= C_RULE_A;
    -- queries(1) <= conv_std_logic_vector(C_LBL_MKT_EWR, C_ENGINE_CRITERIUM_WIDTH);
    -- queries(2) <= conv_std_logic_vector(C_LBL_MKT_CPH, C_ENGINE_CRITERIUM_WIDTH);
    -- queries(3) <= C_DT_07JUL2009;
    -- queries(4) <= C_DT_01JAN9999;
    -- queries(5) <= conv_std_logic_vector(C_LBL_CAB_M, C_ENGINE_CRITERIUM_WIDTH);
    -- queries(6) <= conv_std_logic_vector(C_LBL_OPAIR_2X, C_ENGINE_CRITERIUM_WIDTH);
    -- queries(7) <= conv_std_logic_vector(C_LBL_FG_RMSOND, C_ENGINE_CRITERIUM_WIDTH);
    -- queries(8)   <= conv_std_logic_vector(C_LBL_BKG_OFF, C_ENGINE_CRITERIUM_WIDTH);
    -- wait until rising_edge(sys_clk);
    -- queries(0)  <= C_RULE_A;
    -- queries(1) <= conv_std_logic_vector(C_LBL_MKT_CPH, C_ENGINE_CRITERIUM_WIDTH);
    -- queries(2) <= conv_std_logic_vector(C_LBL_MKT_EWR, C_ENGINE_CRITERIUM_WIDTH);
    -- queries(3) <= C_DT_07JUL2009;
    -- queries(4) <= C_DT_01JAN9999;
    -- queries(5) <= conv_std_logic_vector(C_LBL_CAB_M, C_ENGINE_CRITERIUM_WIDTH);
    -- queries(6) <= conv_std_logic_vector(C_LBL_OPAIR_2X, C_ENGINE_CRITERIUM_WIDTH);
    -- queries(7) <= conv_std_logic_vector(C_LBL_FG_RMSOND, C_ENGINE_CRITERIUM_WIDTH);
    -- queries(8)   <= conv_std_logic_vector(C_LBL_BKG_OFF, C_ENGINE_CRITERIUM_WIDTH);
    -- wait until rising_edge(sys_clk);
    -- queries(0)  <= C_RULE_B;
    -- queries(1) <= conv_std_logic_vector(C_LBL_MKT_WORLD, C_ENGINE_CRITERIUM_WIDTH);
    -- queries(2) <= conv_std_logic_vector(C_LBL_MKT_WORLD, C_ENGINE_CRITERIUM_WIDTH);
    -- queries(3) <= C_DT_04MAY2007;
    -- queries(4) <= C_DT_01JAN9999;
    -- queries(5) <= conv_std_logic_vector(C_LBL_CAB_F, C_ENGINE_CRITERIUM_WIDTH);
    -- queries(6) <= conv_std_logic_vector(C_LBL_OPAIR_2X, C_ENGINE_CRITERIUM_WIDTH);
    -- queries(7) <= conv_std_logic_vector(C_LBL_FG_PRODSLAALLFLTS, C_ENGINE_CRITERIUM_WIDTH);
    -- queries(8)   <= conv_std_logic_vector(C_LBL_BKG_S, C_ENGINE_CRITERIUM_WIDTH);
    wait;
    
end process sim;

dut : entity bre.top port map(
    clk_i    => sys_clk,
    rst_i    => sys_rst,
    query_i  => queries,
    mem_i    => mem_edge,
    mem_wren_i => mem_wren_i,
    mem_addr_i => mem_addr_i
);

sys_clk <= not sys_clk after CLK_PERIOD / 2;
sys_rst <= '1' after 0 ps, '0' after 15*CLK_PERIOD;

end architecture testbench;