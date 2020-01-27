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
reg  [1:0]                           reader_state;
reg  [1:0]                           nxt_reader_state;

reg  [64-1:0]                        nfa_hash_r;
wire                                 nfa_reload;
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
                 WAIT_ALL_EDGES = 2'b10,
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
      IDLE           : nxt_reader_state = (ap_start_pulse) ? ((nfa_reload) ? READ_NFA : WAIT_ALL_EDGES) : IDLE;
      READ_NFA       : nxt_reader_state = (inputs_stream_tlast & inputs_stream_tready & inputs_stream_tvalid) ? WAIT_ALL_EDGES : READ_NFA;
      WAIT_ALL_EDGES : nxt_reader_state = READ_QUERY;
      READ_QUERY     : nxt_reader_state = (inputs_stream_tlast & inputs_stream_tready & inputs_stream_tvalid) ? IDLE           : READ_QUERY;
      default        : nxt_reader_state = IDLE;
    endcase
end

assign inputs_stream_ttype = (reader_state == READ_NFA) ? 1'b0          : 1'b1;


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
  .clk_i                    ( data_clk              ), // kernel_clk
  .rst_i                    ( data_rst_n            ), // kernel_rst_n
  .stats_on_i               ( 1'b0                  ),
  // input
  .rd_data_i                ( inputs_stream_tdata   ),
  .rd_valid_i               ( inputs_stream_tvalid  ),
  .rd_last_i                ( inputs_stream_tlast   ),
  .rd_stype_i               ( inputs_stream_ttype   ),
  .rd_ready_o               ( inputs_stream_tready  ),
  // output
  .wr_data_o                ( results_stream_tdata  ),
  .wr_valid_o               ( results_stream_tvalid ),
  .wr_last_o                ( results_stream_tlast  ),
  .wr_ready_i               ( results_stream_tready )
);

assign results_stream_tkeep = {C_INPUTS_STREAM_TDATA_WIDTH/8-1{1'b1}};

// inputs_stream_tkeep

endmodule : ederah_kernel
`default_nettype wire