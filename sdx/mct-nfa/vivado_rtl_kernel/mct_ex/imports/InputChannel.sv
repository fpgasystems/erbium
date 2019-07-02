

module InputChannel #(
  // Set to the address width of the interface
  parameter integer C_M_AXI_ADDR_WIDTH  = 64,

  // Set the data width of the interface
  // Range: 32, 64, 128, 256, 512, 1024
  parameter integer C_M_AXI_query_WIDTH  = 32,

  // Width of the ctrl_xfer_size_in_bytes input
  // Range: 16:C_M_AXI_ADDR_WIDTH
  parameter integer C_XFER_SIZE_WIDTH   = C_M_AXI_ADDR_WIDTH,

  // Specifies the maximum number of AXI4 transactions that may be outstanding.
  // Affects FIFO depth if data FIFO is enabled.
  parameter integer C_MAX_OUTSTANDING   = 16,

  // Includes a data fifo between the AXI4 read channel master and the AXI4-Stream
  // master.  It will be sized to hold C_MAX_OUTSTANDING transactions. If no
  // FIFO is instantiated then the AXI4 read channel is passed through to the
  // AXI4-Stream slave interface.
  // Range: 0, 1
  parameter integer C_INCLUDE_query_FIFO = 1
)
(
  // System signals
  input  wire                          clk,
  input  wire                          rst_n,

  // Control signals
  input  wire                          ctrl_start,              // Pulse high for one cycle to begin reading
  output wire                          ctrl_done,               // Pulses high for one cycle when transfer request is complete

  // The following ctrl signals are sampled when ctrl_start is asserted
  input  wire [C_M_AXI_ADDR_WIDTH-1:0] nfaPtr,        // Starting Address offset
  input  wire [C_XFER_SIZE_WIDTH-1:0]  nfa_xfer_size_in_bytes, // Length in number of bytes, limited by the address width.
  
  input  wire [C_M_AXI_ADDR_WIDTH-1:0] queryPtr,        // Starting Address offset
  input  wire [C_XFER_SIZE_WIDTH-1:0]  query_xfer_size_in_bytes, // Length in number of bytes, limited by the address width.

  // AXI4 master interface (read only)
  output wire                          m_axi_arvalid,
  input  wire                          m_axi_arready,
  output wire [C_M_AXI_ADDR_WIDTH-1:0] m_axi_araddr,
  output wire [8-1:0]                  m_axi_arlen,

  input  wire                          m_axi_rvalid,
  output wire                          m_axi_rready,
  input  wire [C_M_AXI_query_WIDTH-1:0] m_axi_rdata,
  input  wire                          m_axi_rlast,

  // AXI4-Stream master interface
  input  wire                          m_axis_aclk,
  input  wire                          m_axis_areset,
  output wire                          m_axis_tvalid,
  input  wire                          m_axis_tready,
  output wire [C_M_AXI_query_WIDTH-1:0] m_axis_tdata,
  output wire                          m_axis_tlast, 
  output wire                          m_axis_ttype
);

///////////////////////////////////////////////////////////////////////////////
// Local Parameters
///////////////////////////////////////////////////////////////////////////////
localparam integer LP_DW_BYTES             = C_M_AXI_query_WIDTH/8;
localparam integer LP_AXI_BURST_LEN        = 4096/LP_DW_BYTES < 256 ? 4096/LP_DW_BYTES : 256;
localparam integer LP_LOG_BURST_LEN        = $clog2(LP_AXI_BURST_LEN);
localparam integer LP_BRAM_DEPTH           = 512;
localparam integer LP_RD_MAX_OUTSTANDING   = LP_BRAM_DEPTH / LP_AXI_BURST_LEN;
localparam integer LP_WR_MAX_OUTSTANDING   = 32;

localparam [1:0] IDLE           = 2'b00, 
				 READ_NFA     = 2'b01, 
				 WAIT_ALL_EDGES = 2'b10, 
				 READ_QUERY      = 2'b11;

///////////////////////////////////////////////////////////////////////////////
// Variables
///////////////////////////////////////////////////////////////////////////////
// AXI4 master interface (read only)
wire                          nfa_m_axi_arvalid;
wire                          nfa_m_axi_arready;
wire [C_M_AXI_ADDR_WIDTH-1:0] nfa_m_axi_araddr;
wire [8-1:0]                  nfa_m_axi_arlen;

wire                          nfa_m_axi_rvalid;
wire                          nfa_m_axi_rready;
wire [C_M_AXI_query_WIDTH-1:0] nfa_m_axi_rdata;
wire                          nfa_m_axi_rlast;

