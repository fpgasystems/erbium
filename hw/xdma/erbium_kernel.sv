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

module erbium_kernel #( 
  parameter integer  C_M_AXI_GMEM_ID_WIDTH   = 1,
  parameter integer  C_M_AXI_GMEM_ADDR_WIDTH = 64,
  parameter integer  C_M_AXI_GMEM_DATA_WIDTH = 512
)
(
  // System Signals
  input  wire                                  data_clk           ,
  input  wire                                  data_rst_n         ,
  input  wire                                  kernel_clk         ,
  input  wire                                  kernel_rst_n       ,
  // AXI4 master interface
  output wire                                  m_axi_gmem_awvalid ,
  input  wire                                  m_axi_gmem_awready ,
  output wire [C_M_AXI_GMEM_ADDR_WIDTH-1:0]    m_axi_gmem_awaddr  ,
  output wire [7:0]                            m_axi_gmem_awlen   ,
  output wire [2:0]                            m_axi_gmem_awsize  ,
  output wire                                  m_axi_gmem_wvalid  ,
  input  wire                                  m_axi_gmem_wready  ,
  output wire [C_M_AXI_GMEM_DATA_WIDTH-1:0]    m_axi_gmem_wdata   ,
  output wire [C_M_AXI_GMEM_DATA_WIDTH/8-1:0]  m_axi_gmem_wstrb   ,
  output wire                                  m_axi_gmem_wlast   ,
  output wire                                  m_axi_gmem_arvalid ,
  input  wire                                  m_axi_gmem_arready ,
  output wire [C_M_AXI_GMEM_ADDR_WIDTH-1:0]    m_axi_gmem_araddr  ,
  output wire [C_M_AXI_GMEM_ID_WIDTH-1:0]      m_axi_gmem_arid    ,
  output wire [7:0]                            m_axi_gmem_arlen   ,
  output wire [2:0]                            m_axi_gmem_arsize  ,
  input  wire                                  m_axi_gmem_rvalid  ,
  output wire                                  m_axi_gmem_rready  ,
  input  wire [C_M_AXI_GMEM_DATA_WIDTH - 1:0]  m_axi_gmem_rdata   ,
  input  wire                                  m_axi_gmem_rlast   ,
  input  wire [C_M_AXI_GMEM_ID_WIDTH - 1:0]    m_axi_gmem_rid     ,
  input  wire [1:0]                            m_axi_gmem_rresp   ,
  input  wire                                  m_axi_gmem_bvalid  ,
  output wire                                  m_axi_gmem_bready  ,
  input  wire [1:0]                            m_axi_gmem_bresp   ,
  input  wire [C_M_AXI_GMEM_ID_WIDTH - 1:0]    m_axi_gmem_bid     , // not in use
  // control and user signals
  input  wire                                  ap_start           ,
  output wire                                  ap_done            ,
  output wire                                  ap_ready           ,
  output wire                                  ap_idle            ,
  input  wire [31:0]                           nfadata_cls        ,
  input  wire [31:0]                           queries_cls        ,
  input  wire [31:0]                           results_cls        ,
  input  wire [63:0]                           nfa_hash           ,
  input  wire [63:0]                           nfadata_ptr        ,
  input  wire [63:0]                           queries_ptr        ,
  input  wire [63:0]                           results_ptr
);

////////////////////////////////////////////////////////////////////////////////////////////////////
// Local Parameters                                                                               //
////////////////////////////////////////////////////////////////////////////////////////////////////
localparam integer LP_DW_BYTES           = C_M_AXI_GMEM_DATA_WIDTH/8;
localparam integer LP_AXI_BURST_LEN      = 4096/LP_DW_BYTES < 256 ? 4096/LP_DW_BYTES : 256;
localparam integer LP_LOG_BURST_LEN      = $clog2(LP_AXI_BURST_LEN);
localparam integer LP_WR_FIFO_DEPTH      = LP_AXI_BURST_LEN;

////////////////////////////////////////////////////////////////////////////////////////////////////
// Wires and Variables                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////
logic ap_start_pulse        ;
logic ap_start_r     = 1'b0 ;
logic ap_done_r      = 1'b0 ;
logic ap_idle_r      = 1'b1 ;
logic write_done            ;
logic read_done             ;

logic [31:0]  queries_cls_dlay;
logic [31:0]  nfadata_cls_dlay;

