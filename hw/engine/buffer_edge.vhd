library ieee;
use ieee.std_logic_1164.all;

library bre;
use bre.core_pkg.all;

entity buffer_edge is
    generic (
        G_DEPTH : integer := 32
    );
    port (
        rst_i      :  in std_logic;
        clk_i      :  in std_logic;
        -- FIFO Write Interface
        wr_en_i    :  in std_logic;
        wr_data_i  :  in edge_buffer_type;
        full_o     : out std_logic;
        -- FIFO Read Interface
        rd_en_i    :  in std_logic;
        rd_data_o  : out edge_buffer_type;
        empty_o    : out std_logic
    );
end buffer_edge;
 
architecture rtl of buffer_edge is

    type fifo_data_type is array (0 to G_DEPTH-1) of edge_buffer_type;

    -- # Words in FIFO, has extra range to allow for assert conditions
    signal fifo_cntr_reg : integer range -1 to G_DEPTH+1;
    signal fifo_data_reg : fifo_data_type;-- := (others => (others => (others => '0')));

    signal wr_index_reg  : integer range 0 to G_DEPTH-1;
    signal rd_index_reg  : integer range 0 to G_DEPTH-1;

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
 
sig_full  <= '1' when fifo_cntr_reg = G_DEPTH else '0';
sig_empty <= '1' when fifo_cntr_reg = 0       else '0';
 
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