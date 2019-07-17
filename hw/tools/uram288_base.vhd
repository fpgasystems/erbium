
-- URAM288_BASE : In order to incorporate this function into the design,
--     VHDL     : the following instance declaration needs to be placed
--   instance   : in the body of the design code.  The instance name
-- declaration  : (URAM288_BASE_inst) and/or the port declarations after the
--     code     : "=>" declaration maybe changed to properly reference and
--              : connect this function to the design.  All inputs and outputs
--              : must be connected.

--   Library    : In addition to adding the instance declaration, a use
-- declaration  : statement for the UNISIM.vcomponents library needs to be
--     for      : added before the entity declaration.  This library
--    Xilinx    : contains the component declarations for all Xilinx
--  primitives  : primitives and points to the models that will be used
--              : for simulation.

library UNISIM;
use UNISIM.vcomponents.all;

library tools;
use tools.ram_pkg.all;

entity uram_wrapper is
    generic (
        G_RAM_WIDTH : integer := 64;                   -- Specify RAM witdh (number of bits per row)
        G_RAM_DEPTH : integer := 1024;                 -- Specify RAM depth (number of entries)
    );
    port (
        clk_i        :  in std_logic;
        rd_addr_i    :  in std_logic_vector((clogb2(G_RAM_DEPTH)-1) downto 0);
        rd_data_o    : out std_logic_vector(G_RAM_WIDTH-1 downto 0);
        wr_en_i      :  in std_logic;
        wr_addr_i    :  in std_logic_vector((clogb2(G_RAM_DEPTH)-1) downto 0);
        wr_data_i    :  in std_logic_vector(G_RAM_WIDTH-1 downto 0)
    );
end uram_wrapper;

architecture behavioural of uram_wrapper is
   signal rd_data : std_logic_vector(71 downto 0);
   signal rd_addr : std_logic_vector(22 downto 0);
   signal wr_data : std_logic_vector(71 downto 0);
   signal wr_addr : std_logic_vector(22 downto 0);
begin

-- URAM288_BASE: 288K-bit High-Density Base Memory Building Block
--               Virtex UltraScale+
-- Xilinx HDL Language Template, version 2018.2

URAM288_BASE_inst : URAM288_BASE
generic map (
   AUTO_SLEEP_LATENCY => 8,            -- Latency requirement to enter sleep mode
   AVG_CONS_INACTIVE_CYCLES => 10,     -- Average concecutive inactive cycles when is SLEEP mode for power
                                       -- estimation
   BWE_MODE_A => "PARITY_INTERLEAVED", -- Port A Byte write control
   BWE_MODE_B => "PARITY_INTERLEAVED", -- Port B Byte write control
   EN_AUTO_SLEEP_MODE => "FALSE",      -- Enable to automatically enter sleep mode
   IREG_PRE_A => "FALSE",              -- Optional Port A input pipeline registers
   IREG_PRE_B => "FALSE",              -- Optional Port B input pipeline registers
   OREG_A => "FALSE",                  -- Optional Port A output pipeline registers
   OREG_B => "FALSE",                  -- Optional Port B output pipeline registers
   --
   EN_ECC_RD_A          => "FALSE",    -- Port A ECC encoder
   EN_ECC_RD_B          => "FALSE",    -- Port B ECC encoder
   EN_ECC_WR_A          => "FALSE",    -- Port A ECC decoder
   EN_ECC_WR_B          => "FALSE",    -- Port B ECC decoder
   IS_CLK_INVERTED      => '0',        -- Optional inverter for CLK
   IS_EN_A_INVERTED     => '0',        -- Optional inverter for Port A enable
   IS_EN_B_INVERTED     => '0',        -- Optional inverter for Port B enable
   IS_RDB_WR_A_INVERTED => '0',        -- Optional inverter for Port A read/write select
   IS_RDB_WR_B_INVERTED => '0',        -- Optional inverter for Port B read/write select
   IS_RST_A_INVERTED    => '0',        -- Optional inverter for Port A reset
   IS_RST_B_INVERTED    => '0',        -- Optional inverter for Port B reset
   OREG_ECC_A           => "FALSE",    -- Port A ECC decoder output
   OREG_ECC_B           => "FALSE",    -- Port B ECC decoder output
   RST_MODE_A           => "SYNC",     -- Port A reset mode
   RST_MODE_B           => "SYNC",     -- Port B reset mode
   USE_EXT_CE_A         => "FALSE",    -- Enable Port A external CE inputs for output registers
   USE_EXT_CE_B         => "FALSE"     -- Enable Port B external CE inputs for output registers
)
port map (
   CLK               => clk_i,
   RST_A             => '0',
   RST_B             => '0',
   SLEEP             => '0',
   -- read port
   DOUT_A            => rd_data,
   ADDR_A            => rd_addr,
   DIN_A             => (others => '0'),
   EN_A              => '1',
   OREG_CE_A         => '1',
   RDB_WR_A          => '0',
   -- write port
   DOUT_B            => open,
   ADDR_B            => wr_addr,
   DIN_B             => wr_data,
   EN_B              => wr_en_i,
   OREG_CE_B         => '1',
   RDB_WR_B          => '1',
   --
   BWE_A             => (others => '1'),
   BWE_B             => (others => '1'),
   OREG_ECC_CE_A     => '0',
   OREG_ECC_CE_B     => '0',
   INJECT_DBITERR_A  => '0',
   INJECT_SBITERR_A  => '0',
   INJECT_DBITERR_B  => '0',
   INJECT_SBITERR_B  => '0',
   DBITERR_A         => open,
   SBITERR_A         => open,
   DBITERR_B         => open,
   SBITERR_B         => open
);

rd_data_o <= rd_data(G_RAM_WIDTH-1 downto 0);
rd_addr   <= (22 downto (clogb2(G_RAM_DEPTH) => '0') && rd_addr_i;

wr_data   <= (71 downto G_RAM_WIDTH => '0') & wr_data_i;
wr_addr   <= (22 downto (clogb2(G_RAM_DEPTH) => '0') && wr_addr_i;

end behavioural;