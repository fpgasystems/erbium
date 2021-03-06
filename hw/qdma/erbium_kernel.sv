////////////////////////////////////////////////////////////////////////////////////////////////////
//  ERBium - Business Rule Engine Hardware Accelerator
//  Copyright (C) 2020 Fabio Maschi - Systems Group, ETH Zurich

//  This program is free software: you can redistribute it and/or modify it under the terms of the
//  GNU Affero General Public License as published by the Free Software Foundation, either version 3
//  of the License, or (at your option) any later version.

//  This software is provided by the copyright holders and contributors "AS IS" and any express or
//  implied warranties, including, but not limited to, the implied warranties of merchantability and
//  fitness for a particular purpose are disclaimed. In no event shall the copyright holder or
//  contributors be liable for any direct, indirect, incidental, special, exemplary, or
//  consequential damages (including, but not limited to, procurement of substitute goods or
//  services; loss of use, data, or profits; or business interruption) however caused and on any
//  theory of liability, whether in contract, strict liability, or tort (including negligence or
//  otherwise) arising in any way out of the use of this software, even if advised of the 
//  possibility of such damage. See the GNU Affero General Public License for more details.

//  You should have received a copy of the GNU Affero General Public License along with this
//  program. If not, see <http://www.gnu.org/licenses/agpl-3.0.en.html>.
////////////////////////////////////////////////////////////////////////////////////////////////////

