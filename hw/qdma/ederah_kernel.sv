// This is a generated file. Use and modify at your own risk.
//////////////////////////////////////////////////////////////////////////////// 
// default_nettype of none prevents implicit wire declaration.
`default_nettype none
module ederah_kernel #(
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

///////////////////////////////////////////////////////////////////////////////
// Local Parameters
///////////////////////////////////////////////////////////////////////////////
// Large enough for interesting traffic.
localparam integer  LP_DEFAULT_LENGTH_IN_BYTES = 16384;

///////////////////////////////////////////////////////////////////////////////
// Wires and Variables
///////////////////////////////////////////////////////////////////////////////
(* KEEP = "yes" *)
logic                                kernel_rst                     = 1'b0;
logic                                ap_start_r                     = 1'b0;
logic                                ap_idle_r                      = 1'b1;
logic                                ap_start_pulse                ;
logic                                ap_done_i                     ;
logic                                ap_done_r                      = 1'b0;
logic [32-1:0]                       ctrl_xfer_size_in_bytes        = LP_DEFAULT_LENGTH_IN_BYTES;
logic [32-1:0]                       ctrl_constant                  = 32'd1;
//
wire                                 inputs_stream_ttype;
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
//
reg  [1:0]                           reader_state;
reg  [1:0]                           nxt_reader_state;

reg  [64-1:0]                        nfa_hash_r;
wire                                 nfa_reload;
wire                                 inputs_stream_tvalid_krl;
//

///////////////////////////////////////////////////////////////////////////////
// Begin RTL
///////////////////////////////////////////////////////////////////////////////

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

assign ap_done_i = results_stream_tlast;

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
// EDERAH Engine Core                                                                             //
////////////////////////////////////////////////////////////////////////////////////////////////////

ederah_wrapper #(
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
  .CDC_SYNC_STAGES     ( 3                      ) , // DECIMAL
  .CLOCKING_MODE       ( "independent_clock"    ) , // String
  .ECC_MODE            ( "no_ecc"               ) , // String
  .FIFO_DEPTH          ( 32                     ) , // DECIMAL
  .FIFO_MEMORY_TYPE    ( "auto"                 ) , // String
  .PACKET_FIFO         ( "false"                ) , // String
  .PROG_EMPTY_THRESH   ( 5                      ) , // DECIMAL
  .PROG_FULL_THRESH    ( 32-5                   ) , // DECIMAL
  .RD_DATA_COUNT_WIDTH ( 6                      ) , // DECIMAL
  .RELATED_CLOCKS      ( 0                      ) , // DECIMAL
  .TDATA_WIDTH         ( C_INPUTS_STREAM_TDATA_WIDTH ) , // DECIMAL
  .TDEST_WIDTH         ( 1                      ) , // DECIMAL
  .TID_WIDTH           ( 1                      ) , // DECIMAL
  .TUSER_WIDTH         ( 1                      ) , // DECIMAL
  .USE_ADV_FEATURES    ( "1000"                 ) , // String
  .WR_DATA_COUNT_WIDTH ( 6                      )   // DECIMAL
)
inst_xpm_fifo_axis_inputs (
  .s_aclk             ( data_clk                 ) ,
  .s_aresetn          ( data_rst_n               ) , // Keep tready low when not active
  .s_axis_tvalid      ( inputs_stream_tvalid_krl ) ,
  .s_axis_tready      ( inputs_stream_tready     ) ,
  .s_axis_tdata       ( inputs_stream_tdata      ) ,
  .s_axis_tstrb       ( 'b1                      ) ,
  .s_axis_tkeep       ( inputs_stream_tkeep      ) ,
  .s_axis_tlast       ( inputs_stream_tlast      ) ,
  .s_axis_tid         ( 'b0                      ) ,
  .s_axis_tdest       ( 'b0                      ) ,
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

xpm_fifo_axis #(
  .CDC_SYNC_STAGES     ( 3                      ) , // DECIMAL
  .CLOCKING_MODE       ( "independent_clock"    ) , // String
  .ECC_MODE            ( "no_ecc"               ) , // String
  .FIFO_DEPTH          ( 32                     ) , // DECIMAL
  .FIFO_MEMORY_TYPE    ( "auto"                 ) , // String
  .PACKET_FIFO         ( "false"                ) , // String
  .PROG_EMPTY_THRESH   ( 5                      ) , // DECIMAL
  .PROG_FULL_THRESH    ( 32-5                   ) , // DECIMAL
  .RD_DATA_COUNT_WIDTH ( 6                      ) , // DECIMAL
  .RELATED_CLOCKS      ( 0                      ) , // DECIMAL
  .TDATA_WIDTH         ( C_INPUTS_STREAM_TDATA_WIDTH ) , // DECIMAL
  .TDEST_WIDTH         ( 1                      ) , // DECIMAL
  .TID_WIDTH           ( 1                      ) , // DECIMAL
  .TUSER_WIDTH         ( 1                      ) , // DECIMAL
  .USE_ADV_FEATURES    ( "1000"                 ) , // String
  .WR_DATA_COUNT_WIDTH ( 6                      )   // DECIMAL
)
inst_xpm_fifo_axis_results (
  .s_aclk             ( kernel_clk                ) ,
  .s_aresetn          ( kernel_rst_n              ) , // Keep tready low when not active
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

endmodule : ederah_kernel
`default_nettype wire