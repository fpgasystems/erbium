library IEEE;
use IEEE.STD_LOGIC_1164.all;

library std;
use std.pkg_ram.all;

library bre;
use bre.pkg_bre.all;

entity top is
    Port (
        clk_i    :  in std_logic;
        rst_i    :  in std_logic;
        query_i  :  in query_in_array_type;
        result_o : out std_logic_vector(157 downto 0);
        mem_i    :  in std_logic_vector(200 downto 0);
        meme_i   :  in std_logic_vector(5 downto 0)
    );
end top;

architecture behavioural of top is
    signal sig_fnc_ruleA  : std_logic;
    signal sig_fnc_ruleB  : std_logic;
    signal sig_fnc_ruleAr : std_logic;
    signal sig_fnc_ruleBr : std_logic;
    signal sig_ram_mrktA  : std_logic_vector(C_BRAM_MARKT_WIDTH-1 downto 0);
    signal sig_ram_mrktB  : std_logic_vector(C_BRAM_MARKT_WIDTH-1 downto 0);
    signal sig_ram_cabin  : std_logic_vector(C_BRAM_CABIN_WIDTH-1 downto 0);
    signal sig_ram_opair  : std_logic_vector(C_BRAM_OPAIR_WIDTH-1 downto 0);
    signal sig_ram_flgrp  : std_logic_vector(C_BRAM_FLGRP_WIDTH-1 downto 0);
    signal sig_ram_bkg    : std_logic_vector(C_BRAM_BKG_WIDTH-1   downto 0);
    signal sig_rule_A_342890310 : std_logic;
    signal sig_rule_A_326857829 : std_logic;
    signal sig_rule_A_326857828 : std_logic;
    signal sig_rule_A_326857827 : std_logic;
    signal sig_rule_A_326857826 : std_logic;
    signal sig_rule_A_326857825 : std_logic;
    signal sig_rule_A_326857816 : std_logic;
    signal sig_rule_A_342890305 : std_logic;
    signal sig_rule_A_342890303 : std_logic;
    signal sig_rule_A_342877956 : std_logic;
    signal sig_rule_A_337625101 : std_logic;
    signal sig_rule_A_337625100 : std_logic;
    signal sig_rule_A_337625099 : std_logic;
    signal sig_rule_A_337625098 : std_logic;
    signal sig_rule_A_337625095 : std_logic;
    signal sig_rule_A_337625092 : std_logic;
    signal sig_rule_A_337625061 : std_logic;
    signal sig_rule_A_337625060 : std_logic;
    signal sig_rule_A_326857831 : std_logic;
    signal sig_rule_A_326857830 : std_logic;
    signal sig_rule_A_326857824 : std_logic;
    signal sig_rule_A_326857823 : std_logic;
    signal sig_rule_A_326857822 : std_logic;
    signal sig_rule_A_326857821 : std_logic;
    signal sig_rule_A_326857820 : std_logic;
    signal sig_rule_A_326857819 : std_logic;
    signal sig_rule_A_326857818 : std_logic;
    signal sig_rule_A_326857817 : std_logic;
    signal sig_rule_B_18534707 : std_logic;
    signal sig_rule_B_47209736 : std_logic;
    signal sig_rule_B_47209735 : std_logic;
    signal sig_rule_B_47209734 : std_logic;
    signal sig_rule_B_18534770 : std_logic;
    signal sig_rule_B_18534769 : std_logic;
    signal sig_rule_B_18534768 : std_logic;
    signal sig_rule_B_18534766 : std_logic;
    signal sig_rule_B_18534765 : std_logic;
    signal sig_rule_B_18534764 : std_logic;
    signal sig_rule_B_18534763 : std_logic;
    signal sig_rule_B_18534762 : std_logic;
    signal sig_rule_B_18534761 : std_logic;
    signal sig_rule_B_18534760 : std_logic;
    signal sig_rule_B_18534759 : std_logic;
    signal sig_rule_B_18534758 : std_logic;
    signal sig_rule_B_18534757 : std_logic;
    signal sig_rule_B_18534756 : std_logic;
    signal sig_rule_B_18534755 : std_logic;
    signal sig_rule_B_18534754 : std_logic;
    signal sig_rule_B_18534753 : std_logic;
    signal sig_rule_B_18534752 : std_logic;
    signal sig_rule_B_18534751 : std_logic;
    signal sig_rule_B_18534750 : std_logic;
    signal sig_rule_B_18534749 : std_logic;
    signal sig_rule_B_18534748 : std_logic;
    signal sig_rule_B_18534747 : std_logic;
    signal sig_rule_B_18534746 : std_logic;
    signal sig_rule_B_18534745 : std_logic;
    signal sig_rule_B_18534744 : std_logic;
    signal sig_rule_B_18534743 : std_logic;
    signal sig_rule_B_18534742 : std_logic;
    signal sig_rule_B_18534741 : std_logic;
    signal sig_rule_B_18534740 : std_logic;
    signal sig_rule_B_18534739 : std_logic;
    signal sig_rule_B_18534738 : std_logic;
    signal sig_rule_B_18534737 : std_logic;
    signal sig_rule_B_18534736 : std_logic;
    signal sig_rule_B_18534735 : std_logic;
    signal sig_rule_B_18534734 : std_logic;
    signal sig_rule_B_18534733 : std_logic;
    signal sig_rule_B_18534732 : std_logic;
    signal sig_rule_B_18534731 : std_logic;
    signal sig_rule_B_18534730 : std_logic;
    signal sig_rule_B_18534729 : std_logic;
    signal sig_rule_B_18534716 : std_logic;
    signal sig_rule_B_18534712 : std_logic;
    signal sig_rule_B_18534706 : std_logic;
    signal sig_rule_B_18534688 : std_logic;
    signal sig_rule_B_18534687 : std_logic;
    signal sig_rule_B_18534686 : std_logic;
    signal sig_rule_B_18534685 : std_logic;
    signal sig_rule_B_18534684 : std_logic;
    signal sig_rule_B_18534683 : std_logic;
    signal sig_rule_B_18534682 : std_logic;
    signal sig_rule_B_18534681 : std_logic;
    signal sig_rule_B_18534680 : std_logic;
    signal sig_rule_B_18534679 : std_logic;
    signal sig_rule_B_18534678 : std_logic;
    signal sig_rule_B_18534677 : std_logic;
    signal sig_rule_B_18534676 : std_logic;
    signal sig_rule_B_18534675 : std_logic;
    signal sig_rule_B_18534673 : std_logic;
    signal sig_rule_B_18534667 : std_logic;
    signal sig_rule_B_18534666 : std_logic;
    signal sig_rule_B_18534665 : std_logic;
    signal sig_rule_B_18534664 : std_logic;
    signal sig_rule_B_18534663 : std_logic;
    signal sig_rule_B_18534662 : std_logic;
    signal sig_rule_B_18534658 : std_logic;
    signal sig_rule_B_18534657 : std_logic;
    signal sig_rule_B_18534656 : std_logic;
    signal sig_rule_B_18534652 : std_logic;
    signal sig_rule_B_18534651 : std_logic;
    signal sig_rule_B_18534650 : std_logic;
    signal sig_rule_B_18534649 : std_logic;
    signal sig_rule_B_18534648 : std_logic;
    signal sig_rule_B_18534647 : std_logic;
    signal sig_rule_B_18534646 : std_logic;
    signal sig_rule_B_18534645 : std_logic;
    signal sig_rule_B_18534644 : std_logic;
    signal sig_rule_B_18534643 : std_logic;
    signal sig_rule_B_18534642 : std_logic;
    signal sig_rule_B_18534641 : std_logic;
    signal sig_rule_B_18534640 : std_logic;
    signal sig_rule_B_18534639 : std_logic;
    signal sig_rule_B_18534638 : std_logic;
    signal sig_rule_B_18534637 : std_logic;
    signal sig_rule_B_18534636 : std_logic;
    signal sig_rule_B_18534635 : std_logic;
    signal sig_rule_B_18534634 : std_logic;
    signal sig_rule_B_18534633 : std_logic;
    signal sig_rule_B_18534632 : std_logic;
    signal sig_rule_B_18534631 : std_logic;
    signal sig_rule_B_18534630 : std_logic;
    signal sig_rule_B_18534702 : std_logic;
    signal sig_rule_B_18534701 : std_logic;
    signal sig_rule_B_18534700 : std_logic;
    signal sig_rule_B_18534699 : std_logic;
    signal sig_rule_B_18534698 : std_logic;
    signal sig_rule_B_18534697 : std_logic;
    signal sig_rule_B_18534696 : std_logic;
    signal sig_rule_B_18534695 : std_logic;
    signal sig_rule_B_18534694 : std_logic;
    signal sig_rule_B_18534693 : std_logic;
    signal sig_rule_B_18534692 : std_logic;
    signal sig_rule_B_18534691 : std_logic;
    signal sig_rule_B_18534690 : std_logic;
    signal sig_rule_B_18534689 : std_logic;
    signal sig_rule_B_18534621 : std_logic;
    signal sig_rule_B_18534620 : std_logic;
    signal sig_rule_B_18534619 : std_logic;
    signal sig_rule_B_18534618 : std_logic;
    signal sig_rule_B_18534617 : std_logic;
    signal sig_rule_B_18534616 : std_logic;
    signal sig_rule_B_18534615 : std_logic;
    signal sig_rule_B_18534614 : std_logic;
    signal sig_rule_B_18534613 : std_logic;
    signal sig_rule_B_18534612 : std_logic;
    signal sig_rule_B_18534611 : std_logic;
    signal sig_rule_B_18534610 : std_logic;
    signal sig_rule_B_18534609 : std_logic;
    signal sig_rule_B_18534608 : std_logic;
    signal sig_rule_B_18534607 : std_logic;
    signal sig_rule_B_18534606 : std_logic;
    signal sig_rule_B_18534605 : std_logic;
    signal sig_rule_B_18534604 : std_logic;
    signal sig_rule_B_18534603 : std_logic;
    signal sig_rule_B_18534602 : std_logic;
    signal sig_rule_B_18534601 : std_logic;
    signal sig_fnc_04MAY200701JAN9999  : std_logic;
    signal sig_fnc_15MAY200801JAN9999  : std_logic;
    signal sig_fnc_07JUL200901JAN9999  : std_logic;
    signal sig_fnc_08JUL200901JAN9999  : std_logic;
    signal sig_fnc_18APR201501JAN9999  : std_logic;
    signal sig_fnc_04MAY200701JAN9999r : std_logic;
    signal sig_fnc_15MAY200801JAN9999r : std_logic;
    signal sig_fnc_07JUL200901JAN9999r : std_logic;
    signal sig_fnc_08JUL200901JAN9999r : std_logic;
    signal sig_fnc_18APR201501JAN9999r : std_logic;
