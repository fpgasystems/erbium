----------------------------------------------------------------------------------
-- Institution: Systems Group, ETH Zurich 
-- PhD Researcher: Fabio Maschi
-- 
-- Create Date: 20.02.2019 15:47:34
-- Design Name: 
-- Module Name: matcher - behavioural
-- Project Name: NFA-BRE
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
use IEEE.STD_LOGIC_1164.ALL;

library bre;
use bre.pkg_bre.all;

entity matcher is
    Generic (
        G_STRUCTURE         : integer;
        G_VALUE_A           : std_logic_vector(C_ENGINE_CRITERIUM_WIDTH-1 downto 0);
        G_VALUE_B           : std_logic_vector(C_ENGINE_CRITERIUM_WIDTH-1 downto 0) := (others=>'0');
        G_FUNCTION_A        : integer;
        G_FUNCTION_B        : integer := 0;
        G_FUNCTION_PAIR     : integer := 0
    );    
    Port (
        query_opA_i         :  in std_logic_vector(C_ENGINE_CRITERIUM_WIDTH-1 downto 0);
        query_opB_i         :  in std_logic_vector(C_ENGINE_CRITERIUM_WIDTH-1 downto 0) := (others=>'0');
        match_result_o      : out std_logic
    );
end matcher;

architecture behavioural of matcher is
    signal sig_mux_pair      : std_logic;
    signal sig_functorA      : std_logic;
    signal sig_functorB      : std_logic;
    --
    signal sig_res_pma       : std_logic;
    signal sig_res_pan       : std_logic;
    signal sig_res_pca       : std_logic; -- [!] EQUALS TO 8 PAN CROSS
begin

--  7 PMA BobPairMarketAndFunctor
sig_res_pma <= sig_functorA and sig_functorB;

--  8 PAN BobPairAndFunctor
sig_res_pan <= sig_functorA and sig_functorB;

--  9 PCA BobPairCrossAndFunctor
sig_res_pca <= sig_res_pan; -- [!] EQUALS TO 8 PAN CROSS


with G_FUNCTION_PAIR select sig_mux_pair <=
    sig_res_pma when C_FNCTR_PAIR_PMA,
    sig_res_pan when C_FNCTR_PAIR_PAN,
    sig_res_pca when C_FNCTR_PAIR_PCA, --[!]
    'Z' when others;


with G_STRUCTURE select match_result_o <=
    sig_functorA      when C_STRCT_SIMPLE,
    sig_mux_pair      when C_STRCT_PAIR,
    'Z' when others;

opA: functor generic map
(
    G_VALUE      => G_VALUE_A,
    G_FUNCTION   => G_FUNCTION_A
)
port map
(
    query_i      => query_opA_i,
    funct_o      => sig_functorA
);

opB: functor generic map
(
    G_VALUE      => G_VALUE_B,
    G_FUNCTION   => G_FUNCTION_B
)
port map
(
    query_i      => query_opB_i,
    funct_o      => sig_functorB
);

end behavioural;