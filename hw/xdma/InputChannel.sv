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
`timescale 1 ns / 1 ps

module InputChannel #(
  parameter integer  C_M_AXI_ID_WIDTH   = 1,
  parameter integer  C_M_AXI_ADDR_WIDTH = 64,
  parameter integer  C_M_AXI_DATA_WIDTH = 512,
  parameter integer  C_LENGTH_WIDTH     = 32
)
(
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
  output wire [C_M_AXI_ID_WIDTH-1:0]    m_axi_arid      ,
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

////////////////////////////////////////////////////////////////////////////////////////////////////
// Local Parameters
////////////////////////////////////////////////////////////////////////////////////////////////////
localparam integer LP_DW_BYTES           = C_M_AXI_DATA_WIDTH/8;
localparam integer LP_AXI_BURST_LEN      = 4096/LP_DW_BYTES < 256 ? 4096/LP_DW_BYTES : 256;
localparam integer LP_LOG_BURST_LEN      = $clog2(LP_AXI_BURST_LEN);
localparam integer LP_RD_MAX_OUTSTANDING = 3;
localparam integer LP_RD_FIFO_DEPTH      = LP_AXI_BURST_LEN*(LP_RD_MAX_OUTSTANDING + 1);

localparam [1:0] IDLE           = 2'b00,
                 READ_NFA       = 2'b01,
                 WAIT_ALL_EDGES = 2'b10,
                 READ_QUERY     = 2'b11;

////////////////////////////////////////////////////////////////////////////////////////////////////
// Wires and Variables                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////

logic [1:0]                     ctrl_state          ;
logic [1:0]                     ctrl_state_nxt      ;
logic [C_M_AXI_ID_WIDTH-1:0]    m_axi_id            ;

logic                           nfa_start           ;
logic                           nfa_done            ;
logic                           nfa_done_dataclk    ;
logic                           nfa_reload          ;
logic [63:0]                    nfa_hash_r          ;
logic [C_LENGTH_WIDTH-1:0]      nfa_cls_total       ;
logic [C_LENGTH_WIDTH-1:0]      nfa_cls_received    ;

logic                           nfa_m_axi_arvalid   ;
logic                           nfa_m_axi_arready   ;
logic [C_M_AXI_ADDR_WIDTH-1:0]  nfa_m_axi_araddr    ;
logic [7:0]                     nfa_m_axi_arlen     ;
logic [2:0]                     nfa_m_axi_arsize    ;
logic                           nfa_m_axi_rvalid    ;
logic                           nfa_m_axi_rready    ;
logic [C_M_AXI_DATA_WIDTH-1:0]  nfa_m_axi_rdata     ;
logic                           nfa_m_axi_rlast     ;
logic [1:0]                     nfa_m_axi_rresp     ;
logic                           nfa_axis_tvalid     ;
logic                           nfa_axis_tready_n   ;
logic [C_M_AXI_DATA_WIDTH-1:0]  nfa_axis_tdata      ;
logic                           nfa_fifo_full       ;
logic                           nfa_fifo_tvalid_n   ;
logic [C_M_AXI_DATA_WIDTH-1:0]  nfa_fifo_tdata      ;
logic                           nfa_fifo_tready     ;

logic                           query_start         ;
logic                           query_done          ;
logic                           query_done_dataclk  ;
logic [C_LENGTH_WIDTH-1:0]      query_cls_total     ;
logic [C_LENGTH_WIDTH-1:0]      query_cls_received  ;

logic                           query_m_axi_arvalid ;
logic                           query_m_axi_arready ;
logic [C_M_AXI_ADDR_WIDTH-1:0]  query_m_axi_araddr  ;
logic [7:0]                     query_m_axi_arlen   ;
logic [2:0]                     query_m_axi_arsize  ;
logic                           query_m_axi_rvalid  ;
logic                           query_m_axi_rready  ;
logic [C_M_AXI_DATA_WIDTH-1:0]  query_m_axi_rdata   ;
logic                           query_m_axi_rlast   ;
logic [1:0]                     query_m_axi_rresp   ;
logic                           query_axis_tvalid   ;
logic                           query_axis_tready_n ;
logic [C_M_AXI_DATA_WIDTH-1:0]  query_axis_tdata    ;
logic                           query_fifo_full     ;
logic                           query_fifo_tvalid_n ;
logic [C_M_AXI_DATA_WIDTH-1:0]  query_fifo_tdata    ;
logic                           query_fifo_tready   ;

////////////////////////////////////////////////////////////////////////////////////////////////////
// STATE MACHINE
////////////////////////////////////////////////////////////////////////////////////////////////////

always@(posedge data_clk) begin
  if (~data_rst_n) begin
    ctrl_state <= IDLE;
  end
  else begin
    ctrl_state <= ctrl_state_nxt;
  end
end

always@(*) begin
    case (ctrl_state)
      IDLE           : ctrl_state_nxt = (ctrl_start) ? ((nfa_reload) ? READ_NFA : WAIT_ALL_EDGES) : IDLE;
      READ_NFA       : ctrl_state_nxt = (nfa_done_dataclk)   ? WAIT_ALL_EDGES : READ_NFA;
      WAIT_ALL_EDGES : ctrl_state_nxt = READ_QUERY;
      READ_QUERY     : ctrl_state_nxt = (query_done_dataclk) ? IDLE           : READ_QUERY;
      default        : ctrl_state_nxt = IDLE;
    endcase
end

assign ctrl_done    = query_done;
assign nfa_start    = (ctrl_state == IDLE)           && (ctrl_state_nxt == READ_NFA);
assign query_start  = (ctrl_state == WAIT_ALL_EDGES) && (ctrl_state_nxt == READ_QUERY);

////////////////////////////////////////////////////////////////////////////////////////////////////
// NFA HASH CONTROL
////////////////////////////////////////////////////////////////////////////////////////////////////

always@(posedge data_clk) begin
  if (~data_rst_n) begin
    nfa_hash_r <= 0;
  end
  else if (ctrl_start) begin
      nfa_hash_r <= nfa_hash;
  end
end

assign nfa_reload = (ctrl_start) && (nfa_hash !== nfa_hash_r);

////////////////////////////////////////////////////////////////////////////////////////////////////
// AXI ID UPDATE
////////////////////////////////////////////////////////////////////////////////////////////////////

always@(posedge data_clk) begin
  if (~data_rst_n) begin
    m_axi_id <= {C_M_AXI_ID_WIDTH{1'b1}};
  end
  else if (nfa_done_dataclk || query_done_dataclk) begin
      m_axi_id <= ~m_axi_id;
  end
end

assign m_axi_arid = m_axi_id;

////////////////////////////////////////////////////////////////////////////////////////////////////
// SHARE AXI4 READ MASTER TO TWO CHANNELS (NFA AND QUERY)
////////////////////////////////////////////////////////////////////////////////////////////////////

// TX
assign m_axi_arvalid = (ctrl_state == READ_NFA) ? nfa_m_axi_arvalid : (ctrl_state == READ_QUERY) ? query_m_axi_arvalid : 0;
assign m_axi_araddr  = (ctrl_state == READ_NFA) ? nfa_m_axi_araddr  : (ctrl_state == READ_QUERY) ? query_m_axi_araddr  : 0;
assign m_axi_arlen   = (ctrl_state == READ_NFA) ? nfa_m_axi_arlen   : (ctrl_state == READ_QUERY) ? query_m_axi_arlen   : 0;
assign m_axi_arsize  = (ctrl_state == READ_NFA) ? nfa_m_axi_arsize  : (ctrl_state == READ_QUERY) ? query_m_axi_arsize  : 0;
assign m_axi_rready  = (ctrl_state == READ_NFA) ? nfa_m_axi_rready  : (ctrl_state == READ_QUERY) ? query_m_axi_rready  : 0;

// RX
assign nfa_m_axi_arready   = (ctrl_state == READ_NFA  ) && m_axi_arready;
assign nfa_m_axi_rvalid    = (ctrl_state == READ_NFA  ) && m_axi_rvalid;
assign nfa_m_axi_rdata     = m_axi_rdata;
assign nfa_m_axi_rlast     = m_axi_rlast;
assign nfa_m_axi_rresp     = m_axi_rresp;
assign query_m_axi_arready = (ctrl_state == READ_QUERY) && m_axi_arready;
assign query_m_axi_rvalid  = (ctrl_state == READ_QUERY) && m_axi_rvalid;
assign query_m_axi_rdata   = m_axi_rdata;
assign query_m_axi_rlast   = m_axi_rlast;
assign query_m_axi_rresp   = m_axi_rresp;

// AXI stream to user core
assign m_axis_tvalid = (ctrl_state == READ_NFA) ? ~nfa_fifo_tvalid_n : (ctrl_state == READ_QUERY) ? ~query_fifo_tvalid_n : 1'b0;
assign m_axis_tdata  = (ctrl_state == READ_NFA) ? nfa_fifo_tdata     : query_fifo_tdata;
assign m_axis_tlast  = (ctrl_state == READ_NFA) ? nfa_done           : query_done;
assign m_axis_ttype  = (ctrl_state == READ_NFA) ? 1'b0               : 1'b1;

assign nfa_fifo_tready   = (ctrl_state == READ_NFA)   ? m_axis_tready : 1'b0;
assign query_fifo_tready = (ctrl_state == READ_QUERY) ? m_axis_tready : 1'b0;


////////////////////////////////////////////////////////////////////////////////////////////////////
// COUNTERS
////////////////////////////////////////////////////////////////////////////////////////////////////

always@(posedge data_clk) begin
  if (ctrl_start) begin
    nfa_cls_total   <= nfadata_cls - 2'd1;
    query_cls_total <= queries_cls - 2'd1;
  end
end

always@(posedge m_axis_aclk) begin
  if (~m_axis_areset_n) begin
    nfa_cls_received   <= 0;
    query_cls_received <= 0;
  end
  else begin
    //
    if (nfa_done) begin
      nfa_cls_received <= 0;
    end
    else if (~nfa_fifo_tvalid_n && nfa_fifo_tready) begin
      nfa_cls_received <= nfa_cls_received + 1'b1;
    end

    //
    if (query_done) begin
      query_cls_received  <= 0;
    end
    else if (~query_fifo_tvalid_n && query_fifo_tready) begin
      query_cls_received <= query_cls_received + 1'b1;
    end
  end
end

assign nfa_done   = ~nfa_fifo_tvalid_n   && nfa_fifo_tready   && (nfa_cls_received   == nfa_cls_total);
assign query_done = ~query_fifo_tvalid_n && query_fifo_tready && (query_cls_received == query_cls_total);

////////////////////////////////////////////////////////////////////////////////////////////////////
// NFA DATA CHANNEL
////////////////////////////////////////////////////////////////////////////////////////////////////

// AXI4 Read Master
xdma_axi_read_master #( 
  .C_ADDR_WIDTH       ( C_M_AXI_ADDR_WIDTH    ),
  .C_DATA_WIDTH       ( C_M_AXI_DATA_WIDTH    ),
  .C_LENGTH_WIDTH     ( C_LENGTH_WIDTH        ),
  .C_BURST_LEN        ( LP_AXI_BURST_LEN      ),
  .C_LOG_BURST_LEN    ( LP_LOG_BURST_LEN      ),
  .C_MAX_OUTSTANDING  ( LP_RD_MAX_OUTSTANDING )
)
nfa_axi_read_master ( 
  .aclk           ( data_clk            ),
  .areset         ( ~data_rst_n | nfa_done_dataclk ),

  .ctrl_start     ( nfa_start           ),
  .ctrl_done      (                     ),
  .ctrl_offset    ( nfadata_ptr         ),
  .ctrl_length    ( nfadata_cls         ),
  .ctrl_prog_full ( nfa_fifo_full       ),

  .arvalid        ( nfa_m_axi_arvalid   ),
  .arready        ( nfa_m_axi_arready   ),
  .araddr         ( nfa_m_axi_araddr    ),
  .arlen          ( nfa_m_axi_arlen     ),
  .arsize         ( nfa_m_axi_arsize    ),
  .rvalid         ( nfa_m_axi_rvalid    ),
  .rready         ( nfa_m_axi_rready    ),
  .rdata          ( nfa_m_axi_rdata     ),
  .rlast          ( nfa_m_axi_rlast     ),
  .rresp          ( nfa_m_axi_rresp     ),

  .m_tvalid       ( nfa_axis_tvalid     ),
  .m_tready       ( ~nfa_axis_tready_n  ),
  .m_tdata        ( nfa_axis_tdata      ) 
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
)
nfa_rd_xpm_fifo_async (
  .rst           ( ~data_rst_n       ),
  .wr_clk        ( data_clk          ),
  .wr_en         ( nfa_axis_tvalid   ),
  .din           ( nfa_axis_tdata    ),
  .full          ( nfa_axis_tready_n ),
  .overflow      (                   ),
  .wr_rst_busy   (                   ),
  .rd_clk        ( m_axis_aclk       ),
  .rd_en         ( nfa_fifo_tready   ),
  .dout          ( nfa_fifo_tdata    ),
  .empty         ( nfa_fifo_tvalid_n ),
  .underflow     (                   ),
  .rd_rst_busy   (                   ),
  .prog_full     ( nfa_fifo_full     ),
  .wr_data_count (                   ),
  .prog_empty    (                   ),
  .rd_data_count (                   ),
  .sleep         ( 1'b0              ),
  .injectsbiterr ( 1'b0              ),
  .injectdbiterr ( 1'b0              ),
  .sbiterr       (                   ),
  .dbiterr       (                   )
);


////////////////////////////////////////////////////////////////////////////////////////////////////
// QUERY DATA CHANNEL
////////////////////////////////////////////////////////////////////////////////////////////////////

// AXI4 Read Master
xdma_axi_read_master #( 
  .C_ADDR_WIDTH       ( C_M_AXI_ADDR_WIDTH    ),
  .C_DATA_WIDTH       ( C_M_AXI_DATA_WIDTH    ),
  .C_LENGTH_WIDTH     ( C_LENGTH_WIDTH        ),
  .C_BURST_LEN        ( LP_AXI_BURST_LEN      ),
  .C_LOG_BURST_LEN    ( LP_LOG_BURST_LEN      ),
  .C_MAX_OUTSTANDING  ( LP_RD_MAX_OUTSTANDING )
)
query_axi_read_master ( 
  .aclk           ( data_clk            ),
  .areset         ( ~data_rst_n | query_done_dataclk ),

  .ctrl_start     ( query_start          ),
  .ctrl_done      (                      ),
  .ctrl_offset    ( queries_ptr          ),
  .ctrl_length    ( queries_cls          ),
  .ctrl_prog_full ( query_fifo_full      ),

  .arvalid        ( query_m_axi_arvalid  ),
  .arready        ( query_m_axi_arready  ),
  .araddr         ( query_m_axi_araddr   ),
  .arlen          ( query_m_axi_arlen    ),
  .arsize         ( query_m_axi_arsize   ),
  .rvalid         ( query_m_axi_rvalid   ),
  .rready         ( query_m_axi_rready   ),
  .rdata          ( query_m_axi_rdata    ),
  .rlast          ( query_m_axi_rlast    ),
  .rresp          ( query_m_axi_rresp    ),

  .m_tvalid       ( query_axis_tvalid    ),
  .m_tready       ( ~query_axis_tready_n ),
  .m_tdata        ( query_axis_tdata     ) 
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
)
query_rd_xpm_fifo_async (
  .rst           ( ~data_rst_n       ),
  .wr_clk        ( data_clk          ),
  .wr_en         ( query_axis_tvalid   ),
  .din           ( query_axis_tdata    ),
  .full          ( query_axis_tready_n ),
  .overflow      (                     ),
  .wr_rst_busy   (                     ),
  .rd_clk        ( m_axis_aclk         ),
  .rd_en         ( query_fifo_tready   ),
  .dout          ( query_fifo_tdata    ),
  .empty         ( query_fifo_tvalid_n ),
  .underflow     (                     ),
  .rd_rst_busy   (                     ),
  .prog_full     ( query_fifo_full     ),
  .wr_data_count (                     ),
  .prog_empty    (                     ),
  .rd_data_count (                     ),
  .sleep         ( 1'b0                ),
  .injectsbiterr ( 1'b0                ),
  .injectdbiterr ( 1'b0                ),
  .sbiterr       (                     ),
  .dbiterr       (                     )
);

////////////////////////////////////////////////////////////////////////////////////////////////////
// CDC
////////////////////////////////////////////////////////////////////////////////////////////////////

// xpm_cdc_pulse: Pulse Transfer
// Xilinx Parameterized Macro, version 2018.3
xpm_cdc_pulse #(
   .DEST_SYNC_FF   ( 3 ),
   .INIT_SYNC_FF   ( 0 ),
   .REG_OUTPUT     ( 0 ),
   .RST_USED       ( 0 ),
   .SIM_ASSERT_CHK ( 0 )
)
inst_nfa_done_dataclk (
   .dest_pulse     ( nfa_done_dataclk ),
   .dest_clk       ( data_clk         ),
   .src_clk        ( m_axis_aclk      ),
   .src_pulse      ( nfa_done         )
);

xpm_cdc_pulse #(
   .DEST_SYNC_FF   ( 3 ),
   .INIT_SYNC_FF   ( 0 ),
   .REG_OUTPUT     ( 0 ),
   .RST_USED       ( 0 ),
   .SIM_ASSERT_CHK ( 0 )
)
inst_query_done_dataclk (
   .dest_pulse     ( query_done_dataclk ),
   .dest_clk       ( data_clk           ),
   .src_clk        ( m_axis_aclk        ),
   .src_pulse      ( query_done         )
);

endmodule
`default_nettype wire