begin

fnc_ruleA: matcher generic map (
    G_STRUCTURE         => C_STRCT_SIMPLE,
    G_VALUE_A           => C_RULE_A,
    G_FUNCTION_A        => C_FNCTR_SIMP_SEQ
)
port map (
    query_opA_i         => query_i(C_QUERY_RULE),
    match_result_o      => sig_fnc_ruleA
);
fnc_ruleB: matcher generic map (
    G_STRUCTURE         => C_STRCT_SIMPLE,
    G_VALUE_A           => C_RULE_B,
    G_FUNCTION_A        => C_FNCTR_SIMP_SEQ
)
port map (
    query_opA_i         => query_i(C_QUERY_RULE),
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
    addra  => query_i(C_QUERY_MRKTA)((clogb2(C_BRAM_MARKT_DEPTH)-1) downto 0),
    douta  => sig_ram_mrktA,
    dina   => mem_i(C_BRAM_MARKT_WIDTH-1 downto 0),
    ena    => '1',              -- RAM Enable, for additional power savings, disable port when not in use
    wea    => meme_i(0),
    rsta   => '0',              -- Output reset (does not affect memory contents)
    regcea => '1'               -- Output register enable
);
bram_marketB : xilinx_single_port_ram_no_change
  generic map (
     RAM_WIDTH => C_BRAM_MARKT_WIDTH,
     RAM_DEPTH => C_BRAM_MARKT_DEPTH,
     RAM_PERFORMANCE => "LOW_LATENCY", --"HIGH_PERFORMANCE",
     INIT_FILE => "bram_markt.mem"
  )
  port map (
    clka   => clk_i,
    addra  => query_i(C_QUERY_MRKTB)((clogb2(C_BRAM_MARKT_DEPTH)-1) downto 0),
    douta  => sig_ram_mrktB,    -- RAM output data
    dina   => mem_i(C_BRAM_MARKT_WIDTH-1 downto 0),
    ena    => '1',              -- RAM Enable, for additional power savings, disable port when not in use
    wea    => meme_i(1),           -- Write enmeme_ie
    rsta   => '0',              -- Output reset (does not affect memory contents)
    regcea => '1'               -- Output register enable
);


-- *-*-*-*-*-*--*-*-*-*-*-*-*-*-*--*-*-*-
-- CABIN   ||  C  |  J  |  M  |  Y  |
--         ||  0  |  1  |  2  |  3  |
-- *-*-*-*-*-*--*-*-*-*-*-*-*-*-*--*-*-*-
-- C       ||  1  |  0  |  0  |  0  |
-- J       ||  0  |  1  |  0  |  0  |
-- M       ||  0  |  0  |  1  |  0  |
-- Y       ||  0  |  0  |  0  |  1  |
-- OTHER   ||  0  |  0  |  0  |  0  |
--
bram_cabin : xilinx_single_port_ram_no_change
  generic map (
     RAM_WIDTH => C_BRAM_CABIN_WIDTH,
     RAM_DEPTH => C_BRAM_CABIN_DEPTH,
     RAM_PERFORMANCE => "LOW_LATENCY", --"HIGH_PERFORMANCE",
     INIT_FILE => "bram_cabin.mem"
  )
  port map (
    clka   => clk_i,
    addra  => query_i(C_QUERY_CABIN)((clogb2(C_BRAM_CABIN_DEPTH)-1) downto 0),
    dina   => mem_i(C_BRAM_CABIN_WIDTH-1 downto 0),
    wea    => meme_i(2),
    ena    => '1',
    rsta   => '0',
    regcea => '1',
    douta  => sig_ram_cabin
);


-- *-*-*-*-*-*--*-*-*-*-*-*-*-*-*--*-*-*-
-- S_OPAIR || ALL | 2_X | 8_X |
--         ||  0  |  1  |  2  |
-- *-*-*-*-*-*--*-*-*-*-*-*-*-*-*--*-*-*-
-- ALL     ||  1  |  1  |  0  |
-- 2X      ||  1  |  0  |  1  |
-- 8X      ||  1  |  0  |  0  |
-- OTHER   ||  1  |  0  |  0  |
--
bram_opair : xilinx_single_port_ram_no_change
  generic map (
     RAM_WIDTH => C_BRAM_OPAIR_WIDTH,
     RAM_DEPTH => C_BRAM_OPAIR_DEPTH,
     RAM_PERFORMANCE => "LOW_LATENCY", --"HIGH_PERFORMANCE",
     INIT_FILE => "bram_opair.mem"
  )
  port map (
    clka   => clk_i,
    addra  => query_i(C_QUERY_OPAIR)((clogb2(C_BRAM_OPAIR_DEPTH)-1) downto 0),
    dina   => mem_i(C_BRAM_OPAIR_WIDTH-1 downto 0),
    wea    => meme_i(3),
    ena    => '1',
    rsta   => '0',
    regcea => '1',
    douta  => sig_ram_opair
);


