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
            count <= increment(count);
        end if;
    end if;
end process;

counter_o <= count;
    
end behavioral;