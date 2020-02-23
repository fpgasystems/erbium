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

module erbium #(
  parameter integer C_S_AXI_CONTROL_ADDR_WIDTH   = 12 ,
  parameter integer C_S_AXI_CONTROL_DATA_WIDTH   = 32 ,
  parameter integer C_RESULTS_STREAM_TDATA_WIDTH = 512,
  parameter integer C_INPUTS_STREAM_TDATA_WIDTH  = 512
)
(
  // System Signals
  input  wire                                      ap_clk               ,
  input  wire                                      ap_rst_n             ,
  input  wire                                      ap_clk_2             ,
  input  wire                                      ap_rst_n_2           ,
  // AXI4-Stream (master) interface results_stream
  output wire                                      results_stream_tvalid,
  input  wire                                      results_stream_tready,
  output wire [C_RESULTS_STREAM_TDATA_WIDTH-1:0]   results_stream_tdata ,
  output wire [C_RESULTS_STREAM_TDATA_WIDTH/8-1:0] results_stream_tkeep ,
  output wire                                      results_stream_tlast ,
  // AXI4-Stream (slave) interface inputs_stream
  input  wire                                      inputs_stream_tvalid ,
  output wire                                      inputs_stream_tready ,
  input  wire [C_INPUTS_STREAM_TDATA_WIDTH-1:0]    inputs_stream_tdata  ,
  input  wire [C_INPUTS_STREAM_TDATA_WIDTH/8-1:0]  inputs_stream_tkeep  ,
  input  wire                                      inputs_stream_tlast  ,
  // AXI4-Lite slave interface
  input  wire                                      s_axi_control_awvalid,
  output wire                                      s_axi_control_awready,
  input  wire [C_S_AXI_CONTROL_ADDR_WIDTH-1:0]     s_axi_control_awaddr ,
  input  wire                                      s_axi_control_wvalid ,
  output wire                                      s_axi_control_wready ,
  input  wire [C_S_AXI_CONTROL_DATA_WIDTH-1:0]     s_axi_control_wdata  ,
  input  wire [C_S_AXI_CONTROL_DATA_WIDTH/8-1:0]   s_axi_control_wstrb  ,
  input  wire                                      s_axi_control_arvalid,
  output wire                                      s_axi_control_arready,
  input  wire [C_S_AXI_CONTROL_ADDR_WIDTH-1:0]     s_axi_control_araddr ,
  output wire                                      s_axi_control_rvalid ,
  input  wire                                      s_axi_control_rready ,
  output wire [C_S_AXI_CONTROL_DATA_WIDTH-1:0]     s_axi_control_rdata  ,
  output wire [2-1:0]                              s_axi_control_rresp  ,
  output wire                                      s_axi_control_bvalid ,
  input  wire                                      s_axi_control_bready ,
  output wire [2-1:0]                              s_axi_control_bresp  ,
  output wire                                      interrupt            
);


////////////////////////////////////////////////////////////////////////////////////////////////////
// Wires and Variables
////////////////////////////////////////////////////////////////////////////////////////////////////
reg                                 areset                         = 1'b0;
wire                                ap_start                      ;
wire                                ap_idle                       ;
wire                                ap_done                       ;
wire                                ap_ready                      ;
wire [32-1:0]                       nfa_hash                      ;
//
reg                                 ap_start_dlay                 ;
reg [64-1:0]                        nfa_hash_dlay                 ;

// Register and invert reset signal.
always @(posedge ap_clk) begin
  areset <= ~ap_rst_n;
  ap_start_dlay    <= ap_start;
  nfa_hash_dlay    <= nfa_hash;
end

////////////////////////////////////////////////////////////////////////////////////////////////////
// Begin control interface RTL.
////////////////////////////////////////////////////////////////////////////////////////////////////

// AXI4-Lite slave interface
erbium_control_s_axi #(
  .C_S_AXI_ADDR_WIDTH ( C_S_AXI_CONTROL_ADDR_WIDTH ),
  .C_S_AXI_DATA_WIDTH ( C_S_AXI_CONTROL_DATA_WIDTH )
)
inst_control_s_axi (
  .ACLK        ( ap_clk                ),
  .ARESET      ( areset                ),
  .ACLK_EN     ( 1'b1                  ),
  .AWVALID     ( s_axi_control_awvalid ),
  .AWREADY     ( s_axi_control_awready ),
  .AWADDR      ( s_axi_control_awaddr  ),
  .WVALID      ( s_axi_control_wvalid  ),
  .WREADY      ( s_axi_control_wready  ),
  .WDATA       ( s_axi_control_wdata   ),
  .WSTRB       ( s_axi_control_wstrb   ),
  .ARVALID     ( s_axi_control_arvalid ),
  .ARREADY     ( s_axi_control_arready ),
  .ARADDR      ( s_axi_control_araddr  ),
  .RVALID      ( s_axi_control_rvalid  ),
  .RREADY      ( s_axi_control_rready  ),
  .RDATA       ( s_axi_control_rdata   ),
  .RRESP       ( s_axi_control_rresp   ),
  .BVALID      ( s_axi_control_bvalid  ),
  .BREADY      ( s_axi_control_bready  ),
  .BRESP       ( s_axi_control_bresp   ),
  .interrupt   ( interrupt             ),
  .ap_start    ( ap_start              ),
  .ap_done     ( ap_done               ),
  .ap_ready    ( ap_ready              ),
  .ap_idle     ( ap_idle               ),
  .nfadata_cls (                       ),
  .queries_cls (                       ),
  .results_cls (                       ),
  .scalar03    (                       ),
  .nfa_hash    ( nfa_hash              )
);

////////////////////////////////////////////////////////////////////////////////////////////////////
// ERBIUM KERNEL
////////////////////////////////////////////////////////////////////////////////////////////////////

erbium_kernel #(
  .C_RESULTS_STREAM_TDATA_WIDTH ( C_RESULTS_STREAM_TDATA_WIDTH ),
  .C_INPUTS_STREAM_TDATA_WIDTH  ( C_INPUTS_STREAM_TDATA_WIDTH  )
)
inst_kernel (
  .data_clk              ( ap_clk                ),
  .data_rst_n            ( ap_rst_n              ),
  .kernel_clk            ( ap_clk_2              ),
  .kernel_rst_n          ( ap_rst_n_2            ),
  .results_stream_tvalid ( results_stream_tvalid ),
  .results_stream_tready ( results_stream_tready ),
  .results_stream_tdata  ( results_stream_tdata  ),
  .results_stream_tkeep  ( results_stream_tkeep  ),
  .results_stream_tlast  ( results_stream_tlast  ),
  .inputs_stream_tvalid  ( inputs_stream_tvalid  ),
  .inputs_stream_tready  ( inputs_stream_tready  ),
  .inputs_stream_tdata   ( inputs_stream_tdata   ),
  .inputs_stream_tkeep   ( inputs_stream_tkeep   ),
  .inputs_stream_tlast   ( inputs_stream_tlast   ),
  .ap_start              ( ap_start_dlay         ),
  .ap_done               ( ap_done               ),
  .ap_idle               ( ap_idle               ),
  .ap_ready              ( ap_ready              ),
  .nfa_hash              ( nfa_hash_dlay         )
);

endmodule
`default_nettype wire