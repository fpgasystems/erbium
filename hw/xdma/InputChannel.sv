///////////////////////////////////////////////////////////////////////////////
//  ERBium - Business Rule Engine Hardware Accelerator
//  Copyright (C) 2020 Fabio Maschi - Systems Group, ETH Zurich

//  This program is free software: you can redistribute it and/or modify it
//  under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or (at your
//  option) any later version.

//  This software is provided by the copyright holders and contributors "AS IS"
//  and any express or implied warranties, including, but not limited to, the
//  implied warranties of merchantability and fitness for a particular purpose
//  are disclaimed. In no event shall the copyright holder or contributors be
//  liable for any direct, indirect, incidental, special, exemplary, or
//  consequential damages (including, but not limited to, procurement of
//  substitute goods or services; loss of use, data, or profits; or business
//  interruption) however caused and on any theory of liability, whether in
//  contract, strict liability, or tort (including negligence or otherwise)
//  arising in any way out of the use of this software, even if advised of the
//  possibility of such damage. See the GNU Affero General Public License for
//  more details.

//  You should have received a copy of the GNU Affero General Public License
//  along with this program. If not, see
//  <http://www.gnu.org/licenses/agpl-3.0.en.html>.
///////////////////////////////////////////////////////////////////////////////

`default_nettype none
`timescale 1 ns / 1 ps

