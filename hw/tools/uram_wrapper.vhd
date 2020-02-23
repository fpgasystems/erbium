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
use ieee.std_logic_unsigned.all;

library xpm;
use xpm.vcomponents.all;

library tools;
use tools.std_pkg.all;

entity uram_wrapper is
    generic (
        G_RAM_WIDTH  : integer := 64;                  -- Specify RAM witdh (number of bits per row)
        G_RAM_DEPTH  : integer := 1024;                -- Specify RAM depth (number of entries)
        G_RD_LATENCY : integer := 2                    -- Specify RAM read latency
    );
    port (
        clk_i         :  in std_logic;
        core_a_en_i   :  in std_logic;
        core_a_addr_i :  in std_logic_vector((clogb2(G_RAM_DEPTH)-1) downto 0);
        core_a_data_o : out std_logic_vector(G_RAM_WIDTH-1 downto 0);
        core_b_en_i   :  in std_logic;
        core_b_addr_i :  in std_logic_vector((clogb2(G_RAM_DEPTH)-1) downto 0);
        core_b_data_o : out std_logic_vector(G_RAM_WIDTH-1 downto 0);
        wr_en_i       :  in std_logic;
        wr_addr_i     :  in std_logic_vector((clogb2(G_RAM_DEPTH)-1) downto 0);
        wr_data_i     :  in std_logic_vector(G_RAM_WIDTH-1 downto 0)
    );
end uram_wrapper;

architecture behavioural of uram_wrapper is
    signal portb_en       : std_logic;
    signal portb_addr     : std_logic_vector((clogb2(G_RAM_DEPTH)-1) downto 0);
    signal portb_wen      : std_logic_vector(0 downto 0);
begin

portb_en   <= core_b_en_i or wr_en_i;
portb_addr <= wr_addr_i when wr_en_i = '1' else core_b_addr_i;
portb_wen  <= (others => wr_en_i);

-- xpm_memory_tdpram: True Dual Port RAM
-- Xilinx Parameterized Macro, version 2018.3

xpm_memory_tdpram_inst : xpm_memory_tdpram
generic map (
    ADDR_WIDTH_A          => clogb2(G_RAM_DEPTH),
    ADDR_WIDTH_B          => clogb2(G_RAM_DEPTH),
    READ_DATA_WIDTH_A     => G_RAM_WIDTH,
    READ_DATA_WIDTH_B     => G_RAM_WIDTH,
    WRITE_DATA_WIDTH_A    => G_RAM_WIDTH,
    WRITE_DATA_WIDTH_B    => G_RAM_WIDTH,
    BYTE_WRITE_WIDTH_A    => G_RAM_WIDTH,
    BYTE_WRITE_WIDTH_B    => G_RAM_WIDTH,
    MEMORY_PRIMITIVE      => "ultra", --"auto", "distributed", "block" or "ultra"
    MEMORY_SIZE           => G_RAM_DEPTH * G_RAM_WIDTH,
    --
    AUTO_SLEEP_TIME       => 0,
    CLOCKING_MODE         => "common_clock",
    ECC_MODE              => "no_ecc",
    MEMORY_INIT_FILE      => "none",
    MEMORY_INIT_PARAM     => "0",
    MEMORY_OPTIMIZATION   => "true",
    MESSAGE_CONTROL       => 0,
    READ_LATENCY_A        => G_RD_LATENCY,
    READ_LATENCY_B        => G_RD_LATENCY,
    READ_RESET_VALUE_A    => "00000000",
    READ_RESET_VALUE_B    => "00000000",
    USE_EMBEDDED_CONSTRAINT => 0,
    USE_MEM_INIT          => 1,
    WAKEUP_TIME           => "disable_sleep",
    WRITE_MODE_A          => "no_change",
    WRITE_MODE_B          => "no_change"
)
port map (
    clka    => clk_i,
    clkb    => clk_i,
    -- PORT A
    ena => core_a_en_i,
    addra => core_a_addr_i,
    douta => core_a_data_o,
    dina => (others => '0'),
    wea => (others => '0'),
    regcea => '1',
    -- PORT B
    enb => portb_en,
    addrb => portb_addr,
    doutb => core_b_data_o,
    dinb => wr_data_i,
    web => portb_wen,
    regceb => '1',
    --
    rsta => '0',
    rstb => '0',
    sleep => '0',
    dbiterra => open,
    dbiterrb => open,
    sbiterra => open,
    sbiterrb => open,
    injectdbiterra => '0',
    injectdbiterrb => '0',
    injectsbiterra => '0',
    injectsbiterrb => '0'
);

end behavioural;