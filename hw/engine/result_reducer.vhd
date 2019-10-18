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
        engine_idle_i   :  in std_logic;
        -- FIFO interim result from NFA-PE
        interim_empty_i :  in std_logic;
        interim_data_i  :  in edge_buffer_type;
        interim_read_o  : out std_logic;
        -- final result to TOP
        result_ready_i  :  in std_logic;
        result_data_o   : out edge_buffer_type;
        result_last_o   : out std_logic;
        result_stats_o  : out result_stats_type;
        result_valid_o  : out std_logic
    );
end result_reducer;

architecture behavioural of result_reducer is

    type flow_ctrl_type is (FLW_CTRL_BUFF, FLW_CTRL_READ, FLW_CTRL_WRITE);

    type result_reg_type is record
        flow_ctrl     : flow_ctrl_type;
        interim       : edge_buffer_type;
        result        : edge_buffer_type;
        valid         : std_logic;
        read          : std_logic;
        empty         : std_logic;
        last          : std_logic;
    end record;

    signal result_r, result_rin : result_reg_type;
    signal stats_r              : result_stats_type;
    signal sig_stats_reset      : std_logic;
    signal sig_match_higher_en  : std_logic;
    signal sig_match_lower_en   : std_logic;
    --
    signal stats_queries_out    : std_logic_vector(63 downto 0);
    signal stats_queries_in     : std_logic_vector(63 downto 0);
    signal stats_queries_in_en  : std_logic;
begin

----------------------------------------------------------------------------------------------------
-- RESULT REDUCER                                                                                 --
----------------------------------------------------------------------------------------------------

interim_read_o  <= result_r.read;
result_data_o   <= result_r.result;
result_last_o   <= result_r.last;
result_valid_o  <= result_r.valid;
result_stats_o  <= stats_r;

result_comb: process(result_r, interim_empty_i, interim_data_i, result_ready_i, engine_idle_i)
    variable v          : result_reg_type;
    variable v_new      : std_logic;
    variable v_winterim : integer range 0 to 2**CFG_WEIGHT_WIDTH - 1;
    variable v_wresult  : integer range 0 to 2**CFG_WEIGHT_WIDTH - 1;
begin
    v := result_r;

    if result_r.interim.query_id /= interim_data_i.query_id then
        v_new := not interim_empty_i;
    else
        v_new := '0';
    end if;

    v_winterim := my_conv_integer(interim_data_i.weight);
    v_wresult  := my_conv_integer(result_r.interim.weight);

    case result_r.flow_ctrl is

      when FLW_CTRL_BUFF =>

            v.read  := '0';
            v.valid := '0';
            
            -- INTERIM
            v.interim.clock_cycles := increment(result_r.interim.clock_cycles);

            -- RESULT
            v.result := result_r.interim;
            v.result.clock_cycles := increment(result_r.interim.clock_cycles);

            if interim_empty_i = '0' then

                -- GO READ
                v.read  := '1';
                v.flow_ctrl := FLW_CTRL_READ;

            elsif (engine_idle_i and not result_r.empty) = '1' then

                -- GO WRITE (LAST VALUE)
                v.last  := '1';
                v.empty := '1';
                v.valid := '1';
                v.flow_ctrl := FLW_CTRL_WRITE;

            end if;

      when FLW_CTRL_READ =>

            v.read  := '0';
            v.valid := '0';
            v.empty := '0';

            -- RESULT
            v.result := result_r.interim;
            v.result.clock_cycles := increment(result_r.interim.clock_cycles);

            -- INTERIM
            v.interim.clock_cycles := increment(result_r.interim.clock_cycles);
            if v_new = '1' or v_winterim >= v_wresult then
                v.interim := interim_data_i;
                v.interim.clock_cycles := increment(interim_data_i.clock_cycles);
            end if;

            -- GO WRITE
            if v_new = '1' and result_r.empty = '0' then
                v.valid     := '1';
                v.flow_ctrl := FLW_CTRL_WRITE;
            else
                v.flow_ctrl := FLW_CTRL_BUFF;
            end if;

      when FLW_CTRL_WRITE =>

            v.read  := '0';
            v.valid := '1';

            if result_ready_i = '1' then
                v.read      := '0';
                v.valid     := '0';
                v.last      := '0';
                v.flow_ctrl := FLW_CTRL_BUFF;
            end if;
            
    end case;
    
    result_rin <= v;
end process;

result_seq: process(clk_i)
begin
    if rising_edge(clk_i) then
        if rst_i = '0' then
            result_r.flow_ctrl        <= FLW_CTRL_BUFF;
            result_r.interim.query_id <= C_INIT_QUERY_ID;
            result_r.interim.weight   <= (others => '0');
            result_r.valid            <= '0';
            result_r.read             <= '0';
            result_r.empty            <= '1';
            result_r.last             <= '0';
        else
            result_r <= result_rin;
        end if;
    end if;
end process;

----------------------------------------------------------------------------------------------------
-- STATS                                                                                          --
----------------------------------------------------------------------------------------------------

stats_r.clock_cycle_counter <= increment(result_r.result.clock_cycles);

sig_stats_reset <= rst_i when (result_r.flow_ctrl = FLW_CTRL_READ) else '0';

sig_match_higher_en <= result_r.read when (result_r.interim.query_id = interim_data_i.query_id and
                my_conv_integer(interim_data_i.weight) < my_conv_integer(result_r.interim.weight))
                       else '0';

sig_match_lower_en  <= result_r.read when (result_r.interim.query_id = interim_data_i.query_id and
                my_conv_integer(interim_data_i.weight) > my_conv_integer(result_r.interim.weight))
                       else '0';

stats_queries_in_en  <= result_r.read when (result_r.interim.query_id /= interim_data_i.query_id)
                        else '0';

counter_weight_heigher: simple_counter generic map
(
    G_WIDTH   => CFG_DBG_COUNTERS_WIDTH
)
port map
(
    clk_i     => clk_i,
    rst_i     => sig_stats_reset,
    enable_i  => sig_match_higher_en,
    counter_o => stats_r.match_higher_weight
);

counter_weight_lower: simple_counter generic map
(
    G_WIDTH   => CFG_DBG_COUNTERS_WIDTH
)
port map
(
    clk_i     => clk_i,
    rst_i     => sig_stats_reset,
    enable_i  => sig_match_lower_en,
    counter_o => stats_r.match_lower_weight
);

counter_queries_out: simple_counter generic map
(
    G_WIDTH   => 64
)
port map
(
    clk_i     => clk_i,
    rst_i     => rst_i,
    enable_i  => result_r.valid and result_ready_i,
    counter_o => stats_queries_out
);

counter_queries_in: simple_counter generic map
(
    G_WIDTH   => 64
)
port map
(
    clk_i     => clk_i,
    rst_i     => rst_i,
    enable_i  => stats_queries_in_en,
    counter_o => stats_queries_in
);

end architecture behavioural;