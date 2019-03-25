----------------------------------------------------------------------------------
-- Institution: Systems Group, ETH Zurich 
-- PhD Researcher: Fabio Maschi
-- 
-- Create Date: 20.02.2019 15:34:34
-- Design Name: 
-- Module Name: top - behavioural
-- Project Name: ABR
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;

library abr;
use abr.pkg_abr.all;

entity top is
    Port (
        clk_i    :  in std_logic;
        rst_i    :  in std_logic;
        query_i  :  in query_in_array_type(6 downto 0);
        result_o : out std_logic_vector(18 downto 0)
    );
end top;

architecture behavioural of top is
    type sig_stage is record
        cmb     : std_logic; -- output of AND (match and s-1 seq)
        match   : std_logic; -- output of MATCHER
        seq     : std_logic; -- output of the register
    end record;

    --
    constant C_DT_01jan09   : std_logic_vector(7 downto 0) := "00000000";
    constant C_DT_08jul09   : std_logic_vector(7 downto 0) := "00000001";
    constant C_DT_07jul09   : std_logic_vector(7 downto 0) := "00000010";
    constant C_DT_15may08   : std_logic_vector(7 downto 0) := "00000011";
    constant C_DT_18apr15   : std_logic_vector(7 downto 0) := "00000100";
    --
    signal sig_r0      : sig_stage; -- 2231,2X
    signal sig_r0l0    : sig_stage; -- world2world
    signal sig_r0l1    : sig_stage; -- osl2ewr
    signal sig_r0l2    : sig_stage; -- ewr2cph
    signal sig_r0l3    : sig_stage; -- cph2ewr
    --
    signal sig_r0l00   : sig_stage; -- 01jan09,08jul09
    signal sig_r0l01   : sig_stage; -- 01jan09,07jul09
    signal sig_r0l02   : sig_stage; -- 01jan09,15may08
    signal sig_r0l03   : sig_stage; -- 01jan09,18apr15
    signal sig_r0l04   : sig_stage; -- any,any
    signal sig_r0l10   : sig_stage; -- any,any
    signal sig_r0l20   : sig_stage; -- any,any
    signal sig_r0l30   : sig_stage; -- any,any
    --
    signal sig_r0l000   : sig_stage; -- M
    signal sig_r0l010   : sig_stage; -- J
    signal sig_r0l011   : sig_stage; -- Y
    signal sig_r0l020   : sig_stage; -- J
    signal sig_r0l021   : sig_stage; -- Y
    signal sig_r0l030   : sig_stage; -- Y
    signal sig_r0l040   : sig_stage; -- C
    signal sig_r0l041   : sig_stage; -- J
    signal sig_r0l042   : sig_stage; -- M
    signal sig_r0l043   : sig_stage; -- Y
    signal sig_r0l100   : sig_stage; -- C
    signal sig_r0l101   : sig_stage; -- M
    signal sig_r0l102   : sig_stage; -- Y
    signal sig_r0l200   : sig_stage; -- C
    signal sig_r0l201   : sig_stage; -- M
    signal sig_r0l202   : sig_stage; -- Y
    signal sig_r0l300   : sig_stage; -- C
    signal sig_r0l301   : sig_stage; -- M
    signal sig_r0l302   : sig_stage; -- Y
    --
begin

--query_i(0) <= "10101010";
--query_i(1) <= C_SOPAIR_2X;
--query_i(2) <= C_MKT_WORLD;
--query_i(3) <= C_MKT_WORLD;
--query_i(4) <= C_DT_01jan09;
--query_i(5) <= C_DT_07jul09;
--query_i(6) <= C_CABIN_Y;

r0: matcher generic map -- rule,organisation
(
    G_STRUCTURE         => C_STRCT_PAIR,
    G_VALUE_A           => "10101010",
    G_VALUE_B           => C_SOPAIR_2X,
    G_FUNCTION_A        => C_FNCTR_SIMP_SEQ,
    G_FUNCTION_B        => C_FNCTR_SIMP_SEQ,
    G_FUNCTION_PAIR     => C_FNCTR_PAIR_PAN
)
port map
(
    query_opA_i         => query_i(0),
    query_opB_i         => query_i(1),
    match_result_o      => sig_r0.match
);

