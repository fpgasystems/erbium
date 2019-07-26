----------------------------------------------------------------------------------
-- Institution: Systems Group, ETH Zurich 
-- PhD Researcher: Fabio Maschi
-- 
-- Create Date: 20.02.2019 15:47:34
-- Design Name: 
-- Module Name: functor - behavioural
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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library bre;
use bre.engine_pkg.all;
use bre.core_pkg.all;

library tools;
use tools.std_pkg.all;

entity functor is
    generic (
        G_FUNCTION      : match_simp_function := FNCTR_SIMP_NOP
    );
    port (
        rule_i          :  in std_logic_vector(CFG_CRITERION_VALUE_WIDTH-1 downto 0);
        query_i         :  in std_logic_vector(CFG_CRITERION_VALUE_WIDTH-1 downto 0);
        funct_o         : out std_logic
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

funct_o <= sig_wildchar or sig_result;

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