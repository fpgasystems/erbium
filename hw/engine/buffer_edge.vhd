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
use erbium.core_pkg.all;

entity buffer_edge is
    generic (
        G_DEPTH   : integer := 32;
        G_ALMST   : integer := 1
    );
    port (
        rst_i         :  in std_logic;
        clk_i         :  in std_logic;
        -- FIFO Write Interface
        wr_en_i       :  in std_logic;
        wr_data_i     :  in edge_buffer_type;
        full_o        : out std_logic;
        almost_full_o : out std_logic;
        -- FIFO Read Interface
        rd_en_i       :  in std_logic;
        rd_data_o     : out edge_buffer_type;
        empty_o       : out std_logic
    );
end buffer_edge;
 
architecture rtl of buffer_edge is

    type fifo_data_type is array (0 to G_DEPTH-1) of edge_buffer_type;

    -- # Words in FIFO, has extra range to allow for assert conditions
    signal fifo_cntr_reg : integer range -1 to G_DEPTH+1;
    signal fifo_data_reg : fifo_data_type;-- := (others => (others => (others => '0')));

    signal wr_index_reg  : integer range 0 to G_DEPTH-1;
    signal rd_index_reg  : integer range 0 to G_DEPTH-1;

    signal sig_almst     : std_logic;
    signal sig_full      : std_logic;
    signal sig_empty     : std_logic;

begin
 
p_ctrl : process (clk_i) is
begin
    if rising_edge(clk_i) then
        if rst_i = '0' then
            fifo_cntr_reg  <= 0;
            wr_index_reg   <= 0;
            rd_index_reg   <= 0;
        else
 
            -- Keeps track of the total number of words in the FIFO
            if (wr_en_i = '1' and rd_en_i = '0') then
                fifo_cntr_reg <= fifo_cntr_reg + 1;
            elsif (wr_en_i = '0' and rd_en_i = '1') then
                fifo_cntr_reg <= fifo_cntr_reg - 1;
            end if;
 
            -- Keeps track of the write index (and controls roll-over)
            if (wr_en_i = '1' and sig_full = '0') then
                if wr_index_reg = G_DEPTH-1 then
                    wr_index_reg <= 0;
                else
                    wr_index_reg <= wr_index_reg + 1;
                end if;
            end if;
 
            -- Keeps track of the read index (and controls roll-over)        
            if (rd_en_i = '1' and sig_empty = '0') then
                if rd_index_reg = G_DEPTH-1 then
                    rd_index_reg <= 0;
                else
                    rd_index_reg <= rd_index_reg + 1;
                end if;
            end if;
 
            -- Registers the input data when there is a write
            if wr_en_i = '1' then
                fifo_data_reg(wr_index_reg) <= wr_data_i;
            end if;

        end if;     -- sync reset
    end if;         -- rising_edge(clk_i)
end process p_ctrl;

rd_data_o <= fifo_data_reg(rd_index_reg);
 
sig_almst <= '1' when fifo_cntr_reg >= G_DEPTH-G_ALMST
                 else '0';
sig_full  <= '1' when fifo_cntr_reg = G_DEPTH else '0';
sig_empty <= '1' when fifo_cntr_reg = 0       else '0';
 
almost_full_o <= sig_almst;
full_o  <= sig_full;
empty_o <= sig_empty;
   
-- ASSERTION LOGIC - Not synthesized
-- synthesis translate_off 
p_assert : process (clk_i) is
begin
    if rising_edge(clk_i) then
        if wr_en_i = '1' and sig_full = '1' then
            report "ASSERT FAILURE - MODULE_REGISTER_FIFO: FIFO IS FULL AND BEING WRITTEN " severity failure;
        end if;
 
        if rd_en_i = '1' and sig_empty = '1' then
            report "ASSERT FAILURE - MODULE_REGISTER_FIFO: FIFO IS EMPTY AND BEING READ " severity failure;
        end if;
    end if;
end process p_ASSERT;
-- synthesis translate_on

end rtl;