// default_nettype of none prevents implicit wire declaration.
`default_nettype none
module erbium_kernel #(
  parameter integer C_RESULTS_STREAM_TDATA_WIDTH = 512,
  parameter integer C_INPUTS_STREAM_TDATA_WIDTH  = 512
)
(
  // System Signals
  input  wire                                      data_clk             ,
  input  wire                                      data_rst_n           ,
  input  wire                                      kernel_clk           ,
  input  wire                                      kernel_rst_n         ,
  // Pipe (AXI4-Stream host) interface results_stream
  output wire                                      results_stream_tvalid,
  input  wire                                      results_stream_tready,
  output wire [C_RESULTS_STREAM_TDATA_WIDTH-1:0]   results_stream_tdata ,
  output wire [C_RESULTS_STREAM_TDATA_WIDTH/8-1:0] results_stream_tkeep ,
  output wire                                      results_stream_tlast ,
  // Pipe (AXI4-Stream host) interface inputs_stream
  input  wire                                      inputs_stream_tvalid ,
  output wire                                      inputs_stream_tready ,
  input  wire [C_INPUTS_STREAM_TDATA_WIDTH-1:0]    inputs_stream_tdata  ,
  input  wire [C_INPUTS_STREAM_TDATA_WIDTH/8-1:0]  inputs_stream_tkeep  ,
  input  wire                                      inputs_stream_tlast  ,
  // SDx Control Signals
  input  wire                                      ap_start             ,
  output wire                                      ap_idle              ,
  output wire                                      ap_done              ,
  output wire                                      ap_ready             ,
  input  wire [32-1:0]                             nfa_hash             
);

timeunit 1ps;
timeprecision 1ps;

////////////////////////////////////////////////////////////////////////////////////////////////////
// Wires and Variables
////////////////////////////////////////////////////////////////////////////////////////////////////
logic                                     ap_start_r                     = 1'b0;
logic                                     ap_idle_r                      = 1'b1;
logic                                     ap_start_pulse                ;
logic                                     ap_done_i                     ;
logic                                     ap_done_r                      = 1'b0;
logic                                     active_kernel_clk;
logic                                     active;
//
// Pipe (AXI4-Stream host) interface results_stream
wire                                      cdc_results_stream_tvalid;
wire                                      cdc_results_stream_tready;
wire [C_RESULTS_STREAM_TDATA_WIDTH-1:0]   cdc_results_stream_tdata ;
wire [C_RESULTS_STREAM_TDATA_WIDTH/8-1:0] cdc_results_stream_tkeep ;
wire                                      cdc_results_stream_tlast ;
// Pipe (AXI4-Stream host) interface inputs_stream
wire                                      cdc_inputs_stream_tvalid ;
wire                                      cdc_inputs_stream_tready ;
wire [C_INPUTS_STREAM_TDATA_WIDTH-1:0]    cdc_inputs_stream_tdata  ;
wire                                      cdc_inputs_stream_tlast  ;
wire                                      cdc_inputs_stream_ttype  ;
wire                                      inputs_stream_ttype;
wire                                      inputs_stream_tvalid_krl;
//
reg  [1:0]                                reader_state;
reg  [1:0]                                nxt_reader_state;
reg  [64-1:0]                             nfa_hash_r;
wire                                      nfa_reload;

////////////////////////////////////////////////////////////////////////////////////////////////////
// Begin RTL
////////////////////////////////////////////////////////////////////////////////////////////////////
assign active = ~ap_idle;

always @(posedge data_clk) begin
  ap_start_r <= ap_start;
end

assign ap_start_pulse = ap_start & ~ap_start_r;

always @(posedge data_clk) begin
  if (!data_rst_n) begin
    ap_idle_r <= 1'b1;
    ap_done_r <= 1'b0;
  end
  else begin
    ap_idle_r <= ap_done ? 1'b1 : ap_start_pulse ? 1'b0 : ap_idle;
    ap_done_r <= (ap_start_pulse | ap_done) ? 1'b0 : ap_done_r | ap_done_i;
  end
end

assign ap_idle = ap_idle_r;
assign ap_done = ap_done_r;

assign ap_done_i = results_stream_tlast & results_stream_tvalid & results_stream_tready;

assign ap_ready = ap_done;

////////////////////////////////////////////////////////////////////////////////////////////////////
// STATE MACHINE
////////////////////////////////////////////////////////////////////////////////////////////////////

localparam [1:0] IDLE           = 2'b00,
                 READ_NFA       = 2'b01,
                 READ_QUERY     = 2'b11;

// Reader State
always@(posedge data_clk) begin
  if (~data_rst_n) begin
    reader_state <= IDLE;
  end
  else begin
    reader_state <= nxt_reader_state;
  end
end

always@(*) begin
    case (reader_state)
      IDLE           : nxt_reader_state = (ap_start_pulse) ? ((nfa_reload) ? READ_NFA : READ_QUERY) : IDLE;
      READ_NFA       : nxt_reader_state = (inputs_stream_tlast & inputs_stream_tready & inputs_stream_tvalid) ? READ_QUERY : READ_NFA;
      READ_QUERY     : nxt_reader_state = (inputs_stream_tlast & inputs_stream_tready & inputs_stream_tvalid) ? IDLE       : READ_QUERY;
      default        : nxt_reader_state = IDLE;
    endcase
end

assign inputs_stream_ttype = (reader_state == READ_NFA) ? 1'b0 : 1'b1;

assign inputs_stream_tvalid_krl = (reader_state == IDLE) ? 1'b0 : inputs_stream_tvalid;

// NFA ID control
always@(posedge data_clk) begin
  if (~data_rst_n) begin
    nfa_hash_r <= 0;
  end
  else if (ap_start_pulse) begin
      nfa_hash_r <= nfa_hash;
  end
end

assign nfa_reload = (ap_start_pulse) && (nfa_hash !== nfa_hash_r);


////////////////////////////////////////////////////////////////////////////////////////////////////
// ERBIUM ENGINE WRAPPER                                                                          //
////////////////////////////////////////////////////////////////////////////////////////////////////

erbium_wrapper #(
  .G_DATA_BUS_WIDTH         ( C_RESULTS_STREAM_TDATA_WIDTH )
)
inst_wrapper (
  .clk_i                    ( kernel_clk            ),
  .rst_i                    ( kernel_rst_n          ),
  // input
  .rd_data_i                ( cdc_inputs_stream_tdata  ),
  .rd_valid_i               ( cdc_inputs_stream_tvalid ),
  .rd_last_i                ( cdc_inputs_stream_tlast  ),
  .rd_stype_i               ( cdc_inputs_stream_ttype  ),
  .rd_ready_o               ( cdc_inputs_stream_tready ),
  // output
  .wr_data_o                ( cdc_results_stream_tdata  ),
  .wr_valid_o               ( cdc_results_stream_tvalid ),
  .wr_last_o                ( cdc_results_stream_tlast  ),
  .wr_ready_i               ( cdc_results_stream_tready )
);

assign cdc_results_stream_tkeep = {C_INPUTS_STREAM_TDATA_WIDTH/8-1{1'b1}};

////////////////////////////////////////////////////////////////////////////////////////////////////
// CLOCK DOMAIN CROSSINGS                                                                         //
////////////////////////////////////////////////////////////////////////////////////////////////////

xpm_fifo_axis #(
  .CDC_SYNC_STAGES     ( 3                      ) ,
  .CLOCKING_MODE       ( "independent_clock"    ) ,
  .ECC_MODE            ( "no_ecc"               ) ,
  .FIFO_DEPTH          ( 32                     ) ,
  .FIFO_MEMORY_TYPE    ( "auto"                 ) ,
  .PACKET_FIFO         ( "false"                ) ,
  .PROG_EMPTY_THRESH   ( 5                      ) ,
  .PROG_FULL_THRESH    ( 32-5                   ) ,
  .RD_DATA_COUNT_WIDTH ( 6                      ) ,
  .RELATED_CLOCKS      ( 0                      ) ,
  .TDATA_WIDTH         ( C_INPUTS_STREAM_TDATA_WIDTH ) ,
  .TDEST_WIDTH         ( 1                      ) ,
  .TID_WIDTH           ( 1                      ) ,
  .TUSER_WIDTH         ( 1                      ) ,
  .USE_ADV_FEATURES    ( "1000"                 ) ,
  .WR_DATA_COUNT_WIDTH ( 6                      )
)
inst_xpm_fifo_axis_inputs (
  .s_aclk             ( data_clk                 ) ,
  .s_aresetn          ( active                   ) , // Keep tready low when not active
  .s_axis_tvalid      ( inputs_stream_tvalid_krl ) ,
  .s_axis_tready      ( inputs_stream_tready     ) ,
  .s_axis_tdata       ( inputs_stream_tdata      ) ,
  .s_axis_tstrb       ( 'b1                      ) ,
  .s_axis_tkeep       ( inputs_stream_tkeep      ) ,
  .s_axis_tlast       ( inputs_stream_tlast      ) ,
  .s_axis_tid         ( inputs_stream_ttype      ) ,
  .s_axis_tdest       ( inputs_stream_ttype      ) ,
  .s_axis_tuser       ( inputs_stream_ttype      ) ,
  .almost_full_axis   (                          ) ,
  .prog_full_axis     (                          ) ,
  .wr_data_count_axis (                          ) ,
  .injectdbiterr_axis ( 1'b0                     ) ,
  .injectsbiterr_axis ( 1'b0                     ) ,

  .m_aclk             ( kernel_clk               ) ,
  .m_axis_tvalid      ( cdc_inputs_stream_tvalid ) ,
  .m_axis_tready      ( cdc_inputs_stream_tready ) ,
  .m_axis_tdata       ( cdc_inputs_stream_tdata  ) ,
  .m_axis_tstrb       (                          ) ,
  .m_axis_tkeep       (                          ) ,
  .m_axis_tlast       ( cdc_inputs_stream_tlast  ) ,
  .m_axis_tid         (                          ) ,
  .m_axis_tdest       (                          ) ,
  .m_axis_tuser       ( cdc_inputs_stream_ttype  ) ,
  .almost_empty_axis  (                          ) ,
  .prog_empty_axis    (                          ) ,
  .rd_data_count_axis (                          ) ,
  .sbiterr_axis       (                          ) ,
  .dbiterr_axis       (                          )
);

xpm_cdc_single #(
  .DEST_SYNC_FF        ( 3                 ) ,
  .INIT_SYNC_FF        ( 0                 ) ,
  .SRC_INPUT_REG       ( 1                 ) ,
  .SIM_ASSERT_CHK      ( 1                 )
)
inst_active_kernel_clk (
  .src_in              ( active            ) ,
  .src_clk             ( data_clk          ) ,
  .dest_out            ( active_kernel_clk ) ,
  .dest_clk            ( kernel_clk        )
);

xpm_fifo_axis #(
  .CDC_SYNC_STAGES     ( 3                      ) ,
  .CLOCKING_MODE       ( "independent_clock"    ) ,
  .ECC_MODE            ( "no_ecc"               ) ,
  .FIFO_DEPTH          ( 32                     ) ,
  .FIFO_MEMORY_TYPE    ( "auto"                 ) ,
  .PACKET_FIFO         ( "false"                ) ,
  .PROG_EMPTY_THRESH   ( 5                      ) ,
  .PROG_FULL_THRESH    ( 32-5                   ) ,
  .RD_DATA_COUNT_WIDTH ( 6                      ) ,
  .RELATED_CLOCKS      ( 0                      ) ,
  .TDATA_WIDTH         ( C_INPUTS_STREAM_TDATA_WIDTH ) ,
  .TDEST_WIDTH         ( 1                      ) ,
  .TID_WIDTH           ( 1                      ) ,
  .TUSER_WIDTH         ( 1                      ) ,
  .USE_ADV_FEATURES    ( "1000"                 ) ,
  .WR_DATA_COUNT_WIDTH ( 6                      )
)
inst_xpm_fifo_axis_results (
  .s_aclk             ( kernel_clk                ) ,
  .s_aresetn          ( active_kernel_clk         ) , // Keep tready low when not active
  .s_axis_tvalid      ( cdc_results_stream_tvalid ) ,
  .s_axis_tready      ( cdc_results_stream_tready ) ,
  .s_axis_tdata       ( cdc_results_stream_tdata  ) ,
  .s_axis_tstrb       ( 'b1                       ) ,
  .s_axis_tkeep       ( cdc_results_stream_tkeep  ) ,
  .s_axis_tlast       ( cdc_results_stream_tlast  ) ,
  .s_axis_tid         ( 'b0                       ) ,
  .s_axis_tdest       ( 'b0                       ) ,
  .s_axis_tuser       ( 'b0                       ) ,
  .almost_full_axis   (                           ) ,
  .prog_full_axis     (                           ) ,
  .wr_data_count_axis (                           ) ,
  .injectdbiterr_axis ( 1'b0                      ) ,
  .injectsbiterr_axis ( 1'b0                      ) ,

  .m_aclk             ( data_clk                  ) ,
  .m_axis_tvalid      ( results_stream_tvalid     ) ,
  .m_axis_tready      ( results_stream_tready     ) ,
  .m_axis_tdata       ( results_stream_tdata      ) ,
  .m_axis_tstrb       (                           ) ,
  .m_axis_tkeep       ( results_stream_tkeep      ) ,
  .m_axis_tlast       ( results_stream_tlast      ) ,
  .m_axis_tid         (                           ) ,
  .m_axis_tdest       (                           ) ,
  .m_axis_tuser       (                           ) ,
  .almost_empty_axis  (                           ) ,
  .prog_empty_axis    (                           ) ,
  .rd_data_count_axis (                           ) ,
  .sbiterr_axis       (                           ) ,
  .dbiterr_axis       (                           )
);

endmodule : erbium_kernel
`default_nettype wire