r0_l0: matcher generic map -- world2world
(
    G_STRUCTURE         => C_STRCT_PAIR,
    G_VALUE_A           => C_MKT_WORLD,
    G_VALUE_B           => C_MKT_WORLD,
    G_FUNCTION_A        => C_FNCTR_SIMP_MME,
    G_FUNCTION_B        => C_FNCTR_SIMP_MME,
    G_FUNCTION_PAIR     => C_FNCTR_PAIR_PMA
)
port map
(
    query_opA_i         => query_i(2),
    query_opB_i         => query_i(3),
    match_result_o      => sig_r0l0.match
);
sig_r0l0.cmb <= sig_r0l0.match and sig_r0.seq;

r0_l1: matcher generic map -- osl2ewr
(
    G_STRUCTURE         => C_STRCT_PAIR,
    G_VALUE_A           => C_MKT_OSL,
    G_VALUE_B           => C_MKT_EWR,
    G_FUNCTION_A        => C_FNCTR_SIMP_MME,
    G_FUNCTION_B        => C_FNCTR_SIMP_MME,
    G_FUNCTION_PAIR     => C_FNCTR_PAIR_PMA
)
port map
(
    query_opA_i         => query_i(2),
    query_opB_i         => query_i(3),
    match_result_o      => sig_r0l1.match
);
sig_r0l1.cmb <= sig_r0l1.match and sig_r0.seq;

r0_l2: matcher generic map -- ewr2cph
(
    G_STRUCTURE         => C_STRCT_PAIR,
    G_VALUE_A           => C_MKT_EWR,
    G_VALUE_B           => C_MKT_CPH,
    G_FUNCTION_A        => C_FNCTR_SIMP_MME,
    G_FUNCTION_B        => C_FNCTR_SIMP_MME,
    G_FUNCTION_PAIR     => C_FNCTR_PAIR_PMA
)
port map
(
    query_opA_i         => query_i(2),
    query_opB_i         => query_i(3),
    match_result_o      => sig_r0l2.match
);
sig_r0l2.cmb <= sig_r0l2.match and sig_r0.seq;

r0_l3: matcher generic map -- cph2ewr
(
    G_STRUCTURE         => C_STRCT_PAIR,
    G_VALUE_A           => C_MKT_CPH,
    G_VALUE_B           => C_MKT_EWR,
    G_FUNCTION_A        => C_FNCTR_SIMP_MME,
    G_FUNCTION_B        => C_FNCTR_SIMP_MME,
    G_FUNCTION_PAIR     => C_FNCTR_PAIR_PMA
)
port map
(
    query_opA_i         => query_i(2),
    query_opB_i         => query_i(3),
    match_result_o      => sig_r0l3.match
);
sig_r0l3.cmb <= sig_r0l3.match and sig_r0.seq;


r0_l00: matcher generic map -- 01jan09,08jul09
(
    G_STRUCTURE         => C_STRCT_PAIR,
    G_VALUE_A           => C_DT_01jan09,
    G_VALUE_B           => C_DT_08jul09,
    G_FUNCTION_A        => C_FNCTR_SIMP_DSE,
    G_FUNCTION_B        => C_FNCTR_SIMP_DIE,
    G_FUNCTION_PAIR     => C_FNCTR_PAIR_PCA
)
port map
(
    query_opA_i         => query_i(4),
    query_opB_i         => query_i(5),
    match_result_o      => sig_r0l00.match
);
sig_r0l00.cmb <= sig_r0l00.match and sig_r0l0.seq;

r0_l01: matcher generic map -- 01jan09,07jul09
(
    G_STRUCTURE         => C_STRCT_PAIR,
    G_VALUE_A           => C_DT_01jan09,
    G_VALUE_B           => C_DT_07jul09,
    G_FUNCTION_A        => C_FNCTR_SIMP_DSE,
    G_FUNCTION_B        => C_FNCTR_SIMP_DIE,
    G_FUNCTION_PAIR     => C_FNCTR_PAIR_PCA
)
port map
(
    query_opA_i         => query_i(4),
    query_opB_i         => query_i(5),
    match_result_o      => sig_r0l01.match
);
sig_r0l01.cmb <= sig_r0l01.match and sig_r0l0.seq;

r0_l02: matcher generic map -- 01jan09,15may08
(
    G_STRUCTURE         => C_STRCT_PAIR,
    G_VALUE_A           => C_DT_01jan09,
    G_VALUE_B           => C_DT_15may08,
    G_FUNCTION_A        => C_FNCTR_SIMP_DSE,
    G_FUNCTION_B        => C_FNCTR_SIMP_DIE,
    G_FUNCTION_PAIR     => C_FNCTR_PAIR_PCA
)
port map
(
    query_opA_i         => query_i(4),
    query_opB_i         => query_i(5),
    match_result_o      => sig_r0l02.match
);
sig_r0l02.cmb <= sig_r0l02.match and sig_r0l0.seq;

