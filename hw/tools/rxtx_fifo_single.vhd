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
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

library tools;
use tools.std_pkg.all;

entity rxtx_fifo_single is
    generic (
        G_DATA_WIDTH    : integer := 32
    );
    port (
        clk_i           :  in std_logic;
        rst_i           :  in std_logic; -- rst low active
        -- input (slave)
        slav_ready_o    : out std_logic;
        slav_valid_i    :  in std_logic;
        slav_last_i     :  in std_logic;
        slav_value_i    :  in std_logic_vector(G_DATA_WIDTH - 1 downto 0);
        -- output (master)
        mast_ready_i    :  in std_logic;
        mast_valid_o    : out std_logic;
        mast_last_o     : out std_logic;
        mast_value_o    : out std_logic_vector(G_DATA_WIDTH - 1 downto 0)
    );
end rxtx_fifo_single;

architecture behavioural of rxtx_fifo_single is

    type flow_ctrl_type is (FLW_CTRL_READ, FLW_CTRL_WRITE);

    type fifo_data_record is record
        flow_ctrl  : flow_ctrl_type;
        reg_last   : std_logic;
        reg_value  : std_logic_vector(G_DATA_WIDTH - 1 downto 0);
    end record;
    signal fifo_r, fifo_rin : fifo_data_record;

begin

slav_ready_o <= '1' when fifo_r.flow_ctrl = FLW_CTRL_READ else '0';
mast_valid_o <= '1' when fifo_r.flow_ctrl = FLW_CTRL_WRITE else '0';
mast_last_o  <= fifo_r.reg_last;
mast_value_o <= fifo_r.reg_value;

fifo_comb: process(fifo_r, slav_valid_i, slav_last_i, slav_value_i, mast_ready_i)
    variable v : fifo_data_record;
begin
    v := fifo_r;

    case fifo_r.flow_ctrl is

      when FLW_CTRL_READ =>

            if slav_valid_i = '1' then
                v.flow_ctrl := FLW_CTRL_WRITE;
                v.reg_value := slav_value_i;
                v.reg_last  := slav_last_i;
            end if;

      when FLW_CTRL_WRITE =>

            if mast_ready_i = '1' then
                v.flow_ctrl := FLW_CTRL_READ;
            end if;

    end case;

    fifo_rin <= v;
end process;

fifo_seq : process(clk_i)
begin
    if rising_edge(clk_i) then
        if rst_i = '0' then
            -- default rst
            fifo_r.flow_ctrl <= FLW_CTRL_READ;
        else
            fifo_r <= fifo_rin;
        end if;
    end if;
end process;

end architecture behavioural;