-- SBSFLIGHTS | TRNPBCODE | RMSOND | SAFLIGHTS | ALL2X | 101211093 | 101211096 | 101211097 | 101211098 | 101211099 | 101211100 | 105310439 | 106769036 | PRODSLAALLFLTS |
-- 
-- ...
-- 150K LINES x 14 COLUMNS = 311 KBYTES
-- ...
-- 
bram_flgrp : xilinx_single_port_ram_no_change
  generic map (
     RAM_WIDTH => C_BRAM_FLGRP_WIDTH,
     RAM_DEPTH => C_BRAM_FLGRP_DEPTH,
     RAM_PERFORMANCE => "LOW_LATENCY", --"HIGH_PERFORMANCE",
     INIT_FILE => "bram_flgrp.mem"
  )
  port map (
    clka   => clk_i,
    addra  => query_i(C_QUERY_FLGRP)((clogb2(C_BRAM_FLGRP_DEPTH)-1) downto 0),
    dina   => mem_i(C_BRAM_FLGRP_WIDTH-1 downto 0),
    wea    => meme_i(4),
    ena    => '1',
    rsta   => '0',
    regcea => '1',
    douta  => sig_ram_flgrp
);


-- *-*-*-*-*-*--*-*-*-*-*-*-*-*-*--*-*-*-
-- BKG     || A | B | C | D | E | F | G | H | I | J | K | L | M | N | O | P | Q | R | S | T | U | V | W | X | Y | Z
-- *-*-*-*-*-*--*-*-*-*-*-*-*-*-*--*-*-*-
-- ALL     ||  1  |  1  |  0  |
-- 2X      ||  1  |  0  |  1  |
-- 8X      ||  1  |  0  |  0  |
-- OTHER   ||  1  |  0  |  0  |
--
bram_bkg : xilinx_single_port_ram_no_change
  generic map (
     RAM_WIDTH => C_BRAM_BKG_WIDTH,
     RAM_DEPTH => C_BRAM_BKG_DEPTH,
     RAM_PERFORMANCE => "LOW_LATENCY", --"HIGH_PERFORMANCE",
     INIT_FILE => "bram_bkg.mem"
  )
  port map (
    clka   => clk_i,
    addra  => query_i(C_QUERY_BKG)((clogb2(C_BRAM_BKG_DEPTH)-1) downto 0),
    dina   => mem_i(C_BRAM_BKG_WIDTH-1 downto 0),
    wea    => meme_i(5),
    ena    => '1',
    rsta   => '0',
    regcea => '1',
    douta  => sig_ram_bkg
);

fnc_04MAY200701JAN9999: matcher generic map -- 04MAY2007,01JAN9999
(
    G_STRUCTURE         => C_STRCT_PAIR,
    G_VALUE_A           => C_DT_04MAY2007,
    G_VALUE_B           => C_DT_01JAN9999,
    G_FUNCTION_A        => C_FNCTR_SIMP_DSE,
    G_FUNCTION_B        => C_FNCTR_SIMP_DIE,
    G_FUNCTION_PAIR     => C_FNCTR_PAIR_PCA
)
port map (
    query_opA_i         => query_i(C_QUERY_DATEA),
    query_opB_i         => query_i(C_QUERY_DATEB),
    match_result_o      => sig_fnc_04MAY200701JAN9999
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
fnc_07JUL200901JAN9999: matcher generic map -- 07JUL2009,01JAN9999
(
    G_STRUCTURE         => C_STRCT_PAIR,
    G_VALUE_A           => C_DT_07JUL2009,
    G_VALUE_B           => C_DT_01JAN9999,
    G_FUNCTION_A        => C_FNCTR_SIMP_DSE,
    G_FUNCTION_B        => C_FNCTR_SIMP_DIE,
    G_FUNCTION_PAIR     => C_FNCTR_PAIR_PCA
)
port map (
    query_opA_i         => query_i(C_QUERY_DATEA),
    query_opB_i         => query_i(C_QUERY_DATEB),
    match_result_o      => sig_fnc_07JUL200901JAN9999
);
fnc_08JUL200901JAN9999: matcher generic map -- 08JUL2009,01JAN9999
(
    G_STRUCTURE         => C_STRCT_PAIR,
    G_VALUE_A           => C_DT_08JUL2009,
    G_VALUE_B           => C_DT_01JAN9999,
    G_FUNCTION_A        => C_FNCTR_SIMP_DSE,
    G_FUNCTION_B        => C_FNCTR_SIMP_DIE,
    G_FUNCTION_PAIR     => C_FNCTR_PAIR_PCA
)
port map (
    query_opA_i         => query_i(C_QUERY_DATEA),
    query_opB_i         => query_i(C_QUERY_DATEB),
    match_result_o      => sig_fnc_08JUL200901JAN9999
);
fnc_18APR201501JAN9999: matcher generic map -- 18APR2015,01JAN9999
(
    G_STRUCTURE         => C_STRCT_PAIR,
    G_VALUE_A           => C_DT_18APR2015,
    G_VALUE_B           => C_DT_01JAN9999,
    G_FUNCTION_A        => C_FNCTR_SIMP_DSE,
    G_FUNCTION_B        => C_FNCTR_SIMP_DIE,
    G_FUNCTION_PAIR     => C_FNCTR_PAIR_PCA
)
port map (
    query_opA_i         => query_i(C_QUERY_DATEA),
    query_opB_i         => query_i(C_QUERY_DATEB),
    match_result_o      => sig_fnc_18APR201501JAN9999
);

sig_rule_A_342890310 <= sig_fnc_ruleAr
                        and ((sig_ram_mrktA(C_LBL_MKT_OSL) and sig_ram_mrktB(C_LBL_MKT_EWR))
                        or (sig_ram_mrktA(C_LBL_MKT_EWR) and sig_ram_mrktB(C_LBL_MKT_OSL)))
                        and sig_ram_cabin(C_LBL_CAB_M)
                        and sig_ram_opair(C_LBL_OPAIR_2X)
                        and sig_ram_flgrp(C_LBL_FG_RMSOND);
sig_rule_A_326857829 <= sig_fnc_ruleAr
                        and ((sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        or (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD)))
                        and sig_fnc_08JUL200901JAN9999r
                        and sig_ram_cabin(C_LBL_CAB_M)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_SBSFLIGHTS);
sig_rule_A_326857828 <= sig_fnc_ruleAr
                        and ((sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        or (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD)))
                        and sig_fnc_07JUL200901JAN9999r
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_SBSFLIGHTS);
sig_rule_A_326857827 <= sig_fnc_ruleAr
                        and ((sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        or (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD)))
                        and sig_fnc_07JUL200901JAN9999r
                        and sig_ram_cabin(C_LBL_CAB_J)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_SBSFLIGHTS);
sig_rule_A_326857826 <= sig_fnc_ruleAr
                        and ((sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        or (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD)))
                        and sig_fnc_15MAY200801JAN9999r
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_TRNPBCODE);
sig_rule_A_326857825 <= sig_fnc_ruleAr
                        and ((sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        or (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD)))
                        and sig_fnc_15MAY200801JAN9999r
                        and sig_ram_cabin(C_LBL_CAB_J)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_TRNPBCODE);
sig_rule_A_326857816 <= sig_fnc_ruleAr
                        and ((sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        or (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD)))
                        and sig_fnc_18APR201501JAN9999r
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_opair(C_LBL_OPAIR_2X)
                        and sig_ram_flgrp(C_LBL_FG_105310439);
sig_rule_A_342890305 <= sig_fnc_ruleAr
                        and ((sig_ram_mrktA(C_LBL_MKT_OSL) and sig_ram_mrktB(C_LBL_MKT_EWR))
                        or (sig_ram_mrktA(C_LBL_MKT_EWR) and sig_ram_mrktB(C_LBL_MKT_OSL)))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_opair(C_LBL_OPAIR_2X)
                        and sig_ram_flgrp(C_LBL_FG_RMSOND);
sig_rule_A_342890303 <= sig_fnc_ruleAr
                        and ((sig_ram_mrktA(C_LBL_MKT_OSL) and sig_ram_mrktB(C_LBL_MKT_EWR))
                        or (sig_ram_mrktA(C_LBL_MKT_EWR) and sig_ram_mrktB(C_LBL_MKT_OSL)))
                        and sig_ram_cabin(C_LBL_CAB_C)
                        and sig_ram_opair(C_LBL_OPAIR_2X)
                        and sig_ram_flgrp(C_LBL_FG_RMSOND);