r0_l03: matcher generic map -- 01jan09,18apr15
(
    G_STRUCTURE         => C_STRCT_PAIR,
    G_VALUE_A           => C_DT_01jan09,
    G_VALUE_B           => C_DT_18apr15,
    G_FUNCTION_A        => C_FNCTR_SIMP_DSE,
    G_FUNCTION_B        => C_FNCTR_SIMP_DIE,
    G_FUNCTION_PAIR     => C_FNCTR_PAIR_PCA
)
port map
(
    query_opA_i         => query_i(4),
    query_opB_i         => query_i(5),
    match_result_o      => sig_r0l03.match
);
sig_r0l03.cmb <= sig_r0l03.match and sig_r0l0.seq;

sig_r0l04.cmb <= sig_r0l0.seq;

sig_r0l10.cmb <= sig_r0l1.seq;

sig_r0l20.cmb <= sig_r0l2.seq;

sig_r0l30.cmb <= sig_r0l3.seq;


r0_l000: matcher generic map -- M
(
    G_STRUCTURE         => C_STRCT_SIMPLE,
    G_VALUE_A           => C_CABIN_M,
    G_FUNCTION_A        => C_FNCTR_SIMP_SEQ
)
port map
(
    query_opA_i         => query_i(6),
    match_result_o      => sig_r0l000.match
);
sig_r0l000.cmb <= sig_r0l000.match and sig_r0l00.seq;

r0_l010: matcher generic map -- J
(
    G_STRUCTURE         => C_STRCT_SIMPLE,
    G_VALUE_A           => C_CABIN_J,
    G_FUNCTION_A        => C_FNCTR_SIMP_SEQ
)
port map
(
    query_opA_i         => query_i(6),
    match_result_o      => sig_r0l010.match
);
sig_r0l010.cmb <= sig_r0l010.match and sig_r0l01.seq;

r0_l011: matcher generic map -- Y
(
    G_STRUCTURE         => C_STRCT_SIMPLE,
    G_VALUE_A           => C_CABIN_Y,
    G_FUNCTION_A        => C_FNCTR_SIMP_SEQ
)
port map
(
    query_opA_i         => query_i(6),
    match_result_o      => sig_r0l011.match
);
sig_r0l011.cmb <= sig_r0l011.match and sig_r0l01.seq;

r0_l020: matcher generic map -- J
(
    G_STRUCTURE         => C_STRCT_SIMPLE,
    G_VALUE_A           => C_CABIN_J,
    G_FUNCTION_A        => C_FNCTR_SIMP_SEQ
)
port map
(
    query_opA_i         => query_i(6),
    match_result_o      => sig_r0l020.match
);
sig_r0l020.cmb <= sig_r0l020.match and sig_r0l02.seq;

r0_l021: matcher generic map -- Y
(
    G_STRUCTURE         => C_STRCT_SIMPLE,
    G_VALUE_A           => C_CABIN_Y,
    G_FUNCTION_A        => C_FNCTR_SIMP_SEQ
)
port map
(
    query_opA_i         => query_i(6),
    match_result_o      => sig_r0l021.match
);
sig_r0l021.cmb <= sig_r0l021.match and sig_r0l02.seq;

r0_l030: matcher generic map -- Y
(
    G_STRUCTURE         => C_STRCT_SIMPLE,
    G_VALUE_A           => C_CABIN_Y,
    G_FUNCTION_A        => C_FNCTR_SIMP_SEQ
)
port map
(
    query_opA_i         => query_i(6),
    match_result_o      => sig_r0l030.match
);
sig_r0l030.cmb <= sig_r0l030.match and sig_r0l03.seq;

r0_l040: matcher generic map -- C
(
    G_STRUCTURE         => C_STRCT_SIMPLE,
    G_VALUE_A           => C_CABIN_C,
    G_FUNCTION_A        => C_FNCTR_SIMP_SEQ
)
port map
(
    query_opA_i         => query_i(6),
    match_result_o      => sig_r0l040.match
);
sig_r0l040.cmb <= sig_r0l040.match and sig_r0l04.seq;