module InputChannel
    #(
        parameter C_M_AXI_ID_WIDTH   = 1,
        parameter C_M_AXI_ADDR_WIDTH = 64,
        parameter C_M_AXI_DATA_WIDTH = 512,
        parameter C_LENGTH_WIDTH     = 32
    )(
        input  wire                           data_clk        ,
        input  wire                           data_rst_n      ,
        input  wire                           ctrl_start      ,
        output wire                           ctrl_done       ,

        // user signals
        input  wire [63:0]                    nfa_hash        ,
        input  wire [C_M_AXI_ADDR_WIDTH-1:0]  nfadata_ptr     ,
        input  wire [C_LENGTH_WIDTH-1:0]      nfadata_cls     ,
        input  wire [C_M_AXI_ADDR_WIDTH-1:0]  queries_ptr     ,
        input  wire [C_LENGTH_WIDTH-1:0]      queries_cls     ,

        // AXI4 master interface (read only)
        output wire                           m_axi_arvalid   ,
        input  wire                           m_axi_arready   ,
        output wire [C_M_AXI_ADDR_WIDTH-1:0]  m_axi_araddr    ,
        output reg  [C_M_AXI_ID_WIDTH-1:0]    m_axi_arid      ,
        output wire [7:0]                     m_axi_arlen     ,
        output wire [2:0]                     m_axi_arsize    ,
        input  wire                           m_axi_rvalid    ,
        output wire                           m_axi_rready    ,
        input  wire [C_M_AXI_DATA_WIDTH-1:0]  m_axi_rdata     ,
        input  wire                           m_axi_rlast     ,
        input  wire [C_M_AXI_ID_WIDTH-1:0]    m_axi_rid       , // not in use
        input  wire [1:0]                     m_axi_rresp     ,

        // AXI4-Stream master interface
        input  wire                           m_axis_aclk     ,
        input  wire                           m_axis_areset_n ,
        output wire                           m_axis_tvalid   ,
        input  wire                           m_axis_tready   ,
        output wire [C_M_AXI_DATA_WIDTH-1:0]  m_axis_tdata    ,
        output wire                           m_axis_tlast    ,
        output wire                           m_axis_ttype
    );

    // Local Parameters
    localparam LP_DW_BYTES           = C_M_AXI_DATA_WIDTH/8;
    localparam LP_AXI_BURST_LEN      = ((4096 / LP_DW_BYTES) < 256) ? (4096 / LP_DW_BYTES) : 256;
    localparam LP_LOG_BURST_LEN      = $clog2(LP_AXI_BURST_LEN);
    localparam LP_RD_MAX_OUTSTANDING = 3;
    localparam LP_RD_FIFO_DEPTH      = LP_AXI_BURST_LEN * (LP_RD_MAX_OUTSTANDING + 1);

    localparam [2:0]
        IDLE                 = 3'b000,
        PREPARE_NFA          = 3'b001,
        READ_NFA             = 3'b010,
        DONE_NFA_WAIT_FIFO   = 3'b011,
        PREPARE_QUERY        = 3'b100,
        READ_QUERY           = 3'b101,
        DONE_QUERY_WAIT_FIFO = 3'b110;
        
    // Wires and Variables
    logic [2:0]                     ctrl_state           ;
    logic                           ctrl_done_r          ;
    logic                           axim_start           ;
    logic                           axim_done_pulse      ;
    logic                           axim_done            ;
    logic                           axim_done_axisclk    ;
    logic [C_M_AXI_ADDR_WIDTH-1:0]  axim_offset          ;
    logic [C_LENGTH_WIDTH-1:0]      axim_length          ;
    logic [C_LENGTH_WIDTH-1:0]      axim_length_axisclk  ;
    logic [C_LENGTH_WIDTH-1:0]      fifo_rd_count        ;
    logic                           fifo_tvalid          ;
    logic                           fifo_tready_n        ;
    logic [C_M_AXI_DATA_WIDTH-1:0]  fifo_tdata           ;
    logic                           fifo_full            ;
    logic                           fifo_empty           ;
    logic                           fifo_done            ;
    logic                           fifo_done_dataclk    ;
    logic                           m_axis_ttype_dataclk ;
    logic [63:0]                    last_nfa_hash        ;

    ///////////////////////////////////////////////////////////////////////////
    // State machine for loading data into the core:
    //   - NFA data at first iteration and at every nfa_hash change
    //   - Queries
    ///////////////////////////////////////////////////////////////////////////

    assign ctrl_done = ctrl_done_r;

    always @ (posedge data_clk) begin

        if (data_rst_n == 1'b0) begin
            ctrl_done_r <= 1'b0;
            ctrl_state  <= IDLE;
            axim_start  <= 1'b0;
            axim_done   <= 1'b0;
            last_nfa_hash <= 64'b0;
        end
        else begin
            case (ctrl_state)

                // Wait for a processing request
                default : begin
                    // Launch processing but reload NFA in case new
                    // NFA has been loaded
                    ctrl_done_r <= 1'b0;
                    if (ctrl_start == 1'b1) begin
                        if (nfa_hash != last_nfa_hash) begin
                            last_nfa_hash <= nfa_hash;
                            ctrl_state  <= PREPARE_NFA;
                        end else begin
                            ctrl_state <= PREPARE_QUERY;
                        end
                    end
                end
                // Prepare signals for loading NFA
                PREPARE_NFA : begin
                    axim_start  <= 1'b1;
                    axim_offset <= nfadata_ptr;
                    axim_length <= nfadata_cls;
                    ctrl_state  <= READ_NFA;
                    m_axis_ttype_dataclk <= 1'b0;
                end
                // Reload NFA into the core
                READ_NFA : begin
                    axim_start <= 1'b0;
                    if (axim_done_pulse == 1'b1) begin
                        ctrl_state <= DONE_NFA_WAIT_FIFO;
                        axim_done  <= 1'b1;
                    end
                end
                // Wait for FIFO to be fully read
                DONE_NFA_WAIT_FIFO : begin
                    if (fifo_done_dataclk == 1'b1) begin
                        ctrl_state <= PREPARE_QUERY;
                        axim_done  <= 1'b0;
                    end
                end
                // Prepare signals for loading queries
                PREPARE_QUERY : begin
                    axim_start  <= 1'b1;
                    axim_offset <= queries_ptr;
                    axim_length <= queries_cls;
                    ctrl_state  <= READ_QUERY;
                    m_axis_ttype_dataclk <= 1'b1;
                end
                // Read query and wait for processing completion
                READ_QUERY : begin
                    axim_start <= 1'b0;
                    if (axim_done_pulse == 1'b1) begin
                        ctrl_state <= DONE_QUERY_WAIT_FIFO;
                        axim_done  <= 1'b1;
                    end

                end
                // Wait for FIFO to be fully read
                DONE_QUERY_WAIT_FIFO : begin
                    if (fifo_done_dataclk == 1'b1) begin
                        ctrl_state  <= IDLE;
                        ctrl_done_r <= 1'b1;
                        axim_done   <= 1'b0;
                    end
                end
            endcase
        end
    end

    ///////////////////////////////////////////////////////////////////////////
    // AXI ADDRESS CHANNEL ID UPDATE
    ///////////////////////////////////////////////////////////////////////////

    always @ (posedge data_clk) begin
        if (~data_rst_n) begin
            m_axi_arid <= {C_M_AXI_ID_WIDTH{1'b1}};
        end
        else if (axim_done == 1'b1) begin
            m_axi_arid <= ~m_axi_arid;
        end
    end

    ///////////////////////////////////////////////////////////////////////////
    // DATA CHANNEL
    ///////////////////////////////////////////////////////////////////////////

    // AXI4 Read Master
    xdma_axi_read_master #(
        .C_ADDR_WIDTH       ( C_M_AXI_ADDR_WIDTH    ),
        .C_DATA_WIDTH       ( C_M_AXI_DATA_WIDTH    ),
        .C_LENGTH_WIDTH     ( C_LENGTH_WIDTH        ),
        .C_BURST_LEN        ( LP_AXI_BURST_LEN      ),
        .C_LOG_BURST_LEN    ( LP_LOG_BURST_LEN      ),
        .C_MAX_OUTSTANDING  ( LP_RD_MAX_OUTSTANDING )
    ) xdma_axi_read_master_inst (
        .aclk           ( data_clk        ),
        .areset         ( ~data_rst_n     ),
        .ctrl_start     ( axim_start      ),
        .ctrl_done      ( axim_done_pulse ),
        .ctrl_offset    ( axim_offset     ),
        .ctrl_length    ( axim_length     ),
        .ctrl_prog_full ( fifo_full       ),
        .arvalid        ( m_axi_arvalid   ),
        .arready        ( m_axi_arready   ),
        .araddr         ( m_axi_araddr    ),
        .arlen          ( m_axi_arlen     ),
        .arsize         ( m_axi_arsize    ),
        .rvalid         ( m_axi_rvalid    ),
        .rready         ( m_axi_rready    ),
        .rdata          ( m_axi_rdata     ),
        .rlast          ( m_axi_rlast     ),
        .rresp          ( m_axi_rresp     ),

        .m_tvalid       ( fifo_tvalid     ),
        .m_tready       ( ~fifo_tready_n  ),
        .m_tdata        ( fifo_tdata      )
    );

    // FIFO for CDC
    xpm_fifo_async # (
        .FIFO_MEMORY_TYPE     ( "auto"                     ),
        .ECC_MODE             ( "no_ecc"                   ),
        .RELATED_CLOCKS       ( 0                          ),
        .FIFO_WRITE_DEPTH     ( LP_RD_FIFO_DEPTH           ),
        .WRITE_DATA_WIDTH     ( C_M_AXI_DATA_WIDTH         ),
        .WR_DATA_COUNT_WIDTH  ( $clog2(LP_RD_FIFO_DEPTH)+1 ),
        .PROG_FULL_THRESH     ( LP_AXI_BURST_LEN-2         ),
        .FULL_RESET_VALUE     ( 1                          ),
        .READ_MODE            ( "fwft"                     ),
        .FIFO_READ_LATENCY    ( 1                          ),
        .READ_DATA_WIDTH      ( C_M_AXI_DATA_WIDTH         ),
        .RD_DATA_COUNT_WIDTH  ( $clog2(LP_RD_FIFO_DEPTH)+1 ),
        .PROG_EMPTY_THRESH    ( 10                         ),
        .DOUT_RESET_VALUE     ( "0"                        ),
        .CDC_SYNC_STAGES      ( 3                          ),
        .WAKEUP_TIME          ( 0                          )
    ) xpm_fifo_async_inst (
        .rst           ( ~data_rst_n     ),
        .wr_clk        ( data_clk        ),
        .prog_full     ( fifo_full       ),
        .wr_en         ( fifo_tvalid     ),
        .din           ( fifo_tdata      ),
        .full          ( fifo_tready_n   ),
        .rd_clk        ( m_axis_aclk     ),
        .rd_en         ( m_axis_tready   ),
        .dout          ( m_axis_tdata    ),
        .empty         ( fifo_empty      ),
        .prog_empty    (                 ),
        .underflow     (                 ),
        .wr_rst_busy   (                 ),
        .rd_rst_busy   (                 ),
        .wr_data_count (                 ),
        .rd_data_count (                 ),
        .overflow      (                 ),
        .sleep         ( 1'b0            ),
        .injectsbiterr ( 1'b0            ),
        .injectdbiterr ( 1'b0            ),
        .sbiterr       (                 ),
        .dbiterr       (                 )
    );

    ///////////////////////////////////////////////////////////////////////////
    // FIFO EMPTY SIGNAL GENERATION
    ///////////////////////////////////////////////////////////////////////////

    always@(posedge m_axis_aclk) begin
        if (~m_axis_areset_n) begin
            fifo_rd_count <= 1'b1;
        end
        else begin
            if (fifo_done == 1'b1) begin
                fifo_rd_count <= 1'b1;
            end
            else if ((m_axis_tvalid && m_axis_tready) == 1'b1) begin
                fifo_rd_count <= fifo_rd_count + 1'b1;
            end
        end
    end

    // AXI stream to user core
    assign m_axis_tvalid = ~fifo_empty;
    assign m_axis_tlast  = (fifo_rd_count == axim_length_axisclk);
    assign fifo_done     = m_axis_tvalid & m_axis_tready & (fifo_rd_count == axim_length_axisclk);

    ///////////////////////////////////////////////////////////////////////////
    // CDC
    ///////////////////////////////////////////////////////////////////////////

    xpm_cdc_pulse #(
        .DEST_SYNC_FF   ( 3 ),
        .INIT_SYNC_FF   ( 0 ),
        .REG_OUTPUT     ( 0 ),
        .RST_USED       ( 0 ),
        .SIM_ASSERT_CHK ( 0 )
    )
    inst_query_done_dataclk (
        .dest_pulse     ( fifo_done_dataclk ),
        .dest_clk       ( data_clk          ),
        .src_clk        ( m_axis_aclk       ),
        .src_pulse      ( fifo_done         )
    );

    xpm_cdc_array_single #(
        .DEST_SYNC_FF   ( 3 ),
        .INIT_SYNC_FF   ( 0 ),
        .SIM_ASSERT_CHK ( 0 ),
        .SRC_INPUT_REG  ( 1 ),
        .WIDTH          ( 1 )
    ) cdc_m_axis_ttype_dataclk (
        .dest_out       ( m_axis_ttype         ),
        .dest_clk       ( m_axis_aclk          ),
        .src_clk        ( data_clk             ),
        .src_in         ( m_axis_ttype_dataclk )
    );

    xpm_cdc_array_single #(
        .DEST_SYNC_FF   ( 3 ),
        .INIT_SYNC_FF   ( 0 ),
        .SIM_ASSERT_CHK ( 0 ),
        .SRC_INPUT_REG  ( 1 ),
        .WIDTH          ( 1 )
    ) cdc_axim_done_axisclk (
        .dest_out       ( axim_done_axisclk ),
        .dest_clk       ( m_axis_aclk       ),
        .src_clk        ( data_clk          ),
        .src_in         ( axim_done         )
    );

    xpm_cdc_array_single #(
        .DEST_SYNC_FF   ( 3 ),
        .INIT_SYNC_FF   ( 0 ),
        .SIM_ASSERT_CHK ( 0 ),
        .SRC_INPUT_REG  ( 1 ),
        .WIDTH          ( C_M_AXI_ADDR_WIDTH )
    ) cdc_axim_length_axisclk (
        .dest_out       ( axim_length_axisclk ),
        .dest_clk       ( m_axis_aclk         ),
        .src_clk        ( data_clk            ),
        .src_in         ( axim_length         )
    );
    

endmodule

`default_nettype wire