// AXI-Stream kernel communication
logic                                krnl_rd_valid;
logic                                krnl_rd_type;
logic                                krnl_rd_last;
logic                                krnl_rd_ready;
logic [C_M_AXI_GMEM_DATA_WIDTH-1:0]  krnl_rd_data;
logic                                krnl_wr_valid;
logic                                krnl_wr_ready_n;
logic [C_M_AXI_GMEM_DATA_WIDTH-1:0]  krnl_wr_data;

// From AsyncFIFO to AXI Write
logic                                wr_fifo_tvalid_n;
logic                                wr_fifo_tready; 
logic [C_M_AXI_GMEM_DATA_WIDTH-1:0]  wr_fifo_tdata;

////////////////////////////////////////////////////////////////////////////////////////////////////
// Begin RTL                                                                                      //
////////////////////////////////////////////////////////////////////////////////////////////////////

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
    ap_done_r <= (ap_start_pulse | ap_done) ? 1'b0 : ap_done_r | write_done;
  end
end

assign ap_done  = ap_done_r;
assign ap_ready = ap_done_r;
assign ap_idle  = ap_idle_r;

always @(posedge data_clk) begin
  queries_cls_dlay <= queries_cls;
  nfadata_cls_dlay <= nfadata_cls;
end

////////////////////////////////////////////////////////////////////////////////////////////////////
// Input Channel                                                                                  //
////////////////////////////////////////////////////////////////////////////////////////////////////

// AXI4 Read Master, output format is an AXI4-Stream master
InputChannel #(
  .C_M_AXI_ID_WIDTH    ( C_M_AXI_GMEM_ID_WIDTH   ),
  .C_M_AXI_ADDR_WIDTH  ( C_M_AXI_GMEM_ADDR_WIDTH ),
  .C_M_AXI_DATA_WIDTH  ( C_M_AXI_GMEM_DATA_WIDTH ),
  .C_LENGTH_WIDTH      ( 32                      )
)
inst_InputChannel (
  .data_clk            ( data_clk           ),
  .data_rst_n          ( data_rst_n         ),
  .ctrl_start          ( ap_start_pulse     ),
  .ctrl_done           ( read_done          ), // not in use
  //
  .nfa_hash            ( nfa_hash           ),
  .nfadata_ptr         ( nfadata_ptr        ),
  .nfadata_cls         ( nfadata_cls_dlay   ),
  .queries_ptr         ( queries_ptr        ),
  .queries_cls         ( queries_cls_dlay   ),
  // AXI4 shell communication
  .m_axi_arvalid       ( m_axi_gmem_arvalid ),
  .m_axi_arready       ( m_axi_gmem_arready ),
  .m_axi_araddr        ( m_axi_gmem_araddr  ),
  .m_axi_arid          ( m_axi_gmem_arid    ),
  .m_axi_arlen         ( m_axi_gmem_arlen   ),
  .m_axi_arsize        ( m_axi_gmem_arsize  ),
  .m_axi_rvalid        ( m_axi_gmem_rvalid  ),
  .m_axi_rready        ( m_axi_gmem_rready  ),
  .m_axi_rdata         ( m_axi_gmem_rdata   ),
  .m_axi_rlast         ( m_axi_gmem_rlast   ),
  .m_axi_rid           ( m_axi_gmem_rid     ),
  .m_axi_rresp         ( m_axi_gmem_rresp   ),
  // AXI-Stream kernel communication
  .m_axis_aclk         ( kernel_clk         ),
  .m_axis_areset_n     ( kernel_rst_n       ),
  .m_axis_tvalid       ( krnl_rd_valid      ),
  .m_axis_tready       ( krnl_rd_ready      ),
  .m_axis_tlast        ( krnl_rd_last       ),
  .m_axis_tdata        ( krnl_rd_data       ),
  .m_axis_ttype        ( krnl_rd_type       )
);

////////////////////////////////////////////////////////////////////////////////////////////////////
// ERBIUM ENGINE WRAPPER                                                                          //
////////////////////////////////////////////////////////////////////////////////////////////////////

erbium_wrapper #(
  .G_DATA_BUS_WIDTH    ( C_M_AXI_GMEM_DATA_WIDTH )
)
inst_wrapper (
  .clk_i               ( kernel_clk       ),
  .rst_i               ( kernel_rst_n     ),
  // input
  .rd_data_i           ( krnl_rd_data     ),
  .rd_valid_i          ( krnl_rd_valid    ),
  .rd_last_i           ( krnl_rd_last     ),
  .rd_stype_i          ( krnl_rd_type     ),
  .rd_ready_o          ( krnl_rd_ready    ),
  // output
  .wr_data_o           ( krnl_wr_data     ),
  .wr_valid_o          ( krnl_wr_valid    ),
  .wr_last_o           (                  ),
  .wr_ready_i          ( ~krnl_wr_ready_n )
);

