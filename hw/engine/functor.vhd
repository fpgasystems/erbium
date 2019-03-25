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

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

library bre;
use bre.pkg_bre.all;

entity functor is
    Generic (
        G_VALUE         : std_logic_vector(C_ENGINE_CRITERIUM_WIDTH-1 downto 0);
        G_FUNCTION      : integer
    );    
    Port (
        query_i         :  in std_logic_vector(C_ENGINE_CRITERIUM_WIDTH-1 downto 0);
        funct_o         : out std_logic
    );
end functor;

architecture behavioural of functor is
    --signal res_bna : std_logic;
    --signal res_bno : std_logic;
    --signal res_ban : std_logic;
    --signal res_bor : std_logic;
    --signal res_bdi : std_logic;
    --signal res_beq : std_logic;
    --signal res_ddi : std_logic;
    --signal res_deq : std_logic;
    --signal res_din : std_logic;
    signal sig_res_die : std_logic;
    --signal res_dsu : std_logic;
    signal sig_res_dse : std_logic;
    --signal res_tdi : std_logic;
    --signal res_teq : std_logic;
    --signal res_tin : std_logic;
    --signal res_tie : std_logic;
    --signal res_tsu : std_logic;
    --signal res_tse : std_logic;
    --signal res_hdi : std_logic;
    --signal res_heq : std_logic;
    --signal res_hin : std_logic;
    --signal res_hie : std_logic;
    --signal res_hsu : std_logic;
    --signal res_hse : std_logic;
    --signal res_sdi : std_logic;
    signal sig_res_seq : std_logic;
    --signal res_sin : std_logic;
    --signal res_idi : std_logic;
    --signal res_ieq : std_logic;
    --signal res_iin : std_logic;
    --signal res_iie : std_logic;
    --signal res_isu : std_logic;
    --signal res_ise : std_logic;
    --signal res_udi : std_logic;
    --signal res_ueq : std_logic;
    --signal res_uin : std_logic;
    --signal res_uie : std_logic;
    --signal res_usu : std_logic;
    --signal res_use : std_logic;
    --signal res_amf : std_logic;
    signal sig_res_mme : std_logic; -- [!] FAKE, CODE NOT KNOWN
begin

with G_FUNCTION select funct_o <=
--    res_bna when "",
--    res_bno when "",
--    res_ban when "",
--    res_bor when "",
--    res_bdi when "",
--    res_beq when "",
--    res_ddi when "",
--    res_deq when "",
--    res_din when "",
    sig_res_die when C_FNCTR_SIMP_DIE,
--    res_dsu when "",
    sig_res_dse when C_FNCTR_SIMP_DSE,
--    res_tdi when "",
--    res_teq when "",
--    res_tin when "",
--    res_tie when "",
--    res_tsu when "",
--    res_tse when "",
--    res_hdi when "",
--    res_heq when "",
--    res_hin when "",
--    res_hie when "",
--    res_hsu when "",
--    res_hse when "",
--    res_sdi when "",
    sig_res_seq when C_FNCTR_SIMP_SEQ,
--    res_sin when "",
--    res_idi when "",
--    res_ieq when "",
--    res_iin when "",
--    res_iie when "",
--    res_isu when "",
--    res_ise when "",
--    res_udi when "",
--    res_ueq when "",
--    res_uin when "",
--    res_uie when "",
--    res_usu when "",
--    res_use when "",
--    res_amf when "",
    sig_res_mme when C_FNCTR_SIMP_MME, -- [!] FAKE, CODE NOT KNOWN
    'Z' when others;

process(query_i)
begin
    -- 15 DIE BobDateInferiorityOrEqualityFunctor
    if (G_VALUE <= query_i) then
        sig_res_die <= '1';
    else
        sig_res_die <= '0';
    end if;

    -- 17 DSE BobDateSuperiorityOrEqualityFunctor
    if (G_VALUE >= query_i) then
        sig_res_dse <= '1';
    else
        sig_res_dse <= '0';
    end if;

    -- 40 SEQ BobStringEqualityFunctor
    if (G_VALUE = query_i) then
        sig_res_seq <= '1';
    else
        sig_res_seq <= '0';
    end if;

    -- [99] MME
    if (G_VALUE = query_i) then  -- [!] FAKE, CODE NOT KNOWN
        sig_res_mme <= '1';
    else
        sig_res_mme <= '0';
    end if;
end process;

end behavioural;