sig_rule_A_342877956 <= sig_fnc_ruleAr
                        and ((sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        or (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD)))
                        and sig_ram_cabin(C_LBL_CAB_J)
                        and sig_ram_opair(C_LBL_OPAIR_2X)
                        and sig_ram_flgrp(C_LBL_FG_106769036);
sig_rule_A_337625101 <= sig_fnc_ruleAr
                        and ((sig_ram_mrktA(C_LBL_MKT_EWR) and sig_ram_mrktB(C_LBL_MKT_CPH))
                        or (sig_ram_mrktA(C_LBL_MKT_CPH) and sig_ram_mrktB(C_LBL_MKT_EWR)))
                        and sig_ram_cabin(C_LBL_CAB_M)
                        and sig_ram_opair(C_LBL_OPAIR_2X)
                        and sig_ram_flgrp(C_LBL_FG_RMSOND);
sig_rule_A_337625100 <= sig_fnc_ruleAr
                        and ((sig_ram_mrktA(C_LBL_MKT_EWR) and sig_ram_mrktB(C_LBL_MKT_CPH))
                        or (sig_ram_mrktA(C_LBL_MKT_CPH) and sig_ram_mrktB(C_LBL_MKT_EWR)))
                        and sig_ram_cabin(C_LBL_CAB_C)
                        and sig_ram_opair(C_LBL_OPAIR_2X)
                        and sig_ram_flgrp(C_LBL_FG_RMSOND);
sig_rule_A_337625099 <= sig_fnc_ruleAr
                        and ((sig_ram_mrktA(C_LBL_MKT_EWR) and sig_ram_mrktB(C_LBL_MKT_CPH))
                        or (sig_ram_mrktA(C_LBL_MKT_CPH) and sig_ram_mrktB(C_LBL_MKT_EWR)))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_opair(C_LBL_OPAIR_2X)
                        and sig_ram_flgrp(C_LBL_FG_RMSOND);
sig_rule_A_337625098 <= sig_fnc_ruleAr
                        and ((sig_ram_mrktA(C_LBL_MKT_CPH) and sig_ram_mrktB(C_LBL_MKT_EWR))
                        or (sig_ram_mrktA(C_LBL_MKT_EWR) and sig_ram_mrktB(C_LBL_MKT_CPH)))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_opair(C_LBL_OPAIR_2X)
                        and sig_ram_flgrp(C_LBL_FG_RMSOND);
sig_rule_A_337625095 <= sig_fnc_ruleAr
                        and ((sig_ram_mrktA(C_LBL_MKT_CPH) and sig_ram_mrktB(C_LBL_MKT_EWR))
                        or (sig_ram_mrktA(C_LBL_MKT_EWR) and sig_ram_mrktB(C_LBL_MKT_CPH)))
                        and sig_ram_cabin(C_LBL_CAB_M)
                        and sig_ram_opair(C_LBL_OPAIR_2X)
                        and sig_ram_flgrp(C_LBL_FG_RMSOND);
sig_rule_A_337625092 <= sig_fnc_ruleAr
                        and ((sig_ram_mrktA(C_LBL_MKT_CPH) and sig_ram_mrktB(C_LBL_MKT_EWR))
                        or (sig_ram_mrktA(C_LBL_MKT_EWR) and sig_ram_mrktB(C_LBL_MKT_CPH)))
                        and sig_ram_cabin(C_LBL_CAB_C)
                        and sig_ram_opair(C_LBL_OPAIR_2X)
                        and sig_ram_flgrp(C_LBL_FG_RMSOND);
sig_rule_A_337625061 <= sig_fnc_ruleAr
                        and ((sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        or (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD)))
                        and sig_ram_cabin(C_LBL_CAB_M)
                        and sig_ram_opair(C_LBL_OPAIR_2X)
                        and sig_ram_flgrp(C_LBL_FG_RMSOND);
sig_rule_A_337625060 <= sig_fnc_ruleAr
                        and ((sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        or (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD)))
                        and sig_ram_cabin(C_LBL_CAB_C)
                        and sig_ram_opair(C_LBL_OPAIR_2X)
                        and sig_ram_flgrp(C_LBL_FG_RMSOND);
sig_rule_A_326857831 <= sig_fnc_ruleAr
                        and ((sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        or (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD)))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_opair(C_LBL_OPAIR_2X)
                        and sig_ram_flgrp(C_LBL_FG_SAFLIGHTS);
sig_rule_A_326857830 <= sig_fnc_ruleAr
                        and ((sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        or (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD)))
                        and sig_ram_cabin(C_LBL_CAB_C)
                        and sig_ram_opair(C_LBL_OPAIR_2X)
                        and sig_ram_flgrp(C_LBL_FG_SAFLIGHTS);
sig_rule_A_326857824 <= sig_fnc_ruleAr
                        and ((sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        or (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD)))
                        and sig_ram_cabin(C_LBL_CAB_P)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_101211100);
sig_rule_A_326857823 <= sig_fnc_ruleAr
                        and ((sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        or (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD)))
                        and sig_ram_cabin(C_LBL_CAB_W)
                        and sig_ram_opair(C_LBL_OPAIR_2X)
                        and sig_ram_flgrp(C_LBL_FG_101211096);
sig_rule_A_326857822 <= sig_fnc_ruleAr
                        and ((sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        or (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD)))
                        and sig_ram_cabin(C_LBL_CAB_C)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_ALL2X);
sig_rule_A_326857821 <= sig_fnc_ruleAr
                        and ((sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        or (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD)))
                        and sig_ram_cabin(C_LBL_CAB_J)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_ALL2X);
sig_rule_A_326857820 <= sig_fnc_ruleAr
                        and ((sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        or (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD)))
                        and sig_ram_cabin(C_LBL_CAB_F)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_ALL2X);
sig_rule_A_326857819 <= sig_fnc_ruleAr
                        and ((sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        or (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD)))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_ALL2X);
sig_rule_A_326857818 <= sig_fnc_ruleAr
                        and ((sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        or (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD)))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_opair(C_LBL_OPAIR_ALL);
sig_rule_A_326857817 <= sig_fnc_ruleAr
                        and ((sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        or (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD)))
                        and sig_ram_cabin(C_LBL_CAB_J)
                        and sig_ram_opair(C_LBL_OPAIR_ALL);



sig_rule_B_18534707 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_fnc_04MAY200701JAN9999r
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_B)
                        and sig_ram_opair(C_LBL_OPAIR_2X)
                        and sig_ram_flgrp(C_LBL_FG_101211098);
sig_rule_B_47209736 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_C)
                        and sig_ram_bkg(C_LBL_BKG_R)
                        and sig_ram_opair(C_LBL_OPAIR_2X)
                        and sig_ram_flgrp(C_LBL_FG_SAFLIGHTS);
sig_rule_B_47209735 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_C)
                        and sig_ram_bkg(C_LBL_BKG_E)
                        and sig_ram_opair(C_LBL_OPAIR_2X)
                        and sig_ram_flgrp(C_LBL_FG_SAFLIGHTS);
sig_rule_B_47209734 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_C)
                        and sig_ram_bkg(C_LBL_BKG_Z)
                        and sig_ram_opair(C_LBL_OPAIR_2X)
                        and sig_ram_flgrp(C_LBL_FG_SAFLIGHTS);
sig_rule_B_18534770 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_Q)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_SBSFLIGHTS);
sig_rule_B_18534769 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_P)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_SBSFLIGHTS);
sig_rule_B_18534768 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_K)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_SBSFLIGHTS);
sig_rule_B_18534766 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_J)
                        and sig_ram_bkg(C_LBL_BKG_U)
                        and sig_ram_opair(C_LBL_OPAIR_2X)
                        and sig_ram_flgrp(C_LBL_FG_SBSFLIGHTS);