////////////////////////////////////////////////////////////////////////////////////////////////////
// Output Channel                                                                                 //
////////////////////////////////////////////////////////////////////////////////////////////////////

// FIFO for CDC
xpm_fifo_async # (
  .FIFO_MEMORY_TYPE     ( "auto"                   ),
  .ECC_MODE             ( "no_ecc"                 ),
  .RELATED_CLOCKS       ( 0                        ),
  .FIFO_WRITE_DEPTH     ( LP_WR_FIFO_DEPTH         ),
  .WRITE_DATA_WIDTH     ( C_M_AXI_GMEM_DATA_WIDTH  ),
  .WR_DATA_COUNT_WIDTH  ( $clog2(LP_WR_FIFO_DEPTH) ),
  .PROG_FULL_THRESH     ( 10                       ),
  .FULL_RESET_VALUE     ( 1                        ),
  .READ_MODE            ( "fwft"                   ),
  .FIFO_READ_LATENCY    ( 1                        ),
  .READ_DATA_WIDTH      ( C_M_AXI_GMEM_DATA_WIDTH  ),
  .RD_DATA_COUNT_WIDTH  ( $clog2(LP_WR_FIFO_DEPTH) ),
  .PROG_EMPTY_THRESH    ( 10                       ),
  .DOUT_RESET_VALUE     ( "0"                      ),
  .CDC_SYNC_STAGES      ( 3                        ),
  .WAKEUP_TIME          ( 0                        )

) inst_wr_xpm_fifo_async (
  .rst                  ( ~kernel_rst_n    ),
  .wr_clk               ( kernel_clk       ),
  .wr_en                ( krnl_wr_valid    ),
  .din                  ( krnl_wr_data     ),
  .full                 ( krnl_wr_ready_n  ),
  .overflow             (                  ),
  .wr_rst_busy          (                  ),
  .rd_clk               ( data_clk         ),
  .rd_en                ( wr_fifo_tready   ),
  .dout                 ( wr_fifo_tdata    ),
  .empty                ( wr_fifo_tvalid_n ),
  .underflow            (                  ),
  .rd_rst_busy          (                  ),
  .prog_full            (                  ),
  .wr_data_count        (                  ),
  .prog_empty           (                  ),
  .rd_data_count        (                  ),
  .sleep                ( 1'b0             ),
  .injectsbiterr        ( 1'b0             ),
  .injectdbiterr        ( 1'b0             ),
  .sbiterr              (                  ),
  .dbiterr              (                  )
);

// AXI4 Write Master
xdma_axi_write_master #( 
  .C_ADDR_WIDTH       ( C_M_AXI_GMEM_ADDR_WIDTH ),
  .C_DATA_WIDTH       ( C_M_AXI_GMEM_DATA_WIDTH ),
  .C_MAX_LENGTH_WIDTH ( 32                      ),
  .C_BURST_LEN        ( LP_AXI_BURST_LEN        ),
  .C_LOG_BURST_LEN    ( LP_LOG_BURST_LEN        )
)
inst_axi_write_master ( 
  .aclk        ( data_clk           ),
  .areset      ( ~data_rst_n        ),

  .ctrl_start  ( ap_start_pulse     ),
  .ctrl_offset ( results_ptr        ),
  .ctrl_length ( results_cls        ),
  .ctrl_done   ( write_done         ),

  .s_tvalid    ( ~wr_fifo_tvalid_n  ),
  .s_tready    ( wr_fifo_tready     ),
  .s_tdata     ( wr_fifo_tdata      ),

  .awvalid     ( m_axi_gmem_awvalid ),
  .awready     ( m_axi_gmem_awready ),
  .awaddr      ( m_axi_gmem_awaddr  ),
  .awlen       ( m_axi_gmem_awlen   ),
  .awsize      ( m_axi_gmem_awsize  ),
  .wvalid      ( m_axi_gmem_wvalid  ),
  .wready      ( m_axi_gmem_wready  ),
  .wdata       ( m_axi_gmem_wdata   ),
  .wstrb       ( m_axi_gmem_wstrb   ),
  .wlast       ( m_axi_gmem_wlast   ),
  .bvalid      ( m_axi_gmem_bvalid  ),
  .bready      ( m_axi_gmem_bready  ),
  .bresp       ( m_axi_gmem_bresp   )
);

endmodule : erbium_kernel
`default_nettype wire