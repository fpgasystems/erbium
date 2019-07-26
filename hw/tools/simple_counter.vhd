library ieee;
use ieee.std_logic_1164.all;

library tools;
use tools.std_pkg.all;

entity simple_counter is
    generic (
        G_WIDTH   : integer := 8
    );
    port (
        clk_i     :  in std_logic;
        rst_i     :  in std_logic;
        enable_i  :  in std_logic;
        counter_o : out std_logic_vector(G_WIDTH - 1 downto 0)
    );
end simple_counter;

architecture behavioral of simple_counter is
    signal count : std_logic_vector (G_WIDTH - 1 downto 0);
begin
    
process(clk_i)
begin
    if rising_edge(clk_i) then
        if rst_i = '0' then
            count <= (others => '0');
        elsif enable_i = '1' then
            count <= íncrement(count);
        end if;
    end if;
end process;

counter_o <= count;
    
end behavioral;