sig_rule_B_18534765 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_J)
                        and sig_ram_bkg(C_LBL_BKG_I)
                        and sig_ram_opair(C_LBL_OPAIR_2X)
                        and sig_ram_flgrp(C_LBL_FG_SBSFLIGHTS);
sig_rule_B_18534764 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_J)
                        and sig_ram_bkg(C_LBL_BKG_D)
                        and sig_ram_opair(C_LBL_OPAIR_2X)
                        and sig_ram_flgrp(C_LBL_FG_SBSFLIGHTS);
sig_rule_B_18534763 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_J)
                        and sig_ram_bkg(C_LBL_BKG_C)
                        and sig_ram_opair(C_LBL_OPAIR_2X)
                        and sig_ram_flgrp(C_LBL_FG_SBSFLIGHTS);
sig_rule_B_18534762 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_J)
                        and sig_ram_bkg(C_LBL_BKG_J)
                        and sig_ram_opair(C_LBL_OPAIR_2X)
                        and sig_ram_flgrp(C_LBL_FG_SBSFLIGHTS);
sig_rule_B_18534761 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_M)
                        and sig_ram_bkg(C_LBL_BKG_E)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_SBSFLIGHTS);
sig_rule_B_18534760 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_M)
                        and sig_ram_bkg(C_LBL_BKG_X)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_SBSFLIGHTS);
sig_rule_B_18534759 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_M)
                        and sig_ram_bkg(C_LBL_BKG_G)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_SBSFLIGHTS);
sig_rule_B_18534758 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_M)
                        and sig_ram_bkg(C_LBL_BKG_O)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_SBSFLIGHTS);
sig_rule_B_18534757 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_M)
                        and sig_ram_bkg(C_LBL_BKG_Q)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_SBSFLIGHTS);
sig_rule_B_18534756 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_M)
                        and sig_ram_bkg(C_LBL_BKG_N)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_SBSFLIGHTS);
sig_rule_B_18534755 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_M)
                        and sig_ram_bkg(C_LBL_BKG_S)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_SBSFLIGHTS);
sig_rule_B_18534754 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_M)
                        and sig_ram_bkg(C_LBL_BKG_V)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_SBSFLIGHTS);
sig_rule_B_18534753 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_M)
                        and sig_ram_bkg(C_LBL_BKG_L)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_SBSFLIGHTS);
sig_rule_B_18534752 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_M)
                        and sig_ram_bkg(C_LBL_BKG_M)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_SBSFLIGHTS);
sig_rule_B_18534751 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_M)
                        and sig_ram_bkg(C_LBL_BKG_K)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_SBSFLIGHTS);
sig_rule_B_18534750 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_M)
                        and sig_ram_bkg(C_LBL_BKG_H)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_SBSFLIGHTS);
sig_rule_B_18534749 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_M)
                        and sig_ram_bkg(C_LBL_BKG_B)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_SBSFLIGHTS);
sig_rule_B_18534748 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_M)
                        and sig_ram_bkg(C_LBL_BKG_Y)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_SBSFLIGHTS);
sig_rule_B_18534747 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_E)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_SBSFLIGHTS);
sig_rule_B_18534746 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_X)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_SBSFLIGHTS);
sig_rule_B_18534745 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_W)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_SBSFLIGHTS);
sig_rule_B_18534744 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_G)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_SBSFLIGHTS);
sig_rule_B_18534743 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_R)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_SBSFLIGHTS);
sig_rule_B_18534742 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_Z)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_SBSFLIGHTS);
sig_rule_B_18534741 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_O)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_SBSFLIGHTS);
sig_rule_B_18534740 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_Q)
                        and sig_ram_opair(C_LBL_OPAIR_2X)
                        and sig_ram_flgrp(C_LBL_FG_SBSFLIGHTS);
sig_rule_B_18534739 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_N)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_SBSFLIGHTS);
sig_rule_B_18534738 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_S)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_SBSFLIGHTS);
sig_rule_B_18534737 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_V)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_SBSFLIGHTS);
sig_rule_B_18534736 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_L)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_SBSFLIGHTS);
sig_rule_B_18534735 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_T)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_SBSFLIGHTS);
sig_rule_B_18534734 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_P)
                        and sig_ram_opair(C_LBL_OPAIR_2X)
                        and sig_ram_flgrp(C_LBL_FG_SBSFLIGHTS);
sig_rule_B_18534733 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_M)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_SBSFLIGHTS);
sig_rule_B_18534732 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_K)
                        and sig_ram_opair(C_LBL_OPAIR_2X)
                        and sig_ram_flgrp(C_LBL_FG_SBSFLIGHTS);
sig_rule_B_18534731 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_H)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_SBSFLIGHTS);
sig_rule_B_18534730 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_B)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_SBSFLIGHTS);
sig_rule_B_18534729 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_Y)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_SBSFLIGHTS);
sig_rule_B_18534716 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_P)
                        and sig_ram_bkg(C_LBL_BKG_P)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_101211100);
sig_rule_B_18534712 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_W)
                        and sig_ram_bkg(C_LBL_BKG_W)
                        and sig_ram_opair(C_LBL_OPAIR_2X)
                        and sig_ram_flgrp(C_LBL_FG_101211099);
sig_rule_B_18534706 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_F)
                        and sig_ram_bkg(C_LBL_BKG_F)
                        and sig_ram_opair(C_LBL_OPAIR_2X)
                        and sig_ram_flgrp(C_LBL_FG_101211097);
sig_rule_B_18534688 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_F)
                        and sig_ram_bkg(C_LBL_BKG_Z)
                        and sig_ram_opair(C_LBL_OPAIR_8X)
                        and sig_ram_flgrp(C_LBL_FG_ALL2X);
sig_rule_B_18534687 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_F)
                        and sig_ram_bkg(C_LBL_BKG_P)
                        and sig_ram_opair(C_LBL_OPAIR_8X)
                        and sig_ram_flgrp(C_LBL_FG_ALL2X);
sig_rule_B_18534686 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_F)
                        and sig_ram_bkg(C_LBL_BKG_F)
                        and sig_ram_opair(C_LBL_OPAIR_8X)
                        and sig_ram_flgrp(C_LBL_FG_ALL2X);
sig_rule_B_18534685 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_F)
                        and sig_ram_bkg(C_LBL_BKG_A)
                        and sig_ram_opair(C_LBL_OPAIR_8X)
                        and sig_ram_flgrp(C_LBL_FG_ALL2X);
sig_rule_B_18534684 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_C)
                        and sig_ram_bkg(C_LBL_BKG_U)
                        and sig_ram_opair(C_LBL_OPAIR_8X)
                        and sig_ram_flgrp(C_LBL_FG_ALL2X);
sig_rule_B_18534683 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_C)
                        and sig_ram_bkg(C_LBL_BKG_J)
                        and sig_ram_opair(C_LBL_OPAIR_8X)
                        and sig_ram_flgrp(C_LBL_FG_ALL2X);
sig_rule_B_18534682 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_C)
                        and sig_ram_bkg(C_LBL_BKG_I)
                        and sig_ram_opair(C_LBL_OPAIR_8X)
                        and sig_ram_flgrp(C_LBL_FG_ALL2X);
sig_rule_B_18534681 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_C)
                        and sig_ram_bkg(C_LBL_BKG_D)
                        and sig_ram_opair(C_LBL_OPAIR_8X)
                        and sig_ram_flgrp(C_LBL_FG_ALL2X);
sig_rule_B_18534680 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_C)
                        and sig_ram_bkg(C_LBL_BKG_C)
                        and sig_ram_opair(C_LBL_OPAIR_8X)
                        and sig_ram_flgrp(C_LBL_FG_ALL2X);
sig_rule_B_18534679 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_C)
                        and sig_ram_bkg(C_LBL_BKG_U)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_ALL2X);
sig_rule_B_18534678 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_C)
                        and sig_ram_bkg(C_LBL_BKG_J)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_ALL2X);
sig_rule_B_18534677 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_C)
                        and sig_ram_bkg(C_LBL_BKG_I)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_ALL2X);
sig_rule_B_18534676 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_C)
                        and sig_ram_bkg(C_LBL_BKG_D)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_ALL2X);
