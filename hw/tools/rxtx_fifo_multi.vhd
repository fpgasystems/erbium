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

entity rxtx_fifo_multi is
    generic (
        G_DATA_WIDTH    : integer := 32;
        G_DEPTH         : integer := 5
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
end rxtx_fifo_multi;

architecture behavioural of rxtx_fifo_multi is

    type rxtx_record is record
        ready    : std_logic;
        valid    : std_logic;
        last     : std_logic;
        value    : std_logic_vector(G_DATA_WIDTH - 1 downto 0);
    end record;

    type rxtx_record_array is array (G_DEPTH downto 0) of rxtx_record;
    
    signal sig_rxtx : rxtx_record_array;

begin

slav_ready_o <= sig_rxtx(0).ready;
sig_rxtx(0).valid <= slav_valid_i;
sig_rxtx(0).last  <= slav_last_i;
sig_rxtx(0).value <= slav_value_i;

sig_rxtx(G_DEPTH).ready <= mast_ready_i;
mast_valid_o <= sig_rxtx(G_DEPTH).valid;
mast_last_o  <= sig_rxtx(G_DEPTH).last;
mast_value_o <= sig_rxtx(G_DEPTH).value;

gen_fifolayers: for L in 0 to G_DEPTH - 1 generate

    fifo_layer: entity tools.rxtx_fifo_single generic map
    (
        G_DATA_WIDTH    => G_DATA_WIDTH
    )
    port map
    (
        clk_i           => clk_i,
        rst_i           => rst_i,
        -- input (slave)
        slav_ready_o    => sig_rxtx(L).ready,
        slav_valid_i    => sig_rxtx(L).valid,
        slav_last_i     => sig_rxtx(L).last,
        slav_value_i    => sig_rxtx(L).value,
        -- output (master)
        mast_ready_i    => sig_rxtx(L+1).ready,
        mast_valid_o    => sig_rxtx(L+1).valid,
        mast_last_o     => sig_rxtx(L+1).last,
        mast_value_o    => sig_rxtx(L+1).value
    );

end generate gen_fifolayers;

end architecture behavioural;