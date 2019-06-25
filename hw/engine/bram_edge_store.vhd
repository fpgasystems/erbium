
--  Xilinx Single Port No Change RAM
--  This code implements a parameterizable single-port no-change memory where when data is written
--  to the memory, the output remains unchanged.  This is the most power efficient write mode.
--  If a reset or enable is not necessary, it may be tied off or removed from the code.

--  Modify the parameters for the desired RAM characteristics.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.textio.all;

library tools;
use tools.ram_pkg.all;

library bre;
use bre.core_pkg.all;

entity bram_edge_store is
    generic (
        RAM_DEPTH : integer := 1024;                    -- Specify RAM depth (number of entries)
        RAM_PERFORMANCE : string := "LOW_LATENCY";      -- Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
        INIT_FILE : string := "RAM_INIT.dat"            -- Specify name/location of RAM initialization file if using one (leave blank if not)
    );
    port (
        clk_i        :  in std_logic;
        rst_i        :  in std_logic;
        ram_reg_en_i :  in std_logic; -- Output register enable
        ram_en_i     :  in std_logic; -- RAM Enable, for additional power savings, disable port when not in use
        addr_i       :  in std_logic_vector((clogb2(RAM_DEPTH)-1) downto 0);
        wr_data_i    :  in edge_store_type;
        wr_en_i      :  in std_logic;
        rd_data_o    : out edge_store_type
    );
end bram_edge_store;

architecture rtl of bram_edge_store is

constant C_RAM_DEPTH : integer := RAM_DEPTH;
constant C_RAM_PERFORMANCE : string := RAM_PERFORMANCE;
constant C_INIT_FILE : string := INIT_FILE;


type ram_type is array (0 to C_RAM_DEPTH-1) of edge_store_type;          -- 2D Array Declaration for RAM signal
signal ram_data : edge_store_type;

signal rd_data_reg : edge_store_type;-- := (others => (others => '0'));

-- Following code defines RAM

signal ram_name : ram_type;
begin
process(clk_i)
begin
    if rising_edge(clk_i) then
        if(ram_en_i = '1') then
            if(wr_en_i = '1') then
                ram_name(to_integer(unsigned(addr_i))) <= wr_data_i;
            else
                ram_data <= ram_name(to_integer(unsigned(addr_i)));
            end if;
        end if;
    end if;
end process;

--  Following code generates LOW_LATENCY (no output register)
--  Following is a 1 clock cycle read latency at the cost of a longer clock-to-out timing

no_output_register : if C_RAM_PERFORMANCE = "LOW_LATENCY" generate
    rd_data_o <= ram_data;
end generate;

-- --  Following code generates HIGH_PERFORMANCE (use output register)
-- --  Following is a 2 clock cycle read latency with improved clock-to-out timing
-- 
-- output_register : if C_RAM_PERFORMANCE = "HIGH_PERFORMANCE"  generate
-- process(clk_i)
-- begin
--     if rising_edge(clk_i) then
--         if(rst_i = '1') then
--             rd_data_reg <= (others => (others => '0'));
--         elsif(ram_reg_en_i = '1') then
--             rd_data_reg <= ram_data;
--         end if;
--     end if;
-- end process;
-- rd_data_o <= rd_data_reg;
-- end generate;

end rtl;