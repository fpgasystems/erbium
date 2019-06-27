library IEEE;
use IEEE.STD_LOGIC_1164.all;

library bre;
use bre.engine_pkg.all;
use bre.core_pkg.all;

entity top is
    port (
        clk_i      :  in std_logic;
        rst_i      :  in std_logic;
        query_i    :  in query_in_array_type;
        mem_i      :  in edge_store_type;
        mem_wren_i :  in std_logic_vector(1 downto 0);
        mem_addr_i :  in std_logic_vector(CFG_MEM_ADDR_WIDTH - 1 downto 0)
    );
end top;

architecture behavioural of top is
    --
    signal sig_edgbuff01_wr_en   : std_logic;
    signal sig_edgbuff01_wr_data : edge_buffer_type;
    signal sig_edgbuff01_full    : std_logic;
    signal sig_edgbuff01_rd_en   : std_logic;
    signal sig_edgbuff01_rd_data : edge_buffer_type;
    signal sig_edgbuff01_empty   : std_logic;
    --
    signal sig_edgbuff10_wr_en   : std_logic;
    signal sig_edgbuff10_wr_data : edge_buffer_type;
    signal sig_edgbuff10_full    : std_logic;
    signal sig_edgbuff10_rd_en   : std_logic;
    signal sig_edgbuff10_rd_data : edge_buffer_type;
    signal sig_edgbuff10_empty   : std_logic;
    --
    signal sig_cr0mem_en   : std_logic;
    signal sig_cr0mem_addr : std_logic_vector(CFG_MEM_ADDR_WIDTH - 1 downto 0);
    signal sig_cr1mem_en   : std_logic;
    signal sig_cr1mem_addr : std_logic_vector(CFG_MEM_ADDR_WIDTH - 1 downto 0);
    --
    signal sig_bram0_en   : std_logic;
    signal sig_bram0_addr : std_logic_vector(CFG_MEM_ADDR_WIDTH - 1 downto 0);
    signal sig_bram0_rd   : edge_store_type;
    signal sig_bram1_en   : std_logic;
    signal sig_bram1_addr : std_logic_vector(CFG_MEM_ADDR_WIDTH - 1 downto 0);
    signal sig_bram1_rd   : edge_store_type;
    --
    signal sig_origin_node : edge_buffer_type;
begin

--------------------------------------------------------------

sig_origin_node.pointer <= (others => '0');

cr0_pe : core generic map
(
    G_MATCH_STRCT         => STRCT_PAIR,
    G_MATCH_FUNCTION_A    => FNCTR_SIMP_EQU,
    G_MATCH_FUNCTION_B    => FNCTR_SIMP_EQU,
    G_MATCH_FUNCTION_PAIR => FNCTR_PAIR_OR
)
port map
(
    rst_i           => rst_i,
    clk_i           => clk_i,
    -- FIFO buffer from above
    abv_empty_i     => '0',
    abv_data_i      => sig_origin_node,
    abv_read_o      => open,
    -- current
    query_opA_i     => query_i(0),
    query_opB_i     => query_i(1),
    weight_filter_i => 0,
    -- MEMORY
    mem_edge_i      => sig_bram0_rd,
    mem_addr_o      => sig_cr0mem_addr,
    mem_en_o        => sig_cr0mem_en,
    -- FIFO buffer to below
    blw_full_i      => sig_edgbuff01_full,
    blw_data_o      => sig_edgbuff01_wr_data,
    blw_write_o     => sig_edgbuff01_wr_en
);

edgbuff_01 : buffer_edge generic map
(
    G_DEPTH         => CFG_EDGE_BUFFERS_DEPTH
)
port map
(
    rst_i           => rst_i,
    clk_i           => clk_i,
    --
    wr_en_i         => sig_edgbuff01_wr_en,
    wr_data_i       => sig_edgbuff01_wr_data,
    full_o          => sig_edgbuff01_full,
    --
    rd_en_i         => sig_edgbuff01_rd_en,
    rd_data_o       => sig_edgbuff01_rd_data,
    empty_o         => sig_edgbuff01_empty
);

cr1_pe : core generic map
(
    G_MATCH_STRCT         => STRCT_PAIR,
    G_MATCH_FUNCTION_A    => FNCTR_SIMP_GEQ,
    G_MATCH_FUNCTION_B    => FNCTR_SIMP_LEQ,
    G_MATCH_FUNCTION_PAIR => FNCTR_PAIR_AND
)
port map
(
    rst_i           => rst_i,
    clk_i           => clk_i,
    abv_empty_i     => sig_edgbuff01_empty,
    abv_data_i      => sig_edgbuff01_rd_data,
    abv_read_o      => sig_edgbuff01_rd_en,
    -- current
    query_opA_i     => query_i(2),
    query_opB_i     => query_i(2),
    weight_filter_i => 0,
    -- MEMORY
    mem_edge_i      => sig_bram1_rd,
    mem_addr_o      => sig_cr1mem_addr,
    mem_en_o        => sig_cr1mem_en,
    -- FIFO buffer to below
    blw_full_i      => sig_edgbuff10_full,
    blw_data_o      => sig_edgbuff10_wr_data,
    blw_write_o     => sig_edgbuff10_wr_en
);

edgbuff_10 : buffer_edge generic map
(
    G_DEPTH         => CFG_EDGE_BUFFERS_DEPTH
)
port map
(
    rst_i           => rst_i,
    clk_i           => clk_i,
    --
    wr_en_i         => sig_edgbuff10_wr_en,
    wr_data_i       => sig_edgbuff10_wr_data,
    full_o          => sig_edgbuff10_full,
    --
    rd_en_i         => sig_edgbuff10_rd_en,
    rd_data_o       => sig_edgbuff10_rd_data,
    empty_o         => sig_edgbuff10_empty
);

----------------------------------------------------------------------

sig_bram0_en   <= mem_wren_i(0) or sig_cr0mem_en;
sig_bram0_addr <= mem_addr_i when mem_wren_i(0) = '1' else
                  sig_cr0mem_addr;

sig_bram1_en   <= mem_wren_i(1) or sig_cr1mem_en;
sig_bram1_addr <= mem_addr_i when mem_wren_i(1) = '1' else
                  sig_cr1mem_addr;


bram_cr0 : bram_edge_store generic map
(
    G_RAM_WIDTH       => CFG_MEM_DATA_WIDTH,
    G_RAM_DEPTH       => CFG_EDGE_BRAM_DEPTH,
    G_RAM_PERFORMANCE => "LOW_LATENCY",
    G_INIT_FILE       => "bram_cr0.mem"
)
port map
(
    clk_i        => clk_i,
    rst_i        => rst_i,
    ram_reg_en_i => '1',
    ram_en_i     => sig_bram0_en,
    addr_i       => sig_bram0_addr,
    wr_data_i    => mem_i,
    wr_en_i      => mem_wren_i(0),
    rd_data_o    => sig_bram0_rd
);

bram_cr1 : bram_edge_store generic map
(
    G_RAM_WIDTH       => CFG_MEM_DATA_WIDTH,
    G_RAM_DEPTH       => CFG_EDGE_BRAM_DEPTH,
    G_RAM_PERFORMANCE => "LOW_LATENCY",
    G_INIT_FILE       => "bram_cr1.mem"
)
port map
(
    clk_i        => clk_i,
    rst_i        => rst_i,
    ram_reg_en_i => '1',
    ram_en_i     => sig_bram1_en,
    addr_i       => sig_bram1_addr,
    wr_data_i    => mem_i,
    wr_en_i      => mem_wren_i(1),
    rd_data_o    => sig_bram1_rd
);

end architecture behavioural;