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