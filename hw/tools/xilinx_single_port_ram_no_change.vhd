
--  Xilinx Single Port No Change RAM
--  This code implements a parameterizable single-port no-change memory where when data is written
--  to the memory, the output remains unchanged.  This is the most power efficient write mode.
--  If a reset or enable is not necessary, it may be tied off or removed from the code.

--  Modify the parameters for the desired RAM characteristics.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library xil_defaultlib;
use xil_defaultlib.ram_pkg.all;
use xil_defaultlib.textio.all;

entity xilinx_single_port_ram_no_change is
generic (
    RAM_WIDTH : integer := 18;                      -- Specify RAM data width
    RAM_DEPTH : integer := 1024;                    -- Specify RAM depth (number of entries)
    RAM_PERFORMANCE : string := "LOW_LATENCY";      -- Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    INIT_FILE : string := "RAM_INIT.dat"            -- Specify name/location of RAM initialization file if using one (leave blank if not)
    );

port (
        addra : in std_logic_vector((clogb2(RAM_DEPTH)-1) downto 0);     -- Address bus, width determined from RAM_DEPTH
        dina  : in std_logic_vector(RAM_WIDTH-1 downto 0);		  -- RAM input data
        clka  : in std_logic;                       			  -- Clock
        wea   : in std_logic;                       			  -- Write enable
        ena   : in std_logic;                       			  -- RAM Enable, for additional power savings, disable port when not in use
        rsta  : in std_logic;                       			  -- Output reset (does not affect memory contents)
        regcea: in std_logic;                       			  -- Output register enable
        douta : out std_logic_vector(RAM_WIDTH-1 downto 0)   			  -- RAM output data
    );

end xilinx_single_port_ram_no_change;

architecture rtl of xilinx_single_port_ram_no_change is

constant C_RAM_WIDTH : integer := RAM_WIDTH;
constant C_RAM_DEPTH : integer := RAM_DEPTH;
constant C_RAM_PERFORMANCE : string := RAM_PERFORMANCE;
constant C_INIT_FILE : string := INIT_FILE;

signal douta_reg : std_logic_vector(C_RAM_WIDTH-1 downto 0) := (others => '0');
type ram_type is array (0 to C_RAM_DEPTH-1) of std_logic_vector (C_RAM_WIDTH-1 downto 0);          -- 2D Array Declaration for RAM signal
signal ram_data : std_logic_vector(C_RAM_WIDTH-1 downto 0) ;

-- The folowing code either initializes the memory values to a specified file or to all zeros to match hardware

function init_from_file(ramfilename : in string) return ram_type is
file ramfile	: text is in ramfilename;
variable ramfileline : line;
variable ram_name	: ram_type;
variable bitvec : bit_vector(C_RAM_WIDTH-1 downto 0);
begin
    for i in ram_type'range loop
        readline (ramfile, ramfileline);
        read (ramfileline, bitvec);
        ram_name(i) := to_stdlogicvector(bitvec);
    end loop;
    return ram_name;
end function;

function init_from_file_or_zeros(ramfilename : in string) return ram_type is
    variable is_synthesis : bit := '1';
begin
    --pragma synthesis_off
    is_synthesis := '0';
    --pragma synthesis_on
    if is_synthesis = '1' then
        return (others => (others => '0'));
    else
        return init_from_file(ramfilename);
    end if;
end function;

-- Following code defines RAM

signal ram_name : ram_type := init_from_file_or_zeros(C_INIT_FILE);
begin
process(clka)
begin
    if(clka'event and clka = '1') then
        if(ena = '1') then
            if(wea = '1') then
                ram_name(to_integer(unsigned(addra))) <= dina;
            else
                ram_data <= ram_name(to_integer(unsigned(addra)));
            end if;
        end if;
    end if;
end process;

--  Following code generates LOW_LATENCY (no output register)
--  Following is a 1 clock cycle read latency at the cost of a longer clock-to-out timing

no_output_register : if C_RAM_PERFORMANCE = "LOW_LATENCY" generate
    douta <= ram_data;
end generate;

--  Following code generates HIGH_PERFORMANCE (use output register)
--  Following is a 2 clock cycle read latency with improved clock-to-out timing

output_register : if C_RAM_PERFORMANCE = "HIGH_PERFORMANCE"  generate
process(clka)
begin
    if(clka'event and clka = '1') then
        if(rsta = '1') then
            douta_reg <= (others => '0');
        elsif(regcea = '1') then
            douta_reg <= ram_data;
        end if;
    end if;
end process;
douta <= douta_reg;
end generate;

end rtl;