sig_rule_B_18534675 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_C)
                        and sig_ram_bkg(C_LBL_BKG_C)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_ALL2X);
sig_rule_B_18534673 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_J)
                        and sig_ram_bkg(C_LBL_BKG_J)
                        and sig_ram_opair(C_LBL_OPAIR_2X)
                        and sig_ram_flgrp(C_LBL_FG_101211093);
sig_rule_B_18534667 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_J)
                        and sig_ram_bkg(C_LBL_BKG_C)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_ALL2X);
sig_rule_B_18534666 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_F)
                        and sig_ram_bkg(C_LBL_BKG_Z)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_ALL2X);
sig_rule_B_18534665 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_J)
                        and sig_ram_bkg(C_LBL_BKG_I)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_ALL2X);
sig_rule_B_18534664 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_J)
                        and sig_ram_bkg(C_LBL_BKG_U)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_ALL2X);
sig_rule_B_18534663 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_J)
                        and sig_ram_bkg(C_LBL_BKG_J)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_ALL2X);
sig_rule_B_18534662 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_J)
                        and sig_ram_bkg(C_LBL_BKG_D)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_ALL2X);
sig_rule_B_18534658 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_F)
                        and sig_ram_bkg(C_LBL_BKG_P)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_ALL2X);
sig_rule_B_18534657 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_F)
                        and sig_ram_bkg(C_LBL_BKG_F)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_ALL2X);
sig_rule_B_18534656 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_F)
                        and sig_ram_bkg(C_LBL_BKG_A)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_ALL2X);
sig_rule_B_18534652 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_E)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_PRODSLAALLFLTS);
sig_rule_B_18534651 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_X)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_PRODSLAALLFLTS);
sig_rule_B_18534650 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_G)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_PRODSLAALLFLTS);
sig_rule_B_18534649 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_Q)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_PRODSLAALLFLTS);
sig_rule_B_18534648 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_O)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_PRODSLAALLFLTS);
sig_rule_B_18534647 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_N)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_PRODSLAALLFLTS);
sig_rule_B_18534646 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_V)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_PRODSLAALLFLTS);
sig_rule_B_18534645 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_S)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_PRODSLAALLFLTS);
sig_rule_B_18534644 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_L)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_PRODSLAALLFLTS);
sig_rule_B_18534643 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_M)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_PRODSLAALLFLTS);
sig_rule_B_18534642 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_K)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_PRODSLAALLFLTS);
sig_rule_B_18534641 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_H)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_PRODSLAALLFLTS);
sig_rule_B_18534640 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_Y)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_PRODSLAALLFLTS);
sig_rule_B_18534639 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_B)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_PRODSLAALLFLTS);
sig_rule_B_18534638 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_J)
                        and sig_ram_bkg(C_LBL_BKG_I)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_PRODSLAALLFLTS);
sig_rule_B_18534637 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_J)
                        and sig_ram_bkg(C_LBL_BKG_D)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_PRODSLAALLFLTS);
sig_rule_B_18534636 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_J)
                        and sig_ram_bkg(C_LBL_BKG_C)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_PRODSLAALLFLTS);
sig_rule_B_18534635 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_J)
                        and sig_ram_bkg(C_LBL_BKG_J)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_PRODSLAALLFLTS);
sig_rule_B_18534634 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_J)
                        and sig_ram_bkg(C_LBL_BKG_U)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_PRODSLAALLFLTS);
sig_rule_B_18534633 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_F)
                        and sig_ram_bkg(C_LBL_BKG_Z)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_PRODSLAALLFLTS);
sig_rule_B_18534632 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_F)
                        and sig_ram_bkg(C_LBL_BKG_P)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_PRODSLAALLFLTS);
sig_rule_B_18534631 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_F)
                        and sig_ram_bkg(C_LBL_BKG_A)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_PRODSLAALLFLTS);
sig_rule_B_18534630 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_F)
                        and sig_ram_bkg(C_LBL_BKG_F)
                        and sig_ram_opair(C_LBL_OPAIR_ALL)
                        and sig_ram_flgrp(C_LBL_FG_PRODSLAALLFLTS);
sig_rule_B_18534702 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_Y)
                        and sig_ram_opair(C_LBL_OPAIR_8X);
sig_rule_B_18534701 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_X)
                        and sig_ram_opair(C_LBL_OPAIR_8X);
sig_rule_B_18534700 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_V)
                        and sig_ram_opair(C_LBL_OPAIR_8X);
sig_rule_B_18534699 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_S)
                        and sig_ram_opair(C_LBL_OPAIR_8X);
sig_rule_B_18534698 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_R)
                        and sig_ram_opair(C_LBL_OPAIR_8X);
sig_rule_B_18534697 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_Q)
                        and sig_ram_opair(C_LBL_OPAIR_8X);
sig_rule_B_18534696 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_O)
                        and sig_ram_opair(C_LBL_OPAIR_8X);
sig_rule_B_18534695 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_N)
                        and sig_ram_opair(C_LBL_OPAIR_8X);
sig_rule_B_18534694 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_M)
                        and sig_ram_opair(C_LBL_OPAIR_8X);
sig_rule_B_18534693 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_L)
                        and sig_ram_opair(C_LBL_OPAIR_8X);
sig_rule_B_18534692 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_K)
                        and sig_ram_opair(C_LBL_OPAIR_8X);
sig_rule_B_18534691 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_H)
                        and sig_ram_opair(C_LBL_OPAIR_8X);
sig_rule_B_18534690 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_G)
                        and sig_ram_opair(C_LBL_OPAIR_8X);
sig_rule_B_18534689 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_E)
                        and sig_ram_opair(C_LBL_OPAIR_8X);
sig_rule_B_18534621 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_E)
                        and sig_ram_opair(C_LBL_OPAIR_ALL);
sig_rule_B_18534620 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_X)
                        and sig_ram_opair(C_LBL_OPAIR_ALL);
sig_rule_B_18534619 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_T)
                        and sig_ram_opair(C_LBL_OPAIR_ALL);
sig_rule_B_18534618 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_R)
                        and sig_ram_opair(C_LBL_OPAIR_ALL);
sig_rule_B_18534617 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_G)
                        and sig_ram_opair(C_LBL_OPAIR_ALL);
sig_rule_B_18534616 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_S)
                        and sig_ram_opair(C_LBL_OPAIR_ALL);
sig_rule_B_18534615 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_Q)
                        and sig_ram_opair(C_LBL_OPAIR_ALL);
sig_rule_B_18534614 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_O)
                        and sig_ram_opair(C_LBL_OPAIR_ALL);
sig_rule_B_18534613 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_N)
                        and sig_ram_opair(C_LBL_OPAIR_ALL);
sig_rule_B_18534612 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_V)
                        and sig_ram_opair(C_LBL_OPAIR_ALL);
sig_rule_B_18534611 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_W)
                        and sig_ram_opair(C_LBL_OPAIR_ALL);
sig_rule_B_18534610 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_L)
                        and sig_ram_opair(C_LBL_OPAIR_ALL);
sig_rule_B_18534609 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_M)
                        and sig_ram_opair(C_LBL_OPAIR_ALL);
sig_rule_B_18534608 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_K)
                        and sig_ram_opair(C_LBL_OPAIR_ALL);
sig_rule_B_18534607 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_H)
                        and sig_ram_opair(C_LBL_OPAIR_ALL);
sig_rule_B_18534606 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_B)
                        and sig_ram_opair(C_LBL_OPAIR_ALL);
sig_rule_B_18534605 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_Y)
                        and sig_ram_bkg(C_LBL_BKG_Y)
                        and sig_ram_opair(C_LBL_OPAIR_ALL);
sig_rule_B_18534604 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_J)
                        and sig_ram_bkg(C_LBL_BKG_U)
                        and sig_ram_opair(C_LBL_OPAIR_ALL);
sig_rule_B_18534603 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_J)
                        and sig_ram_bkg(C_LBL_BKG_I)
                        and sig_ram_opair(C_LBL_OPAIR_ALL);
