// default_nettype of none prevents implicit wire declaration.
`default_nettype none
module ederah_kernel #(
  parameter integer C_M00_AXI_ADDR_WIDTH = 64 ,
  parameter integer C_M00_AXI_DATA_WIDTH = 512
)
(
  // System Signals
  input  wire                              data_clk       ,
  input  wire                              data_rst_n     ,
  input  wire                              kernel_clk     ,
  input  wire                              kernel_rst_n   ,
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
  input  wire [32-1:0]                     nfadata_cls    ,
  input  wire [32-1:0]                     queries_cls    ,
  input  wire [32-1:0]                     results_cls    ,
  input  wire [32-1:0]                     scalar03       , // stats_on
  input  wire [64-1:0]                     nfa_hash       ,
  input  wire [64-1:0]                     nfadata_ptr    ,
  input  wire [64-1:0]                     queries_ptr    ,
  input  wire [64-1:0]                     results_ptr    ,
  input  wire [64-1:0]                     axi00_ptr3
);


timeunit 1ps;
timeprecision 1ps;

////////////////////////////////////////////////////////////////////////////////////////////////////
// Local Parameters                                                                               //
////////////////////////////////////////////////////////////////////////////////////////////////////
// Large enough for interesting traffic.
localparam integer  LP_DEFAULT_LENGTH_IN_BYTES = 16384;

////////////////////////////////////////////////////////////////////////////////////////////////////
// Wires and Variables                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////
logic                           ap_start_r                     = 1'b0;
logic                           ap_idle_r                      = 1'b1;
logic                           ap_start_pulse                ;
logic                           ap_done_i                     ;
logic                           ap_done_r                      = 1'b0;
logic [32-1:0]                  ctrl_xfer_size_in_bytes        = LP_DEFAULT_LENGTH_IN_BYTES;
logic [32-1:0]                  ctrl_constant                  = 32'd1;

reg [32-1:0]                    queries_cls_dlay;
reg [32-1:0]                    nfadata_cls_dlay;

wire                            wr_tvalid;
wire                            wr_tready;
wire [C_M00_AXI_DATA_WIDTH-1:0] wr_tdata;

wire                            rd_tvalid;
wire                            rd_ttype;
wire                            rd_tlast;
wire                            rd_tready;
wire [C_M00_AXI_DATA_WIDTH-1:0] rd_tdata;

logic                           write_done;
logic                           read_done;

////////////////////////////////////////////////////////////////////////////////////////////////////
// Begin RTL                                                                                      //
////////////////////////////////////////////////////////////////////////////////////////////////////

always @(posedge data_clk) begin
  ap_start_r <= ap_start;
end

assign ap_start_pulse = ap_start & ~ap_start_r;

// ap_idle is asserted when done is asserted, it is de-asserted when ap_start_pulse is asserted
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

assign ap_done_i = write_done;


always @(posedge data_clk) begin
  queries_cls_dlay <= queries_cls;
  nfadata_cls_dlay <= nfadata_cls;
end

////////////////////////////////////////////////////////////////////////////////////////////////////
// Input Channel                                                                                  //
////////////////////////////////////////////////////////////////////////////////////////////////////

// AXI4 Read Master, output format is an AXI4-Stream master, one stream per thread.
InputChannel #(
  .C_M_AXI_ADDR_WIDTH       ( C_M00_AXI_ADDR_WIDTH ),
  .C_M_AXI_DATA_WIDTH       ( C_M00_AXI_DATA_WIDTH ),
  .C_XFER_SIZE_WIDTH        (                   32 ),
  .C_MAX_OUTSTANDING        (                   16 ),
  .C_INCLUDE_QUERY_FIFO     (                    1 )
)
inst_InputChannel (
  .data_clk                 ( data_clk             ),
  .data_rst_n               ( data_rst_n           ),
  .ctrl_start               ( ap_start_pulse       ),
  .ctrl_done                ( read_done            ),
  .nfa_hash                 ( nfa_hash             ),
  .nfadata_ptr              ( nfadata_ptr          ),
  .nfa_xfer_size_in_bytes   ( (nfadata_cls_dlay << 6) ),
  .queries_ptr              ( queries_ptr          ),
  .query_xfer_size_in_bytes ( (queries_cls_dlay << 6) ),
  .m_axi_arvalid            ( m00_axi_arvalid      ),
  .m_axi_arready            ( m00_axi_arready      ),
  .m_axi_araddr             ( m00_axi_araddr       ),
  .m_axi_arlen              ( m00_axi_arlen        ),
  .m_axi_rvalid             ( m00_axi_rvalid       ),
  .m_axi_rready             ( m00_axi_rready       ),
  .m_axi_rdata              ( m00_axi_rdata        ),
  .m_axi_rlast              ( m00_axi_rlast        ),
  .m_axis_aclk              ( kernel_clk           ),
  .m_axis_areset_n          ( kernel_rst_n         ),
  .m_axis_tvalid            ( rd_tvalid            ),
  .m_axis_tready            ( rd_tready            ),
  .m_axis_tlast             ( rd_tlast             ),
  .m_axis_tdata             ( rd_tdata             ),
  .m_axis_ttype             ( rd_ttype             )
);

////////////////////////////////////////////////////////////////////////////////////////////////////
// EDERAH Engine Core                                                                             //
////////////////////////////////////////////////////////////////////////////////////////////////////

ederah_wrapper #(
  .G_DATA_BUS_WIDTH         ( C_M00_AXI_DATA_WIDTH )
)
inst_wrapper (
  .clk_i                    ( kernel_clk           ),
  .rst_i                    ( kernel_rst_n         ),
  .stats_on_i               ( |scalar03            ),
  // input
  .rd_data_i                ( rd_tdata             ),
  .rd_valid_i               ( rd_tvalid            ),
  .rd_last_i                ( rd_tlast             ),
  .rd_stype_i               ( rd_ttype             ),
  .rd_ready_o               ( rd_tready            ),
  // output
  .wr_data_o                ( wr_tdata             ),
  .wr_valid_o               ( wr_tvalid            ),
  .wr_ready_i               ( wr_tready            )
);

////////////////////////////////////////////////////////////////////////////////////////////////////
// Output Channel                                                                                 //
////////////////////////////////////////////////////////////////////////////////////////////////////

// AXI4 Write Master
xdma_axi_write_master #(
  .C_M_AXI_ADDR_WIDTH      ( C_M00_AXI_ADDR_WIDTH    ),
  .C_M_AXI_DATA_WIDTH      ( C_M00_AXI_DATA_WIDTH    ),
  .C_XFER_SIZE_WIDTH       (                   32    ),
  .C_MAX_OUTSTANDING       (                   16    ),
  .C_INCLUDE_DATA_FIFO     (                    1    )
)
inst_axi_write_master (
  .aclk                    ( data_clk                ),
  .areset                  ( ~data_rst_n             ),
  .ctrl_start              ( ap_start_pulse          ),
  .ctrl_done               ( write_done              ),
  .ctrl_addr_offset        ( results_ptr             ),
  .ctrl_xfer_size_in_bytes ( {(results_cls << 6)}    ),
  .m_axi_awvalid           ( m00_axi_awvalid         ),
  .m_axi_awready           ( m00_axi_awready         ),
  .m_axi_awaddr            ( m00_axi_awaddr          ),
  .m_axi_awlen             ( m00_axi_awlen           ),
  .m_axi_wvalid            ( m00_axi_wvalid          ),
  .m_axi_wready            ( m00_axi_wready          ),
  .m_axi_wdata             ( m00_axi_wdata           ),
  .m_axi_wstrb             ( m00_axi_wstrb           ),
  .m_axi_wlast             ( m00_axi_wlast           ),
  .m_axi_bvalid            ( m00_axi_bvalid          ),
  .m_axi_bready            ( m00_axi_bready          ),
  .s_axis_aclk             ( kernel_clk              ),
  .s_axis_areset           ( ~kernel_rst_n           ),
  .s_axis_tvalid           ( wr_tvalid               ),
  .s_axis_tready           ( wr_tready               ),
  .s_axis_tdata            ( wr_tdata                )
);

endmodule : ederah_kernel
`default_nettype wire