// AXI4-Stream master interface
wire                          nfa_rd_tvalid;
wire                          nfa_rd_tready;
wire                          nfa_rd_tlast;
wire [511:0]                  nfa_rd_tdata;

// AXI4 master interface (read only)
wire                          query_m_axi_arvalid;
wire                          query_m_axi_arready;
wire [C_M_AXI_ADDR_WIDTH-1:0] query_m_axi_araddr;
wire [8-1:0]                  query_m_axi_arlen;

wire                          query_m_axi_rvalid;
wire                          query_m_axi_rready;
wire [C_M_AXI_query_WIDTH-1:0] query_m_axi_rdata;
wire                          query_m_axi_rlast;

// AXI4-Stream master interface
wire                          query_rd_tvalid;
wire                          query_rd_tready;
wire                          query_rd_tlast;
wire [511:0]                  query_rd_tdata;

reg  [1:0] 					  reader_state;
reg  [1:0] 					  nxt_reader_state;

wire 						  nfa_read_done;
wire 						  query_read_done;

wire 						  nfa_start;
wire 						  query_start;

reg  [C_XFER_SIZE_WIDTH-1:0]  nfa_num_cls_received;
reg  [C_XFER_SIZE_WIDTH-1:0]  query_num_cls_received;

///////////////////////////////////////////////////////////////////////////////
// AXI Read Address Channel
///////////////////////////////////////////////////////////////////////////////

// Reader State 
always@(posedge clk) begin 
  if(~rst_n) begin
    reader_state <= IDLE;
  end
  else begin 
    reader_state <= nxt_reader_state;
  end
end

always@(*) begin 
	case (reader_state)
      IDLE          : nxt_reader_state = (ctrl_start)?         READ_NFA    : IDLE;
      READ_NFA    : nxt_reader_state = (nfa_read_done)?    WAIT_ALL_EDGES: READ_NFA;
      WAIT_ALL_EDGES: nxt_reader_state = READ_QUERY;
      READ_QUERY     : nxt_reader_state = (query_read_done)?     IDLE          : READ_QUERY; 
      default       : nxt_reader_state = IDLE;
    endcase
end


assign ctrl_done     = query_read_done;

assign nfa_start = (reader_state == IDLE)           && (nxt_reader_state == READ_NFA);
assign query_start  = (reader_state == WAIT_ALL_EDGES) && (nxt_reader_state == READ_QUERY);

// RD TX
assign m_axi_arvalid = (reader_state == READ_NFA)? nfa_m_axi_arvalid : (reader_state == READ_QUERY)? query_m_axi_arvalid : 1'b0;
assign m_axi_araddr  = (reader_state == READ_NFA)? nfa_m_axi_araddr  : (reader_state == READ_QUERY)? query_m_axi_araddr  : 0;
assign m_axi_arlen   = (reader_state == READ_NFA)? nfa_m_axi_arlen   : (reader_state == READ_QUERY)? query_m_axi_arlen   : 0;

assign query_m_axi_arready  = (reader_state == READ_QUERY)  && m_axi_arready;
assign nfa_m_axi_arready = (reader_state == READ_NFA) && m_axi_arready;

// RD RX 
assign nfa_m_axi_rvalid = (reader_state == READ_NFA) && m_axi_rvalid;
assign nfa_m_axi_rdata  = m_axi_rdata;
assign nfa_m_axi_rlast  = m_axi_rlast;

assign query_m_axi_rvalid  = (reader_state == READ_QUERY) && m_axi_rvalid;
assign query_m_axi_rdata   = m_axi_rdata;
assign query_m_axi_rlast   = m_axi_rlast;

assign m_axi_rready       = (reader_state == READ_NFA)? nfa_m_axi_rready : query_m_axi_rready;

// AXI stream to user core
assign m_axis_tvalid   = (reader_state == READ_NFA)? nfa_rd_tvalid : (reader_state == READ_QUERY)? query_rd_tvalid : 1'b0;
assign m_axis_tdata    = (reader_state == READ_NFA)? nfa_rd_tdata  : query_rd_tdata;
assign m_axis_tlast    = (reader_state == READ_NFA)? nfa_read_done : query_read_done;
assign m_axis_ttype    = (reader_state == READ_NFA)? 1'b0            : 1'b1;

assign nfa_rd_tready = m_axis_tready;
assign query_rd_tready  = m_axis_tready;

////////////////////////////// Counters
always@(posedge clk) begin 
  if(~rst_n) begin
    nfa_num_cls_received <= 0;
    query_num_cls_received  <= 0;
  end
  else begin 
    //
    if(nfa_read_done) begin
      nfa_num_cls_received <= 0;
    end
    else if(nfa_rd_tvalid && nfa_rd_tready) begin
      nfa_num_cls_received <= nfa_num_cls_received + 1'b1;
    end

    //
    if(query_read_done) begin
      query_num_cls_received  <= 0;
    end
    else if(query_rd_tvalid && query_rd_tready) begin
      query_num_cls_received <= query_num_cls_received + 1'b1;
    end
  end