r0_l041: matcher generic map -- J
(
    G_STRUCTURE         => C_STRCT_SIMPLE,
    G_VALUE_A           => C_CABIN_J,
    G_FUNCTION_A        => C_FNCTR_SIMP_SEQ
)
port map
(
    query_opA_i         => query_i(6),
    match_result_o      => sig_r0l041.match
);
sig_r0l041.cmb <= sig_r0l041.match and sig_r0l04.seq;

r0_l042: matcher generic map -- M
(
    G_STRUCTURE         => C_STRCT_SIMPLE,
    G_VALUE_A           => C_CABIN_M,
    G_FUNCTION_A        => C_FNCTR_SIMP_SEQ
)
port map
(
    query_opA_i         => query_i(6),
    match_result_o      => sig_r0l042.match
);
sig_r0l042.cmb <= sig_r0l042.match and sig_r0l04.seq;

r0_l043: matcher generic map -- Y
(
    G_STRUCTURE         => C_STRCT_SIMPLE,
    G_VALUE_A           => C_CABIN_Y,
    G_FUNCTION_A        => C_FNCTR_SIMP_SEQ
)
port map
(
    query_opA_i         => query_i(6),
    match_result_o      => sig_r0l043.match
);
sig_r0l043.cmb <= sig_r0l043.match and sig_r0l04.seq;


r0_l100: matcher generic map -- C
(
    G_STRUCTURE         => C_STRCT_SIMPLE,
    G_VALUE_A           => C_CABIN_C,
    G_FUNCTION_A        => C_FNCTR_SIMP_SEQ
)
port map
(
    query_opA_i         => query_i(6),
    match_result_o      => sig_r0l100.match
);
sig_r0l100.cmb <= sig_r0l100.match and sig_r0l10.seq;

r0_l101: matcher generic map -- M
(
    G_STRUCTURE         => C_STRCT_SIMPLE,
    G_VALUE_A           => C_CABIN_M,
    G_FUNCTION_A        => C_FNCTR_SIMP_SEQ
)
port map
(
    query_opA_i         => query_i(6),
    match_result_o      => sig_r0l101.match
);
sig_r0l101.cmb <= sig_r0l101.match and sig_r0l10.seq;

r0_l102: matcher generic map -- Y
(
    G_STRUCTURE         => C_STRCT_SIMPLE,
    G_VALUE_A           => C_CABIN_Y,
    G_FUNCTION_A        => C_FNCTR_SIMP_SEQ
)
port map
(
    query_opA_i         => query_i(6),
    match_result_o      => sig_r0l102.match
);
sig_r0l102.cmb <= sig_r0l102.match and sig_r0l10.seq;


r0_l200: matcher generic map -- C
(
    G_STRUCTURE         => C_STRCT_SIMPLE,
    G_VALUE_A           => C_CABIN_C,
    G_FUNCTION_A        => C_FNCTR_SIMP_SEQ
)
port map
(
    query_opA_i         => query_i(6),
    match_result_o      => sig_r0l200.match
);
sig_r0l200.cmb <= sig_r0l200.match and sig_r0l20.seq;

r0_l201: matcher generic map -- M
(
    G_STRUCTURE         => C_STRCT_SIMPLE,
    G_VALUE_A           => C_CABIN_M,
    G_FUNCTION_A        => C_FNCTR_SIMP_SEQ
)
port map
(
    query_opA_i         => query_i(6),
    match_result_o      => sig_r0l201.match
);
sig_r0l201.cmb <= sig_r0l201.match and sig_r0l20.seq;

r0_l202: matcher generic map -- Y
(
    G_STRUCTURE         => C_STRCT_SIMPLE,
    G_VALUE_A           => C_CABIN_Y,
    G_FUNCTION_A        => C_FNCTR_SIMP_SEQ
)
port map
(
    query_opA_i         => query_i(6),
    match_result_o      => sig_r0l202.match
);
sig_r0l202.cmb <= sig_r0l202.match and sig_r0l20.seq;


r0_l300: matcher generic map -- C
(
    G_STRUCTURE         => C_STRCT_SIMPLE,
    G_VALUE_A           => C_CABIN_C,
    G_FUNCTION_A        => C_FNCTR_SIMP_SEQ
)
port map
(
    query_opA_i         => query_i(6),
    match_result_o      => sig_r0l300.match
);
sig_r0l300.cmb <= sig_r0l300.match and sig_r0l30.seq;