sig_rule_B_18534602 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_J)
                        and sig_ram_bkg(C_LBL_BKG_D)
                        and sig_ram_opair(C_LBL_OPAIR_ALL);
sig_rule_B_18534601 <= sig_fnc_ruleBr
                        and (sig_ram_mrktA(C_LBL_MKT_WORLD) and sig_ram_mrktB(C_LBL_MKT_WORLD))
                        and sig_ram_cabin(C_LBL_CAB_J)
                        and sig_ram_bkg(C_LBL_BKG_J)
                        and sig_ram_opair(C_LBL_OPAIR_ALL);

process(clk_i, rst_i)
begin
    if rst_i = '1' then
        result_o <= (others => '0');
        sig_fnc_ruleAr <= '0';
        sig_fnc_ruleBr <= '0';
        sig_fnc_04MAY200701JAN9999r <= '0';
        sig_fnc_15MAY200801JAN9999r <= '0';
        sig_fnc_07JUL200901JAN9999r <= '0';
        sig_fnc_08JUL200901JAN9999r <= '0';
        sig_fnc_18APR201501JAN9999r <= '0';
    elsif rising_edge(clk_i) then

        sig_fnc_ruleAr <= sig_fnc_ruleA;
        sig_fnc_ruleBr <= sig_fnc_ruleB;
        sig_fnc_04MAY200701JAN9999r <= sig_fnc_04MAY200701JAN9999;
        sig_fnc_15MAY200801JAN9999r <= sig_fnc_15MAY200801JAN9999;
        sig_fnc_07JUL200901JAN9999r <= sig_fnc_07JUL200901JAN9999;
        sig_fnc_08JUL200901JAN9999r <= sig_fnc_08JUL200901JAN9999;
        sig_fnc_18APR201501JAN9999r <= sig_fnc_18APR201501JAN9999;

    result_o <= 
          sig_rule_A_342890310
        & sig_rule_A_326857829
        & sig_rule_A_326857828
        & sig_rule_A_326857827
        & sig_rule_A_326857826
        & sig_rule_A_326857825
        & sig_rule_A_326857816
        & sig_rule_A_342890305
        & sig_rule_A_342890303
        & sig_rule_A_342877956
        & sig_rule_A_337625101
        & sig_rule_A_337625100
        & sig_rule_A_337625099
        & sig_rule_A_337625098
        & sig_rule_A_337625095
        & sig_rule_A_337625092
        & sig_rule_A_337625061
        & sig_rule_A_337625060
        & sig_rule_A_326857831
        & sig_rule_A_326857830
        & sig_rule_A_326857824
        & sig_rule_A_326857823
        & sig_rule_A_326857822
        & sig_rule_A_326857821
        & sig_rule_A_326857820
        & sig_rule_A_326857819
        & sig_rule_A_326857818
        & sig_rule_A_326857817
        & sig_rule_B_18534707
        & sig_rule_B_47209736
        & sig_rule_B_47209735
        & sig_rule_B_47209734
        & sig_rule_B_18534770
        & sig_rule_B_18534769
        & sig_rule_B_18534768
        & sig_rule_B_18534766
        & sig_rule_B_18534765
        & sig_rule_B_18534764
        & sig_rule_B_18534763
        & sig_rule_B_18534762
        & sig_rule_B_18534761
        & sig_rule_B_18534760
        & sig_rule_B_18534759
        & sig_rule_B_18534758
        & sig_rule_B_18534757
        & sig_rule_B_18534756
        & sig_rule_B_18534755
        & sig_rule_B_18534754
        & sig_rule_B_18534753
        & sig_rule_B_18534752
        & sig_rule_B_18534751
        & sig_rule_B_18534750
        & sig_rule_B_18534749
        & sig_rule_B_18534748
        & sig_rule_B_18534747
        & sig_rule_B_18534746
        & sig_rule_B_18534745
        & sig_rule_B_18534744
        & sig_rule_B_18534743
        & sig_rule_B_18534742
        & sig_rule_B_18534741
        & sig_rule_B_18534740
        & sig_rule_B_18534739
        & sig_rule_B_18534738
        & sig_rule_B_18534737
        & sig_rule_B_18534736
        & sig_rule_B_18534735
        & sig_rule_B_18534734
        & sig_rule_B_18534733
        & sig_rule_B_18534732
        & sig_rule_B_18534731
        & sig_rule_B_18534730
        & sig_rule_B_18534729
        & sig_rule_B_18534716
        & sig_rule_B_18534712
        & sig_rule_B_18534706
        & sig_rule_B_18534688
        & sig_rule_B_18534687
        & sig_rule_B_18534686
        & sig_rule_B_18534685
        & sig_rule_B_18534684
        & sig_rule_B_18534683
        & sig_rule_B_18534682
        & sig_rule_B_18534681
        & sig_rule_B_18534680
        & sig_rule_B_18534679
        & sig_rule_B_18534678
        & sig_rule_B_18534677
        & sig_rule_B_18534676
        & sig_rule_B_18534675
        & sig_rule_B_18534673
        & sig_rule_B_18534667
        & sig_rule_B_18534666
        & sig_rule_B_18534665
        & sig_rule_B_18534664
        & sig_rule_B_18534663
        & sig_rule_B_18534662
        & sig_rule_B_18534658
        & sig_rule_B_18534657
        & sig_rule_B_18534656
        & sig_rule_B_18534652
        & sig_rule_B_18534651
        & sig_rule_B_18534650
        & sig_rule_B_18534649
        & sig_rule_B_18534648
        & sig_rule_B_18534647
        & sig_rule_B_18534646
        & sig_rule_B_18534645
        & sig_rule_B_18534644
        & sig_rule_B_18534643
        & sig_rule_B_18534642
        & sig_rule_B_18534641
        & sig_rule_B_18534640
        & sig_rule_B_18534639
        & sig_rule_B_18534638
        & sig_rule_B_18534637
        & sig_rule_B_18534636
        & sig_rule_B_18534635
        & sig_rule_B_18534634
        & sig_rule_B_18534633
        & sig_rule_B_18534632
        & sig_rule_B_18534631
        & sig_rule_B_18534630
        & sig_rule_B_18534702
        & sig_rule_B_18534701
        & sig_rule_B_18534700
        & sig_rule_B_18534699
        & sig_rule_B_18534698
        & sig_rule_B_18534697
        & sig_rule_B_18534696
        & sig_rule_B_18534695
        & sig_rule_B_18534694
        & sig_rule_B_18534693
        & sig_rule_B_18534692
        & sig_rule_B_18534691
        & sig_rule_B_18534690
        & sig_rule_B_18534689
        & sig_rule_B_18534621
        & sig_rule_B_18534620
        & sig_rule_B_18534619
        & sig_rule_B_18534618
        & sig_rule_B_18534617
        & sig_rule_B_18534616
        & sig_rule_B_18534615
        & sig_rule_B_18534614
        & sig_rule_B_18534613
        & sig_rule_B_18534612
        & sig_rule_B_18534611
        & sig_rule_B_18534610
        & sig_rule_B_18534609
        & sig_rule_B_18534608
        & sig_rule_B_18534607
        & sig_rule_B_18534606
        & sig_rule_B_18534605
        & sig_rule_B_18534604
        & sig_rule_B_18534603
        & sig_rule_B_18534602
        & sig_rule_B_18534601;
    end if;
end process;