end

assign nfa_read_done = nfa_rd_tvalid && nfa_rd_tready && (nfa_num_cls_received == (nfa_xfer_size_in_bytes[C_XFER_SIZE_WIDTH-1:6] - 2'd1));
assign query_read_done  = query_rd_tvalid  && query_rd_tready  && (query_num_cls_received  == (query_xfer_size_in_bytes[C_XFER_SIZE_WIDTH-1:6] - 2'd1));

// AXI4 Read Master, output format is an AXI4-Stream master, one stream per thread.
mct_axi_read_master #(
  .C_M_AXI_ADDR_WIDTH  ( C_M_AXI_ADDR_WIDTH    ) ,
  .C_M_AXI_query_WIDTH  ( C_M_AXI_query_WIDTH    ) ,
  .C_XFER_SIZE_WIDTH   ( 32                      ) ,
  .C_MAX_OUTSTANDING   ( LP_RD_MAX_OUTSTANDING   ) ,
  .C_INCLUDE_query_FIFO ( 1                       )
)
nfa_axi_read_master (
  .aclk                    ( clk                      ) ,
  .areset                  ( ~rst_n | nfa_read_done ) ,
  .ctrl_start              ( nfa_start              ) ,
  .ctrl_done               (                          ) ,
  .ctrl_addr_offset        ( nfaPtr                 ) ,
  .ctrl_xfer_size_in_bytes ( nfa_xfer_size_in_bytes ) ,
  .m_axi_arvalid           ( nfa_m_axi_arvalid      ) ,
  .m_axi_arready           ( nfa_m_axi_arready      ) ,
  .m_axi_araddr            ( nfa_m_axi_araddr       ) ,
  .m_axi_arlen             ( nfa_m_axi_arlen        ) ,
  .m_axi_rvalid            ( nfa_m_axi_rvalid       ) ,
  .m_axi_rready            ( nfa_m_axi_rready       ) ,
  .m_axi_rdata             ( nfa_m_axi_rdata        ) ,
  .m_axi_rlast             ( nfa_m_axi_rlast        ) ,
  .m_axis_aclk             ( clk                      ) ,
  .m_axis_areset           ( ~rst_n                   ) ,
  .m_axis_tvalid           ( nfa_rd_tvalid          ) ,
  .m_axis_tready           ( nfa_rd_tready          ) ,
  .m_axis_tlast            ( nfa_rd_tlast           ) ,
  .m_axis_tdata            ( nfa_rd_tdata           )
);


mct_axi_read_master #(
  .C_M_AXI_ADDR_WIDTH  ( C_M_AXI_ADDR_WIDTH    ) ,
  .C_M_AXI_query_WIDTH  ( C_M_AXI_query_WIDTH    ) ,
  .C_XFER_SIZE_WIDTH   ( 32     ) ,
  .C_MAX_OUTSTANDING   ( LP_RD_MAX_OUTSTANDING ) ,
  .C_INCLUDE_query_FIFO ( 1                     )
)
query_axi_read_master (
  .aclk                    ( clk                     ) ,
  .areset                  ( ~rst_n | query_read_done ) ,
  .ctrl_start              ( query_start              ) ,
  .ctrl_done               (                         ) ,
  .ctrl_addr_offset        ( queryPtr                 ) ,
  .ctrl_xfer_size_in_bytes ( query_xfer_size_in_bytes ) ,
  .m_axi_arvalid           ( query_m_axi_arvalid      ) ,
  .m_axi_arready           ( query_m_axi_arready      ) ,
  .m_axi_araddr            ( query_m_axi_araddr       ) ,
  .m_axi_arlen             ( query_m_axi_arlen        ) ,
  .m_axi_rvalid            ( query_m_axi_rvalid       ) ,
  .m_axi_rready            ( query_m_axi_rready       ) ,
  .m_axi_rdata             ( query_m_axi_rdata        ) ,
  .m_axi_rlast             ( query_m_axi_rlast        ) ,
  .m_axis_aclk             ( clk                     ) ,
  .m_axis_areset           ( ~rst_n                  ) ,
  .m_axis_tvalid           ( query_rd_tvalid          ) ,
  .m_axis_tready           ( query_rd_tready          ) ,
  .m_axis_tlast            ( query_rd_tlast           ) ,
  .m_axis_tdata            ( query_rd_tdata           )
);








endmodule