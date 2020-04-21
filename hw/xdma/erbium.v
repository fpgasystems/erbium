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
// Top level of the kernel. Do not modify module name, parameters or ports.
module erbium #(
  parameter integer  C_S_AXI_CONTROL_DATA_WIDTH = 32,
  parameter integer  C_S_AXI_CONTROL_ADDR_WIDTH = 7,
  parameter integer  C_M_AXI_GMEM_ID_WIDTH = 1,
  parameter integer  C_M_AXI_GMEM_ADDR_WIDTH = 64,
  parameter integer  C_M_AXI_GMEM_DATA_WIDTH = 512
)
(
  // System signals
  input  wire                                    ap_clk                ,
  input  wire                                    ap_rst_n              ,
  input  wire                                    ap_clk_2              ,
  input  wire                                    ap_rst_n_2            ,

  // AXI4 master interface
  output wire                                    m_axi_gmem_awvalid    ,
  input  wire                                    m_axi_gmem_awready    ,
  output wire [C_M_AXI_GMEM_ADDR_WIDTH-1:0]      m_axi_gmem_awaddr     ,
  output wire [7:0]                              m_axi_gmem_awlen      ,
  output wire [2:0]                              m_axi_gmem_awsize     ,
  output wire                                    m_axi_gmem_wvalid     ,
  input  wire                                    m_axi_gmem_wready     ,
  output wire [C_M_AXI_GMEM_DATA_WIDTH-1:0]      m_axi_gmem_wdata      ,
  output wire [C_M_AXI_GMEM_DATA_WIDTH/8-1:0]    m_axi_gmem_wstrb      ,
  output wire                                    m_axi_gmem_wlast      ,
  output wire                                    m_axi_gmem_arvalid    ,
  input  wire                                    m_axi_gmem_arready    ,
  output wire [C_M_AXI_GMEM_ADDR_WIDTH-1:0]      m_axi_gmem_araddr     ,
  output wire [C_M_AXI_GMEM_ID_WIDTH-1:0]        m_axi_gmem_arid       ,
  output wire [7:0]                              m_axi_gmem_arlen      ,
  output wire [2:0]                              m_axi_gmem_arsize     ,
  input  wire                                    m_axi_gmem_rvalid     ,
  output wire                                    m_axi_gmem_rready     ,
  input  wire [C_M_AXI_GMEM_DATA_WIDTH - 1:0]    m_axi_gmem_rdata      ,
  input  wire                                    m_axi_gmem_rlast      ,
  input  wire [C_M_AXI_GMEM_ID_WIDTH - 1:0]      m_axi_gmem_rid        ,
  input  wire [1:0]                              m_axi_gmem_rresp      ,
  input  wire                                    m_axi_gmem_bvalid     ,
  output wire                                    m_axi_gmem_bready     ,
  input  wire [1:0]                              m_axi_gmem_bresp      ,
  input  wire [C_M_AXI_GMEM_ID_WIDTH - 1:0]      m_axi_gmem_bid        ,
  // Tie-off AXI4 transaction options that are not being used.
  output wire [C_M_AXI_GMEM_ID_WIDTH - 1:0]      m_axi_gmem_awid       ,
  output wire [1:0]                              m_axi_gmem_awburst    ,
  output wire [1:0]                              m_axi_gmem_awlock     ,
  output wire [3:0]                              m_axi_gmem_awcache    ,
  output wire [2:0]                              m_axi_gmem_awprot     ,
  output wire [3:0]                              m_axi_gmem_awqos      ,
  output wire [3:0]                              m_axi_gmem_awregion   ,
  output wire [1:0]                              m_axi_gmem_arburst    ,
  output wire [1:0]                              m_axi_gmem_arlock     ,
  output wire [3:0]                              m_axi_gmem_arcache    ,
  output wire [2:0]                              m_axi_gmem_arprot     ,
  output wire [3:0]                              m_axi_gmem_arqos      ,
  output wire [3:0]                              m_axi_gmem_arregion   ,

  // AXI4-Lite slave interface
  input  wire                                    s_axi_control_awvalid ,
  output wire                                    s_axi_control_awready ,
  input  wire [C_S_AXI_CONTROL_ADDR_WIDTH-1:0]   s_axi_control_awaddr  ,
  input  wire                                    s_axi_control_wvalid  ,
  output wire                                    s_axi_control_wready  ,
  input  wire [C_S_AXI_CONTROL_DATA_WIDTH-1:0]   s_axi_control_wdata   ,
  input  wire [C_S_AXI_CONTROL_DATA_WIDTH/8-1:0] s_axi_control_wstrb   ,
  input  wire                                    s_axi_control_arvalid ,
  output wire                                    s_axi_control_arready ,
  input  wire [C_S_AXI_CONTROL_ADDR_WIDTH-1:0]   s_axi_control_araddr  ,
  output wire                                    s_axi_control_rvalid  ,
  input  wire                                    s_axi_control_rready  ,
  output wire [C_S_AXI_CONTROL_DATA_WIDTH-1:0]   s_axi_control_rdata   ,
  output wire [1:0]                              s_axi_control_rresp   ,
  output wire                                    s_axi_control_bvalid  ,
  input  wire                                    s_axi_control_bready  ,
  output wire [1:0]                              s_axi_control_bresp   ,
  output wire                                    interrupt
);

