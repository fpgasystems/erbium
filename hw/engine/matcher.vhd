----------------------------------------------------------------------------------------------------
--  ERBium - Business Rule Engine Hardware Accelerator
--  Copyright (C) 2020 Fabio Maschi - Systems Group, ETH Zurich

--  This program is free software: you can redistribute it and/or modify it under the terms of the
--  GNU Affero General Public License as published by the Free Software Foundation, either version 3
--  of the License, or (at your option) any later version.

--  This software is provided by the copyright holders and contributors "AS IS" and any express or
--  implied warranties, including, but not limited to, the implied warranties of merchantability and
--  fitness for a particular purpose are disclaimed. In no event shall the copyright holder or
--  contributors be liable for any direct, indirect, incidental, special, exemplary, or
--  consequential damages (including, but not limited to, procurement of substitute goods or
--  services; loss of use, data, or profits; or business interruption) however caused and on any
--  theory of liability, whether in contract, strict liability, or tort (including negligence or
--  otherwise) arising in any way out of the use of this software, even if advised of the 
--  possibility of such damage. See the GNU Affero General Public License for more details.

--  You should have received a copy of the GNU Affero General Public License along with this
--  program. If not, see <http://www.gnu.org/licenses/agpl-3.0.en.html>.
----------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library erbium;
use erbium.engine_pkg.all;
use erbium.core_pkg.all;

entity matcher is
    generic (
        G_STRUCTURE         : match_structure_type := STRCT_SIMPLE;
        G_FUNCTION_A        : match_simp_function  := FNCTR_SIMP_NOP;
        G_FUNCTION_B        : match_simp_function  := FNCTR_SIMP_NOP;
        G_FUNCTION_PAIR     : match_pair_function  := FNCTR_PAIR_NOP;
        G_WILDCARD          : std_logic            := '0'
    );
    port (
        op_query_i          :  in std_logic_vector(CFG_CRITERION_VALUE_WIDTH-1 downto 0);
        opA_rule_i          :  in std_logic_vector(CFG_CRITERION_VALUE_WIDTH-1 downto 0);
        opB_rule_i          :  in std_logic_vector(CFG_CRITERION_VALUE_WIDTH-1 downto 0);
        match_result_o      : out std_logic;
        stopscan_o          : out std_logic;
        wildcard_o          : out std_logic
    );
end matcher;

architecture behavioural of matcher is
    signal sig_mux_pair      : std_logic;
    signal sig_functorA      : std_logic;
    signal sig_functorB      : std_logic;
    --
    signal sig_wildcard_a    : std_logic;
    signal sig_wildcard_b    : std_logic;
    --
    signal sig_res_and       : std_logic;
    signal sig_res_or        : std_logic;
    signal sig_res_xor       : std_logic;
    signal sig_res_nand      : std_logic;
    signal sig_res_nor       : std_logic;
begin

wildcard_o   <= sig_wildcard_a or sig_wildcard_b;

sig_res_and  <= sig_functorA and  sig_functorB;

sig_res_or   <= sig_functorA or   sig_functorB;

sig_res_xor  <= sig_functorA xor  sig_functorB;

sig_res_nand <= sig_functorA nand sig_functorB;

sig_res_nor  <= sig_functorA nor  sig_functorB;


with G_FUNCTION_PAIR select sig_mux_pair <=
    sig_res_and  when FNCTR_PAIR_AND,
    sig_res_or   when FNCTR_PAIR_OR,
    sig_res_xor  when FNCTR_PAIR_XOR,
    sig_res_nand when FNCTR_PAIR_NAND,
    sig_res_nor  when FNCTR_PAIR_NOR,
    '0' when others;


with G_STRUCTURE select match_result_o <=
    sig_functorA      when STRCT_SIMPLE,
    sig_mux_pair      when STRCT_PAIR,
    '0' when others;

opA: functor generic map
(
    G_FUNCTION   => G_FUNCTION_A,
    G_WILDCARD   => G_WILDCARD
)
port map
(
    rule_i       => opA_rule_i,
    query_i      => op_query_i,
    funct_o      => sig_functorA,
    stopscan_o   => stopscan_o,
    wildcard_o   => sig_wildcard_a
);

opB: functor generic map
(
    G_FUNCTION   => G_FUNCTION_B,
    G_WILDCARD   => G_WILDCARD
)
port map
(
    rule_i       => opB_rule_i,
    query_i      => op_query_i,
    funct_o      => sig_functorB,
    stopscan_o   => open,
    wildcard_o   => sig_wildcard_b
);

end behavioural;