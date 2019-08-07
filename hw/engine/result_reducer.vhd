library ieee;
use ieee.std_logic_1164.all;

library bre;
use bre.engine_pkg.all;
use bre.core_pkg.all;

library tools;
use tools.std_pkg.all;

entity result_reducer is
    port (
        clk_i           :  in std_logic;
        rst_i           :  in std_logic; -- low active
        -- interim result from NFA-PE
        interim_valid_i :  in std_logic;
        interim_data_i  :  in edge_buffer_type;
        interim_ready_o : out std_logic;
        -- final result to TOP
        result_ready_i  :  in std_logic;
        result_data_o   : out edge_buffer_type;
        result_valid_o  : out std_logic
    );
end result_reducer;

architecture behavioural of result_reducer is

    type flow_ctrl_type is (FLW_CTRL_READ, FLW_CTRL_WRITE);

    type result_reg_type is record
        flow_ctrl     : flow_ctrl_type;
        interim       : edge_buffer_type;
        result        : edge_buffer_type;
        valid         : std_logic;
        ready         : std_logic;
    end record;

    signal result_r, result_rin : result_reg_type;
begin

----------------------------------------------------------------------------------------------------
-- RESULT REDUCER                                                                                 --
----------------------------------------------------------------------------------------------------

interim_ready_o <= result_r.ready;
result_data_o   <= result_r.result;
result_valid_o  <= result_r.valid;

result_comb: process(result_r, interim_valid_i, interim_data_i, result_ready_i)
    variable v : result_reg_type;
begin
    v := result_r;

    case result_r.flow_ctrl is

      when FLW_CTRL_READ =>

            v.ready := '1';
            v.valid := '0';

            if interim_valid_i = '1' then

                if result_r.interim.query_id = interim_data_i.query_id then
                    if interim_data_i.weight >= result_r.interim.weight then
                        v.interim := interim_data_i;
                    end if;
                else
                    v.ready     := '0';
                    v.valid     := '1';
                    v.flow_ctrl := FLW_CTRL_WRITE;
                    v.result    := result_r.interim;
                    v.interim   := interim_data_i;
                end if;

            end if;

      when FLW_CTRL_WRITE =>

            v.ready := '0';
            v.valid := '1';

            if result_ready_i = '1' then
                v.valid     := '0';
                v.flow_ctrl := FLW_CTRL_READ;
            end if;
            
    end case;
    
    result_rin <= v;
end process;

result_seq: process(clk_i)
begin
    if rising_edge(clk_i) then
        if rst_i = '0' then
            result_r.flow_ctrl        <= FLW_CTRL_READ;
            result_r.interim.query_id <=  0 ;
            result_r.interim.weight   <=  0 ;
            result_r.valid            <= '0';
            result_r.ready            <= '1';
        else
            result_r <= result_rin;
        end if;
    end if;
end process;

end architecture behavioural;