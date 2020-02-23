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
use ieee.numeric_std.all;

library erbium;
use erbium.engine_pkg.all;
use erbium.core_pkg.all;

library tools;
use tools.std_pkg.all;

entity functor is
    generic (
        G_FUNCTION          : match_simp_function := FNCTR_SIMP_NOP;
        G_WILDCARD          : std_logic           := '0'
    );
    port (
        rule_i              :  in std_logic_vector(CFG_CRITERION_VALUE_WIDTH-1 downto 0);
        query_i             :  in std_logic_vector(CFG_CRITERION_VALUE_WIDTH-1 downto 0);
        funct_o             : out std_logic;
        stopscan_o          : out std_logic;
        wildcard_o          : out std_logic
    );
end functor;

architecture behavioural of functor is
    signal sig_res_equ : std_logic;
    signal sig_res_neq : std_logic;
    signal sig_res_grt : std_logic;
    signal sig_res_geq : std_logic;
    signal sig_res_les : std_logic;
    signal sig_res_leq : std_logic;
    --
    signal sig_wildchar : std_logic;
    signal sig_result : std_logic;
begin

gen_wildcard : if G_WILDCARD = '1' and G_FUNCTION /= FNCTR_SIMP_NOP generate
    funct_o    <= sig_wildchar or sig_result;
    wildcard_o <= sig_wildchar;
    stopscan_o <= sig_res_les;
end generate;

gen_wildcard_n : if G_WILDCARD = '0' or G_FUNCTION = FNCTR_SIMP_NOP generate
    funct_o    <= sig_result;
    wildcard_o <= '0';
    stopscan_o <= '0';
end generate;


with G_FUNCTION select sig_result <=
    sig_res_equ when FNCTR_SIMP_EQU,
    sig_res_neq when FNCTR_SIMP_NEQ,
    sig_res_grt when FNCTR_SIMP_GRT,
    sig_res_geq when FNCTR_SIMP_GEQ,
    sig_res_les when FNCTR_SIMP_LES,
    sig_res_leq when FNCTR_SIMP_LEQ,
    'Z' when others;

sig_res_neq <= not sig_res_equ;

process(query_i, rule_i)
begin

    sig_wildchar <= is_zero(rule_i);

    sig_res_equ <= compare(query_i, rule_i);

    if (my_conv_integer(query_i) > my_conv_integer(rule_i)) then
        sig_res_grt <= '1';
    else
        sig_res_grt <= '0';
    end if;

    if (my_conv_integer(query_i) >= my_conv_integer(rule_i)) then
        sig_res_geq <= '1';
    else
        sig_res_geq <= '0';
    end if;

    if (my_conv_integer(query_i) < my_conv_integer(rule_i)) then
        sig_res_les <= '1';
    else
        sig_res_les <= '0';
    end if;

    if (my_conv_integer(query_i) <= my_conv_integer(rule_i)) then
        sig_res_leq <= '1';
    else
        sig_res_leq <= '0';
    end if;

end process;

end behavioural;