end architecture behavioural;



    --signal sig_fnc_ACR0 : std_logic;
    --signal sig_fnc_AFS0 : std_logic;
    --signal sig_fnc_AGG0 : std_logic;
    --signal sig_fnc_APR0 : std_logic;
    --signal sig_fnc_APR1 : std_logic;
    --signal sig_fnc_ARC0 : std_logic;
    --signal sig_fnc_ASR0 : std_logic;
    --signal sig_fnc_ASR1 : std_logic;
    --signal sig_fnc_BCR2 : std_logic;
    --signal sig_fnc_CCM0 : std_logic;
    --signal sig_fnc_CMT0 : std_logic;
    --signal sig_fnc_EFT0 : std_logic;
    --signal sig_fnc_ETR0 : std_logic;
    --signal sig_fnc_FCM0 : std_logic;
    --signal sig_fnc_FCM2 : std_logic;
    --signal sig_fnc_FRS0 : std_logic;
    --signal sig_fnc_FSR0 : std_logic;
    --signal sig_fnc_GHA0 : std_logic;
    --signal sig_fnc_IDC0 : std_logic;
    --signal sig_fnc_INT0 : std_logic;
    --signal sig_fnc_MCO1 : std_logic;
    --signal sig_fnc_MIC0 : std_logic;
    --signal sig_fnc_MIL0 : std_logic;
    --signal sig_fnc_NSR1 : std_logic;
    --signal sig_fnc_NSR2 : std_logic;
    --signal sig_fnc_OCC0 : std_logic;
    --signal sig_fnc_OCC1 : std_logic;
    --signal sig_fnc_OCC2 : std_logic;
    --signal sig_fnc_ODC0 : std_logic;
    --signal sig_fnc_ODP0 : std_logic;
    --signal sig_fnc_OED0 : std_logic;
    --signal sig_fnc_OFD0 : std_logic;
    --signal sig_fnc_PAL0 : std_logic;
    --signal sig_fnc_PDR0 : std_logic;
    --signal sig_fnc_RCR0 : std_logic;
    --signal sig_fnc_SCD0 : std_logic;
    --signal sig_fnc_SLR0 : std_logic;
    --signal sig_fnc_SPR0 : std_logic;
    --signal sig_fnc_STP0 : std_logic;
    --signal sig_fnc_STS0 : std_logic;
    --signal sig_fnc_TIF0 : std_logic;
    --signal sig_fnc_TIL0 : std_logic;
    --signal sig_fnc_TNR0 : std_logic;
    --signal sig_fnc_TPL0 : std_logic;
    --signal sig_fnc_YCR0 : std_logic;

    ---- not in use
    ---- code="ACV"
    ---- code="DURA_PAIR"
    ---- code="DAYS"
    ---- code="POS_NAME"
    ---- code="POS_MKT"
    ---- code="FG2" ONLY ONE RULE and same value as fg1??? weird test
    ---- code="SALECFG"
    ---- code="SEASON"
    ---- code="S_ENUM2"
    ---- code="TIME_PAIR"

    ---- implemented
    --code="BKG"
    --code="CABIN"
    --code="S_OPAIR"
    
    ---- to be implemented
    --code="CSH" -- one value accepted, just directed from encoding ie. query_i(3)()
    --code="EQP"
    --code="FG1"
    --code="MKT1"
    --code="MKT_PAIR"
    --code="STR1"
    --code="S_SYST"
    --code="S_STR1"
    --code="TIA"

    --code="DATE_PAIR"

    --signal sig_fnc_ACR00   : std_logic;
    --signal sig_fnc_ACR00_r : std_logic;
    --signal sig_fnc_AFS00   : std_logic;
    --signal sig_fnc_AFS00_r : std_logic;
    --signal sig_fnc_AGG00   : std_logic;
    --signal sig_fnc_AGG00_r : std_logic;
    --signal sig_fnc_APR00   : std_logic;
    --signal sig_fnc_APR00_r : std_logic;
    --signal sig_fnc_APR11   : std_logic;
    --signal sig_fnc_APR11_r : std_logic;
    --signal sig_fnc_ARC00   : std_logic;
    --signal sig_fnc_ARC00_r : std_logic;
    --signal sig_fnc_ASR00   : std_logic;
    --signal sig_fnc_ASR00_r : std_logic;
    --signal sig_fnc_ASR11   : std_logic;
    --signal sig_fnc_ASR11_r : std_logic;
    --signal sig_fnc_BCR22   : std_logic;
    --signal sig_fnc_BCR22_r : std_logic;
    --signal sig_fnc_CCM00   : std_logic;
    --signal sig_fnc_CCM00_r : std_logic;
    --signal sig_fnc_CMT00   : std_logic;
    --signal sig_fnc_CMT00_r : std_logic;
    --signal sig_fnc_EFT00   : std_logic;
    --signal sig_fnc_EFT00_r : std_logic;
    --signal sig_fnc_ETR00   : std_logic;
    --signal sig_fnc_ETR00_r : std_logic;
    --signal sig_fnc_FCM00   : std_logic;
    --signal sig_fnc_FCM00_r : std_logic;
    --signal sig_fnc_FCM22   : std_logic;
    --signal sig_fnc_FCM22_r : std_logic;
    --signal sig_fnc_FRS00   : std_logic;
    --signal sig_fnc_FRS00_r : std_logic;
    --signal sig_fnc_FSR00   : std_logic;
    --signal sig_fnc_FSR00_r : std_logic;
    --signal sig_fnc_GHA00   : std_logic;
    --signal sig_fnc_GHA00_r : std_logic;
    --signal sig_fnc_IDC00   : std_logic;
    --signal sig_fnc_IDC00_r : std_logic;
    --signal sig_fnc_INT00   : std_logic;
    --signal sig_fnc_INT00_r : std_logic;
    --signal sig_fnc_MCO11   : std_logic;
    --signal sig_fnc_MCO11_r : std_logic;
    --signal sig_fnc_MIC00   : std_logic;
    --signal sig_fnc_MIC00_r : std_logic;
    --signal sig_fnc_MIL00   : std_logic;
    --signal sig_fnc_MIL00_r : std_logic;
    --signal sig_fnc_NSR11   : std_logic;
    --signal sig_fnc_NSR11_r : std_logic;
    --signal sig_fnc_NSR22   : std_logic;
    --signal sig_fnc_NSR22_r : std_logic;
    --signal sig_fnc_OCC00   : std_logic;
    --signal sig_fnc_OCC00_r : std_logic;
    --signal sig_fnc_OCC11   : std_logic;
    --signal sig_fnc_OCC11_r : std_logic;
    --signal sig_fnc_OCC22   : std_logic;
    --signal sig_fnc_OCC22_r : std_logic;
    --signal sig_fnc_ODC00   : std_logic;
    --signal sig_fnc_ODC00_r : std_logic;
    --signal sig_fnc_ODP00   : std_logic;
    --signal sig_fnc_ODP00_r : std_logic;
    --signal sig_fnc_OED00   : std_logic;
    --signal sig_fnc_OED00_r : std_logic;
    --signal sig_fnc_OFD00   : std_logic;
    --signal sig_fnc_OFD00_r : std_logic;
    --signal sig_fnc_PAL00   : std_logic;
    --signal sig_fnc_PAL00_r : std_logic;
    --signal sig_fnc_PDR00   : std_logic;
    --signal sig_fnc_PDR00_r : std_logic;
    --signal sig_fnc_RCR00   : std_logic;
    --signal sig_fnc_RCR00_r : std_logic;
    --signal sig_fnc_SCD00   : std_logic;
    --signal sig_fnc_SCD00_r : std_logic;
    --signal sig_fnc_SLR00   : std_logic;
    --signal sig_fnc_SLR00_r : std_logic;
    --signal sig_fnc_SPR00   : std_logic;
    --signal sig_fnc_SPR00_r : std_logic;
    --signal sig_fnc_STP00   : std_logic;
    --signal sig_fnc_STP00_r : std_logic;
    --signal sig_fnc_STS00   : std_logic;
    --signal sig_fnc_STS00_r : std_logic;
    --signal sig_fnc_TIF00   : std_logic;
    --signal sig_fnc_TIF00_r : std_logic;
    --signal sig_fnc_TIL00   : std_logic;
    --signal sig_fnc_TIL00_r : std_logic;
    --signal sig_fnc_TNR00   : std_logic;
    --signal sig_fnc_TNR00_r : std_logic;
    --signal sig_fnc_TPL00   : std_logic;
    --signal sig_fnc_TPL00_r : std_logic;
    --signal sig_fnc_YCR00   : std_logic;
    --signal sig_fnc_YCR00_r : std_logic;