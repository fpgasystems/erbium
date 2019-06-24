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
use bre.core_pkg.all;

entity matcher is
    generic (
        G_STRUCTURE         : integer;
        G_FUNCTION_A        : integer;
        G_FUNCTION_B        : integer;
        G_FUNCTION_PAIR     : integer
    );
    port (
        opA_rule_i          :  in std_logic_vector(CFG_ENGINE_CRITERIUM_WIDTH-1 downto 0);
        opA_query_i         :  in std_logic_vector(CFG_ENGINE_CRITERIUM_WIDTH-1 downto 0);
        opB_rule_i          :  in std_logic_vector(CFG_ENGINE_CRITERIUM_WIDTH-1 downto 0);
        opB_query_i         :  in std_logic_vector(CFG_ENGINE_CRITERIUM_WIDTH-1 downto 0);
        match_result_o      : out std_logic
    );
end matcher;

architecture behavioural of matcher is
    signal sig_mux_pair      : std_logic;
    signal sig_functorA      : std_logic;
    signal sig_functorB      : std_logic;
    --
    signal sig_res_and       : std_logic;
    signal sig_res_or        : std_logic;
    signal sig_res_xor       : std_logic;
    signal sig_res_nand      : std_logic;
    signal sig_res_nor       : std_logic;
begin

sig_res_and  <= sig_functorA and  sig_functorB;

sig_res_or   <= sig_functorA or   sig_functorB;

sig_res_xor  <= sig_functorA xor  sig_functorB;

sig_res_nand <= sig_functorA nand sig_functorB;

sig_res_nor  <= sig_functorA nor  sig_functorB;


with G_FUNCTION_PAIR select sig_mux_pair <=
    sig_res_and  when C_FNCTR_PAIR_AND,
    sig_res_or   when C_FNCTR_PAIR_OR,
    sig_res_xor  when C_FNCTR_PAIR_XOR,
    sig_res_nand when C_FNCTR_PAIR_NAND,
    sig_res_nor  when C_FNCTR_PAIR_NOR,
    'Z' when others;


with structure_i select match_result_o <=
    sig_functorA      when C_STRCT_SIMPLE,
    sig_mux_pair      when C_STRCT_PAIR,
    'Z' when others;

opA: functor generic map
(
    G_FUNCTION   => G_FUNCTION_A
)
port map
(
    rule_i       => opA_rule_i,
    query_i      => opA_query_i,
    funct_o      => sig_functorA
);

opB: functor generic map
(
    G_FUNCTION   => G_FUNCTION_B
)
port map
(
    rule_i       => opB_rule_i,
    query_i      => opB_query_i,
    funct_o      => sig_functorB
);

end behavioural;