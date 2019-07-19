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
        result_ready_i  :  in std_logic; -- TODO not used yet
        result_data_o   : out edge_buffer_type;
        result_valid_o  : out std_logic
    );
end result_reducer;

architecture behavioural of result_reducer is

    type result_reg_type is record
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

result_comb: process(result_r, interim_valid_i, interim_data_i)
    variable v : result_reg_type;
begin
    v := result_r;

    -- default
    v.valid   := '0';
    v.ready   := '1';

    if interim_valid_i = '1' then

        if result_r.interim.query_id = interim_data_i.query_id then
            if result_r.interim.weight >= interim_data_i.weight then
                v.interim := interim_data_i;
            end if;
        else
            v.result  := result_r.interim;
            v.valid   := '1';
            v.interim := interim_data_i;
        end if;

    end if;
    
    result_rin <= v;
end process;

result_seq: process(clk_i)
begin
    if rising_edge(clk_i) then
        if rst_i = '0' then
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