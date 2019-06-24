library IEEE;
use IEEE.STD_LOGIC_1164.all;

library std;
use std.pkg_ram.all;

library bre;
use bre.pkg_bre.all;

entity top is
    port (
        clk_i    :  in std_logic;
        rst_i    :  in std_logic;
        query_i  :  in query_in_array_type;
        result_o : out std_logic_vector(157 downto 0);
        mem_i    :  in std_logic_vector(200 downto 0);
        meme_i   :  in std_logic_vector(5 downto 0)
    );
end top;

architecture behavioural of top is
    signal sig_fc_blabla : std_logic;
begin

fnc_ruleA: matcher generic map (
    G_STRUCTURE         => C_STRCT_SIMPLE,
    G_VALUE_A           => C_RULE_A,
    G_FUNCTION_A        => C_FNCTR_SIMP_SEQ
)
port map (
    query_opA_i         => query_i(C_QUERY_RTD),
    match_result_o      => sig_fnc_ruleA
);
fnc_ruleB: matcher generic map (
    G_STRUCTURE         => C_STRCT_SIMPLE,
    G_VALUE_A           => C_RULE_B,
    G_FUNCTION_A        => C_FNCTR_SIMP_SEQ
)
port map (
    query_opA_i         => query_i(C_QUERY_RTD),
    match_result_o      => sig_fnc_ruleB
);

-- *-*-*-*-*-*--*-*-*-*-*-*-*-*-*--*-*-*-
-- MARKET  || WORLD | OSL | EWR | CPH | EUROPE
--         ||   0   |  1  |  2  |  3  |    4
-- *-*-*-*-*-*--*-*-*-*-*-*-*-*-*--*-*-*-
-- WORLD   ||   1   |  0  |  0  |  0  |    0
-- OSL     ||   1   |  1  |  0  |  0  |    1
-- EWR     ||   1   |  0  |  1  |  0  |    0
-- CPH     ||   1   |  0  |  0  |  1  |    1
-- OTHER   ||   1   |  0  |  0  |  0  |    0
--
bram_marketA : xilinx_single_port_ram_no_change
  generic map (
     RAM_WIDTH => C_BRAM_MARKT_WIDTH,
     RAM_DEPTH => C_BRAM_MARKT_DEPTH,
     RAM_PERFORMANCE => "LOW_LATENCY", --"HIGH_PERFORMANCE",
     INIT_FILE => "bram_markt.mem"
  )
  port map (
    clka   => clk_i,
    addra  => query_i(C_QUERY_MKTA)((clogb2(C_BRAM_MARKT_DEPTH)-1) downto 0),
    douta  => sig_ram_mrktA,
    dina   => mem_i(C_BRAM_MARKT_WIDTH-1 downto 0),
    ena    => '1',              -- RAM Enable, for additional power savings, disable port when not in use
    wea    => meme_i(0),
    rsta   => '0',              -- Output reset (does not affect memory contents)
    regcea => '1'               -- Output register enable
);

fnc_15MAY200801JAN9999: matcher generic map -- 15MAY2008,01JAN9999
(
    G_STRUCTURE         => C_STRCT_PAIR,
    G_VALUE_A           => C_DT_15MAY2008,
    G_VALUE_B           => C_DT_01JAN9999,
    G_FUNCTION_A        => C_FNCTR_SIMP_DSE,
    G_FUNCTION_B        => C_FNCTR_SIMP_DIE,
    G_FUNCTION_PAIR     => C_FNCTR_PAIR_PCA
)
port map (
    query_opA_i         => query_i(C_QUERY_DATEA),
    query_opB_i         => query_i(C_QUERY_DATEB),
    match_result_o      => sig_fnc_15MAY200801JAN9999
);

sig_rule_A_342890310 <= sig_fnc_ruleAr
                        and ((sig_ram_mrktA(C_LBL_MKT_OSL) and sig_ram_mrktB(C_LBL_MKT_EWR))
                        or (sig_ram_mrktA(C_LBL_MKT_EWR) and sig_ram_mrktB(C_LBL_MKT_OSL)))
                        and sig_ram_cabin(C_LBL_CAB_M)
                        and sig_ram_opair(C_LBL_OPAIR_2X)
                        and sig_ram_flgrp(C_LBL_FG_RMSOND);

process(clk_i, rst_i)
begin
    if rst_i = '1' then

    elsif rising_edge(clk_i) then

    end if;
end process;



-- core
-- ports:
--      - in query
--      - in mem_fetch
--      - in stack
--      - out addr
--      - stack
--      - mct result - couple(value, weight?)
-- 
-- stage 1: fetch
--      - 
-- stage 2: exe
-- stage 3: mem

end architecture behavioural;