// Tie-off unused AXI protocol features
assign m_axi_gmem_awid     = {C_M_AXI_GMEM_ID_WIDTH{1'b0}};
assign m_axi_gmem_awburst  = 2'b01   ;
assign m_axi_gmem_awlock   = 2'b00   ;
assign m_axi_gmem_awcache  = 4'b0011 ;
assign m_axi_gmem_awprot   = 3'b000  ;
assign m_axi_gmem_awqos    = 4'b0000 ;
assign m_axi_gmem_awregion = 4'b0000 ;
assign m_axi_gmem_arburst  = 2'b01   ;
assign m_axi_gmem_arlock   = 2'b00   ;
assign m_axi_gmem_arcache  = 4'b0011 ;
assign m_axi_gmem_arprot   = 3'b000  ;
assign m_axi_gmem_arqos    = 4'b0000 ;
assign m_axi_gmem_arregion = 4'b0000 ;

////////////////////////////////////////////////////////////////////////////////////////////////////
// Wires and Variables
////////////////////////////////////////////////////////////////////////////////////////////////////
wire            ap_start           ;
wire            ap_ready           ;
wire            ap_done            ;
wire            ap_idle     = 1'b1 ;
wire [32-1:0]   nfadata_cls        ;
wire [32-1:0]   queries_cls        ;
wire [32-1:0]   results_cls        ;
wire [64-1:0]   nfa_hash           ;
wire [64-1:0]   nfadata_ptr        ;
wire [64-1:0]   queries_ptr        ;
wire [64-1:0]   results_ptr        ;

////////////////////////////////////////////////////////////////////////////////////////////////////
// Begin control interface RTL
////////////////////////////////////////////////////////////////////////////////////////////////////

// AXI4-Lite slave interface
erbium_control_s_axi #(
  .C_S_AXI_ADDR_WIDTH( C_S_AXI_CONTROL_ADDR_WIDTH ),
  .C_S_AXI_DATA_WIDTH( C_S_AXI_CONTROL_DATA_WIDTH )
)
inst_control_s_axi (
  .aclk        ( ap_clk                ),
  .areset      ( ~ap_rst_n             ),
  .aclk_en     ( 1'b1                  ),
  .awvalid     ( s_axi_control_awvalid ),
  .awready     ( s_axi_control_awready ),
  .awaddr      ( s_axi_control_awaddr  ),
  .wvalid      ( s_axi_control_wvalid  ),
  .wready      ( s_axi_control_wready  ),
  .wdata       ( s_axi_control_wdata   ),
  .wstrb       ( s_axi_control_wstrb   ),
  .arvalid     ( s_axi_control_arvalid ),
  .arready     ( s_axi_control_arready ),
  .araddr      ( s_axi_control_araddr  ),
  .rvalid      ( s_axi_control_rvalid  ),
  .rready      ( s_axi_control_rready  ),
  .rdata       ( s_axi_control_rdata   ),
  .rresp       ( s_axi_control_rresp   ),
  .bvalid      ( s_axi_control_bvalid  ),
  .bready      ( s_axi_control_bready  ),
  .bresp       ( s_axi_control_bresp   ),
  .interrupt   ( interrupt             ),
  .ap_start    ( ap_start              ),
  .ap_ready    ( ap_ready              ),
  .ap_done     ( ap_done               ),
  .ap_idle     ( ap_idle               ),
  .nfadata_cls ( nfadata_cls           ),
  .queries_cls ( queries_cls           ),
  .results_cls ( results_cls           ),
  .nfa_hash    ( nfa_hash              ),
  .nfadata_ptr ( nfadata_ptr           ),
  .queries_ptr ( queries_ptr           ),
  .results_ptr ( results_ptr           )
);

////////////////////////////////////////////////////////////////////////////////////////////////////
// ERBIUM KERNEL
////////////////////////////////////////////////////////////////////////////////////////////////////

erbium_kernel #(
  .C_M_AXI_GMEM_ID_WIDTH   ( C_M_AXI_GMEM_ID_WIDTH   ),
  .C_M_AXI_GMEM_ADDR_WIDTH ( C_M_AXI_GMEM_ADDR_WIDTH ),
  .C_M_AXI_GMEM_DATA_WIDTH ( C_M_AXI_GMEM_DATA_WIDTH )
)
inst_erbium (
  .data_clk           ( ap_clk             ),
  .data_rst_n         ( ap_rst_n           ),
  .kernel_clk         ( ap_clk_2           ),
  .kernel_rst_n       ( ap_rst_n_2         ),
  .m_axi_gmem_awvalid ( m_axi_gmem_awvalid ),
  .m_axi_gmem_awready ( m_axi_gmem_awready ),
  .m_axi_gmem_awaddr  ( m_axi_gmem_awaddr  ),
  .m_axi_gmem_awlen   ( m_axi_gmem_awlen   ),
  .m_axi_gmem_awsize  ( m_axi_gmem_awsize  ),
  .m_axi_gmem_wvalid  ( m_axi_gmem_wvalid  ),
  .m_axi_gmem_wready  ( m_axi_gmem_wready  ),
  .m_axi_gmem_wdata   ( m_axi_gmem_wdata   ),
  .m_axi_gmem_wstrb   ( m_axi_gmem_wstrb   ),
  .m_axi_gmem_wlast   ( m_axi_gmem_wlast   ),
  .m_axi_gmem_arvalid ( m_axi_gmem_arvalid ),
  .m_axi_gmem_arready ( m_axi_gmem_arready ),
  .m_axi_gmem_araddr  ( m_axi_gmem_araddr  ),
  .m_axi_gmem_arid    ( m_axi_gmem_arid    ),
  .m_axi_gmem_arlen   ( m_axi_gmem_arlen   ),
  .m_axi_gmem_arsize  ( m_axi_gmem_arsize  ),
  .m_axi_gmem_rvalid  ( m_axi_gmem_rvalid  ),
  .m_axi_gmem_rready  ( m_axi_gmem_rready  ),
  .m_axi_gmem_rdata   ( m_axi_gmem_rdata   ),
  .m_axi_gmem_rlast   ( m_axi_gmem_rlast   ),
  .m_axi_gmem_rid     ( m_axi_gmem_rid     ),
  .m_axi_gmem_rresp   ( m_axi_gmem_rresp   ),
  .m_axi_gmem_bvalid  ( m_axi_gmem_bvalid  ),
  .m_axi_gmem_bready  ( m_axi_gmem_bready  ),
  .m_axi_gmem_bresp   ( m_axi_gmem_bresp   ),
  .m_axi_gmem_bid     ( m_axi_gmem_bid     ),
  .ap_start           ( ap_start           ),
  .ap_ready           ( ap_ready           ),
  .ap_done            ( ap_done            ),
  .ap_idle            ( ap_idle            ),
  .nfadata_cls        ( nfadata_cls        ),
  .queries_cls        ( queries_cls        ),
  .results_cls        ( results_cls        ),
  .nfa_hash           ( nfa_hash           ),
  .nfadata_ptr        ( nfadata_ptr        ),
  .queries_ptr        ( queries_ptr        ),
  .results_ptr        ( results_ptr        )
);

endmodule
`default_nettype wire