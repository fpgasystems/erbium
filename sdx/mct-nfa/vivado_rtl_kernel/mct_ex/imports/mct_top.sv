// This is a generated file. Use and modify at your own risk.
//////////////////////////////////////////////////////////////////////////////// 
// default_nettype of none prevents implicit wire declaration.
`default_nettype none
module mct_top #(
  parameter integer C_M00_AXI_ADDR_WIDTH = 64 ,
  parameter integer C_M00_AXI_DATA_WIDTH = 512
)
(
  // System Signals
  input  wire                              ap_clk         ,
  input  wire                              ap_rst_n       ,
  // AXI4 master interface m00_axi
  output wire                              m00_axi_awvalid,
  input  wire                              m00_axi_awready,
  output wire [C_M00_AXI_ADDR_WIDTH-1:0]   m00_axi_awaddr ,
  output wire [8-1:0]                      m00_axi_awlen  ,
  output wire                              m00_axi_wvalid ,
  input  wire                              m00_axi_wready ,
  output wire [C_M00_AXI_DATA_WIDTH-1:0]   m00_axi_wdata  ,
  output wire [C_M00_AXI_DATA_WIDTH/8-1:0] m00_axi_wstrb  ,
  output wire                              m00_axi_wlast  ,
  input  wire                              m00_axi_bvalid ,
  output wire                              m00_axi_bready ,
  output wire                              m00_axi_arvalid,
  input  wire                              m00_axi_arready,
  output wire [C_M00_AXI_ADDR_WIDTH-1:0]   m00_axi_araddr ,
  output wire [8-1:0]                      m00_axi_arlen  ,
  input  wire                              m00_axi_rvalid ,
  output wire                              m00_axi_rready ,
  input  wire [C_M00_AXI_DATA_WIDTH-1:0]   m00_axi_rdata  ,
  input  wire                              m00_axi_rlast  ,
  // SDx Control Signals
  input  wire                              ap_start       ,
  output wire                              ap_idle        ,
  output wire                              ap_done        ,
  input  wire [8-1:0]                      numCriteria    ,
  input  wire [32-1:0]                     queriesNumCLs  ,
  input  wire [32-1:0]                     edgesNumCLs    ,
  input  wire [32-1:0]                     resultNumCLs   ,
  input  wire [32-1:0]                     extraParam1    ,
  input  wire [32-1:0]                     extraParam2    ,
  input  wire [64-1:0]                     nfaPtr         ,
  input  wire [64-1:0]                     queryPtr       ,
  input  wire [64-1:0]                     resultPtr      
);


timeunit 1ps;
timeprecision 1ps;

///////////////////////////////////////////////////////////////////////////////
// Local Parameters
///////////////////////////////////////////////////////////////////////////////
// Large enough for interesting traffic.
localparam integer  LP_DEFAULT_LENGTH_IN_BYTES = 16384;
localparam integer  LP_NUM_EXAMPLES    = 1;

///////////////////////////////////////////////////////////////////////////////
// Wires and Variables
///////////////////////////////////////////////////////////////////////////////
logic                                rst_n                          = 1'b0;
logic                                ap_start_r                     = 1'b0;
logic                                ap_idle_r                      = 1'b0;
logic                                ap_start_pulse_d1              = 1'b0;
logic                                ap_start_pulse                ;
logic                                ap_done_i                     ;
logic                                ap_done_r                      = 1'b0;
logic [32-1:0]                       ctrl_xfer_size_in_bytes        = LP_DEFAULT_LENGTH_IN_BYTES;
logic [32-1:0]                       ctrl_constant                  = 32'd1;

wire                                 wr_tvalid;
wire                                 wr_tready;
wire   [C_M00_AXI_DATA_WIDTH-1:0]    wr_tdata;

wire                                 rd_tvalid;
wire                                 rd_ttype;
wire                                 rd_tlast;
wire                                 rd_tready;
wire   [C_M00_AXI_DATA_WIDTH-1:0]    rd_tdata;


logic [16-1:0]                     num_words_per_tuple;
logic [16-1:0]                     num_64bit_words_per_tuple;
logic [8-1:0]                      tree_depth;
logic [8-1:0]                      num_trees_per_pu_minus_one;
logic [32-1:0]                     total_trees_numcls_minus_one;
logic [32-1:0]                     total_trees_numcls;
logic [32-1:0]                     total_tuples_numcls_minus_one;
logic [32-1:0]                     total_output_numcls;
logic [32-1:0]                     total_output_numcls_minus_one;
logic [16-1:0]                     last_result_line_mask;

logic                              write_done;
logic                              read_done;
///////////////////////////////////////////////////////////////////////////////
// Begin RTL
///////////////////////////////////////////////////////////////////////////////

// Register and invert reset signal.
always @(posedge ap_clk) begin
  rst_n             <= ap_rst_n;
  ap_start_r        <= ap_start;
  ap_start_pulse_d1 <= ap_start_pulse;
end

assign ap_start_pulse = ap_start & ~ap_start_r;

// ap_idle is asserted when done is asserted, it is de-asserted when ap_start_pulse
// is asserted
always @(posedge ap_clk) begin
  if (!rst_n) begin
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

////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////                            //////////////////////////////////
//////////////////////////////                Input Channel                /////////////////////////
//////////////////////////////////////                            //////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////

// AXI4 Read Master, output format is an AXI4-Stream master, one stream per thread.
InputChannel #(
  .C_M_AXI_ADDR_WIDTH   ( C_M00_AXI_ADDR_WIDTH    ) ,
  .C_M_AXI_query_WIDTH  ( C_M00_AXI_DATA_WIDTH    ) ,
  .C_XFER_SIZE_WIDTH    ( 32                      ) ,
  .C_MAX_OUTSTANDING    ( 16                      ) ,
  .C_INCLUDE_query_FIFO ( 1                       )
)
inst_InputChannel (
  .clk                     ( ap_clk                  ) ,
  .rst_n                   ( rst_n                   ) ,
  .ctrl_start              ( ap_start_pulse          ) ,
  .ctrl_done               ( read_done               ) ,
  .nfaPtr                  ( nfaPtr                  ) ,
  .nfa_xfer_size_in_bytes  ( (edgesNumCLs << 6)      ) ,
  .queryPtr                ( queryPtr                ) ,
  .query_xfer_size_in_bytes( (queriesNumCLs << 6)    ) ,
  .m_axi_arvalid           ( m00_axi_arvalid         ) ,
  .m_axi_arready           ( m00_axi_arready         ) ,
  .m_axi_araddr            ( m00_axi_araddr          ) ,
  .m_axi_arlen             ( m00_axi_arlen           ) ,
  .m_axi_rvalid            ( m00_axi_rvalid          ) ,
  .m_axi_rready            ( m00_axi_rready          ) ,
  .m_axi_rdata             ( m00_axi_rdata           ) ,
  .m_axi_rlast             ( m00_axi_rlast           ) ,
  .m_axis_aclk             ( ap_clk                  ) ,
  .m_axis_areset           ( rst_n                   ) ,
  .m_axis_tvalid           ( rd_tvalid               ) ,
  .m_axis_tready           ( rd_tready               ) ,
  .m_axis_tlast            ( rd_tlast                ) ,
  .m_axis_tdata            ( rd_tdata                ) , 
  .m_axis_ttype            ( rd_ttype                )
);

////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////                            //////////////////////////////////
//////////////////////////////                 Engine Core                 /////////////////////////
//////////////////////////////////////                            //////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////


mct_wrapper mct_wrapper(
  .clk_i                          (ap_clk),
  .rst_i                          (~rst_n),
  
  // input
  .rd_data_i                      (rd_tdata),
  .rd_valid_i                     (rd_tvalid),
  .rd_last_i                      (rd_tlast),
  .rd_stype_i                     (rd_ttype),
  .rd_ready_o                     (rd_tready),
  // output 
  .wr_data_o                      (wr_tdata),
  .wr_valid_o                     (wr_tvalid),
  .wr_ready_i                     (wr_tready)
);



////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////                            //////////////////////////////////
//////////////////////////////               Output Channel                /////////////////////////
//////////////////////////////////////                            //////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////

// AXI4 Write Master
mct_axi_write_master #(
  .C_M_AXI_ADDR_WIDTH  ( C_M00_AXI_ADDR_WIDTH    ) ,
  .C_M_AXI_DATA_WIDTH  ( C_M00_AXI_DATA_WIDTH    ) ,
  .C_XFER_SIZE_WIDTH   ( 32                      ) ,
  .C_MAX_OUTSTANDING   ( 16                      ) ,
  .C_INCLUDE_DATA_FIFO ( 1                       )
)
inst_axi_write_master (
  .aclk                    ( ap_clk                  ) ,
  .areset                  ( ~rst_n                  ) ,
  .ctrl_start              ( ap_start_pulse          ) ,
  .ctrl_done               ( write_done              ) ,
  .ctrl_addr_offset        ( resultPtr               ) ,
  .ctrl_xfer_size_in_bytes ( {(resultNumCLs << 6)}   ) ,
  .m_axi_awvalid           ( m00_axi_awvalid         ) ,
  .m_axi_awready           ( m00_axi_awready         ) ,
  .m_axi_awaddr            ( m00_axi_awaddr          ) ,
  .m_axi_awlen             ( m00_axi_awlen           ) ,
  .m_axi_wvalid            ( m00_axi_wvalid          ) ,
  .m_axi_wready            ( m00_axi_wready          ) ,
  .m_axi_wdata             ( m00_axi_wdata           ) ,
  .m_axi_wstrb             ( m00_axi_wstrb           ) ,
  .m_axi_wlast             ( m00_axi_wlast           ) ,
  .m_axi_bvalid            ( m00_axi_bvalid          ) ,
  .m_axi_bready            ( m00_axi_bready          ) ,
  .s_axis_aclk             ( ap_clk                  ) ,
  .s_axis_areset           ( ~rst_n                  ) ,
  .s_axis_tvalid           ( wr_tvalid               ) ,
  .s_axis_tready           ( wr_tready               ) ,
  .s_axis_tdata            ( wr_tdata                )
);

assign ap_done_i = write_done;
endmodule : mct_top
`default_nettype wire