r0_l301: matcher generic map -- M
(
    G_STRUCTURE         => C_STRCT_SIMPLE,
    G_VALUE_A           => C_CABIN_M,
    G_FUNCTION_A        => C_FNCTR_SIMP_SEQ
)
port map
(
    query_opA_i         => query_i(6),
    match_result_o      => sig_r0l301.match
);
sig_r0l301.cmb <= sig_r0l301.match and sig_r0l30.seq;

r0_l302: matcher generic map -- Y
(
    G_STRUCTURE         => C_STRCT_SIMPLE,
    G_VALUE_A           => C_CABIN_Y,
    G_FUNCTION_A        => C_FNCTR_SIMP_SEQ
)
port map
(
    query_opA_i         => query_i(6),
    match_result_o      => sig_r0l302.match
);
sig_r0l302.cmb <= sig_r0l302.match and sig_r0l30.seq;


-- PCA
-- 502,503  DSE,DIE --
-- 521,522  ISE,IIE
-- 522,521  IIE,ISE
-- 612,613  ISE,IIE

-- 45 IIE BobIntegerInferiorityOrEqualityFunctor
-- 47 ISE BobIntegerSuperiorityOrEqualityFunctor


process (clk_i, rst_i)
begin 
    if (rst_i = '1') then
        sig_r0.seq <= '0';
    elsif rising_edge(clk_i) then
        sig_r0.seq <= sig_r0.match;
        --
        sig_r0l0.seq <= sig_r0l0.cmb;
        sig_r0l1.seq <= sig_r0l1.cmb;
        sig_r0l2.seq <= sig_r0l2.cmb;
        sig_r0l3.seq <= sig_r0l3.cmb;
        --
        sig_r0l00.seq <= sig_r0l00.cmb;
        sig_r0l01.seq <= sig_r0l01.cmb;
        sig_r0l02.seq <= sig_r0l02.cmb;
        sig_r0l03.seq <= sig_r0l03.cmb;
        sig_r0l04.seq <= sig_r0l04.cmb;
        sig_r0l10.seq <= sig_r0l10.cmb;
        sig_r0l20.seq <= sig_r0l20.cmb;
        sig_r0l30.seq <= sig_r0l30.cmb;
        --
        sig_r0l000.seq <= sig_r0l000.cmb;
        sig_r0l010.seq <= sig_r0l010.cmb;
        sig_r0l011.seq <= sig_r0l011.cmb;
        sig_r0l020.seq <= sig_r0l020.cmb;
        sig_r0l021.seq <= sig_r0l021.cmb;
        sig_r0l030.seq <= sig_r0l030.cmb;
        sig_r0l040.seq <= sig_r0l040.cmb;
        sig_r0l041.seq <= sig_r0l041.cmb;
        sig_r0l042.seq <= sig_r0l042.cmb;
        sig_r0l043.seq <= sig_r0l043.cmb;
        sig_r0l100.seq <= sig_r0l100.cmb;
        sig_r0l101.seq <= sig_r0l101.cmb;
        sig_r0l102.seq <= sig_r0l102.cmb;
        sig_r0l200.seq <= sig_r0l200.cmb;
        sig_r0l201.seq <= sig_r0l201.cmb;
        sig_r0l202.seq <= sig_r0l202.cmb;
        sig_r0l300.seq <= sig_r0l300.cmb;
        sig_r0l301.seq <= sig_r0l301.cmb;
        sig_r0l302.seq <= sig_r0l302.cmb;
    end if;
end process;

result_o( 0) <= sig_r0l000.seq;
result_o( 1) <= sig_r0l010.seq;
result_o( 2) <= sig_r0l011.seq;
result_o( 3) <= sig_r0l020.seq;
result_o( 4) <= sig_r0l021.seq;
result_o( 5) <= sig_r0l030.seq;
result_o( 6) <= sig_r0l040.seq;
result_o( 7) <= sig_r0l041.seq;
result_o( 8) <= sig_r0l042.seq;
result_o( 9) <= sig_r0l043.seq;
result_o(10) <= sig_r0l100.seq;
result_o(11) <= sig_r0l101.seq;
result_o(12) <= sig_r0l102.seq;
result_o(13) <= sig_r0l200.seq;
result_o(14) <= sig_r0l201.seq;
result_o(15) <= sig_r0l202.seq;
result_o(16) <= sig_r0l300.seq;
result_o(17) <= sig_r0l301.seq;
result_o(18) <= sig_r0l302.seq;

end behavioural;