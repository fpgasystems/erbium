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

module xdma_axi_read_master #( 
  parameter integer C_ADDR_WIDTH       = 64,
  parameter integer C_DATA_WIDTH       = 32,
  parameter integer C_LENGTH_WIDTH     = 32,  
  parameter integer C_BURST_LEN        = 256, // Max AXI burst length for read commands
  parameter integer C_LOG_BURST_LEN    = 8,
  parameter integer C_MAX_OUTSTANDING  = 3 
)
(
  // System signals
  input  wire                       aclk,
  input  wire                       areset,
  // Control signals 
  input  wire                       ctrl_start, 
  output wire                       ctrl_done, 
  input  wire [C_ADDR_WIDTH-1:0]    ctrl_offset,
  input  wire [C_LENGTH_WIDTH-1:0]  ctrl_length,
  input  wire                       ctrl_prog_full,
  // AXI4 master interface                             
  output wire                       arvalid,
  input  wire                       arready,
  output wire [C_ADDR_WIDTH-1:0]    araddr,
  output wire [7:0]                 arlen,
  output wire [2:0]                 arsize,
  input  wire                       rvalid,
  output wire                       rready,
  input  wire [C_DATA_WIDTH - 1:0]  rdata,
  input  wire                       rlast,
  input  wire [1:0]                 rresp,
  // AXI4-Stream master interface
  output wire                       m_tvalid,
  input  wire                       m_tready,
  output wire [C_DATA_WIDTH-1:0]    m_tdata
);

///////////////////////////////////////////////////////////////////////////////
// Local Parameters
///////////////////////////////////////////////////////////////////////////////
localparam integer LP_MAX_OUTSTANDING_CNTR_WIDTH = $clog2(C_MAX_OUTSTANDING+1); 
localparam integer LP_TRANSACTION_CNTR_WIDTH = C_LENGTH_WIDTH-C_LOG_BURST_LEN;

///////////////////////////////////////////////////////////////////////////////
// Variables
///////////////////////////////////////////////////////////////////////////////
// Control logic
logic                                      done      = '0             ;
logic [LP_TRANSACTION_CNTR_WIDTH-1:0]      num_full_bursts            ;
logic                                      num_partial_bursts         ;
logic                                      start     = 1'b0           ;
logic [LP_TRANSACTION_CNTR_WIDTH-1:0]      num_transactions           ;
logic                                      has_partial_burst          ;
logic [C_LOG_BURST_LEN-1:0]                final_burst_len            ;
logic                                      single_transaction         ;
logic                                      ar_idle   = 1'b1           ;
logic                                      ar_done                    ;
// AXI Read Address Channel
logic                                      fifo_stall                 ;
logic                                      arxfer                     ;
logic                                      arvalid_r = 1'b0           ;
logic [C_ADDR_WIDTH-1:0]                   addr                       ;
logic [LP_TRANSACTION_CNTR_WIDTH-1:0]      ar_transactions_to_go      ;
logic                                      ar_final_transaction       ;
logic                                      incr_ar_to_r_cnt           ;
logic                                      decr_ar_to_r_cnt           ;
logic                                      stall_ar                   ;
logic [LP_MAX_OUTSTANDING_CNTR_WIDTH-1:0]  outstanding_vacancy_count  ;
// AXI Data Channel
logic                                      tvalid                     ;
logic [C_DATA_WIDTH-1:0]                   tdata                      ;
logic                                      rxfer                      ;
logic                                      decr_r_transaction_cntr    ;
logic [LP_TRANSACTION_CNTR_WIDTH-1:0]      r_transactions_to_go       ;
logic                                      r_final_transaction        ;
///////////////////////////////////////////////////////////////////////////////
// Control Logic 
///////////////////////////////////////////////////////////////////////////////

always @(posedge aclk) begin
  done <= rxfer & rlast & r_final_transaction ? 1'b1 : 
          ctrl_done ? 1'b0 : done; 
end
assign ctrl_done = &done;

// Determine how many full burst to issue and if there are any partial bursts.
assign num_full_bursts = ctrl_length[C_LOG_BURST_LEN+:C_LENGTH_WIDTH-C_LOG_BURST_LEN];
assign num_partial_bursts = ctrl_length[0+:C_LOG_BURST_LEN] ? 1'b1 : 1'b0; 

always @(posedge aclk) begin 
  start <= ctrl_start;
  num_transactions <= (num_partial_bursts == 1'b0) ? num_full_bursts - 1'b1 : num_full_bursts;
  has_partial_burst <= num_partial_bursts;
  final_burst_len <=  ctrl_length[0+:C_LOG_BURST_LEN] - 1'b1;
end

// Special case if there is only 1 AXI transaction. 
assign single_transaction = (num_transactions == {LP_TRANSACTION_CNTR_WIDTH{1'b0}}) ? 1'b1 : 1'b0;

///////////////////////////////////////////////////////////////////////////////
// AXI Read Address Channel
///////////////////////////////////////////////////////////////////////////////
assign arvalid = arvalid_r;
assign araddr = addr;
assign arlen  = ar_final_transaction || (start & single_transaction) ? final_burst_len : C_BURST_LEN - 1;
assign arsize = $clog2((C_DATA_WIDTH/8));

assign arxfer = arvalid & arready;
assign fifo_stall = ctrl_prog_full;

always @(posedge aclk) begin 
  if (areset) begin 
    arvalid_r <= 1'b0;
  end
  else begin
    arvalid_r <= ~ar_idle & ~stall_ar & ~arvalid_r & ~fifo_stall ? 1'b1 : 
                 arready ? 1'b0 : arvalid_r;
  end
end

// When ar_idle, there are no transactions to issue.
always @(posedge aclk) begin 
  if (areset) begin 
    ar_idle <= 1'b1; 
  end
  else begin 
    ar_idle <= start   ? 1'b0 :
               ar_done ? 1'b1 : 
                         ar_idle;
  end
end

// Increment to next address after each transaction is issued.
always @(posedge aclk) begin 
    addr <= ctrl_start ? ctrl_offset :
            arxfer     ? addr + C_BURST_LEN*C_DATA_WIDTH/8 : 
                         addr;
end

// Counts down the number of transactions to send.
xdma_counter #(
  .C_WIDTH ( LP_TRANSACTION_CNTR_WIDTH         ) ,
  .C_INIT  ( {LP_TRANSACTION_CNTR_WIDTH{1'b0}} ) 
)
inst_ar_transaction_cntr ( 
  .clk        ( aclk                   ) ,
  .clken      ( 1'b1                   ) ,
  .rst        ( areset                 ) ,
  .load       ( start                  ) ,
  .incr       ( 1'b0                   ) ,
  .decr       ( arxfer                 ) ,
  .load_value ( num_transactions       ) ,
  .count      ( ar_transactions_to_go  ) ,
  .is_zero    ( ar_final_transaction   ) 
);

assign ar_done = ar_final_transaction && arxfer;

always_comb begin 
    incr_ar_to_r_cnt = rxfer & rlast;
    decr_ar_to_r_cnt = arxfer;
end

// Keeps track of the number of outstanding transactions. Stalls 
// when the value is reached so that the FIFO won't overflow.
xdma_counter #(
  .C_WIDTH ( LP_MAX_OUTSTANDING_CNTR_WIDTH                       ) ,
  .C_INIT  ( C_MAX_OUTSTANDING[0+:LP_MAX_OUTSTANDING_CNTR_WIDTH] ) 
)
inst_ar_to_r_transaction_cntr ( 
  .clk        ( aclk                           ) ,
  .clken      ( 1'b1                           ) ,
  .rst        ( areset                         ) ,
  .load       ( 1'b0                           ) ,
  .incr       ( incr_ar_to_r_cnt               ) ,
  .decr       ( decr_ar_to_r_cnt               ) ,
  .load_value ( {LP_MAX_OUTSTANDING_CNTR_WIDTH{1'b0}} ) ,
  .count      ( outstanding_vacancy_count      ) ,
  .is_zero    ( stall_ar                       ) 
);

///////////////////////////////////////////////////////////////////////////////
// AXI Read Channel
///////////////////////////////////////////////////////////////////////////////
assign m_tvalid = rvalid;
assign m_tdata = rdata;


// rready can remain high for optimal timing because ar transactions are not issued
// unless there is enough space in the FIFO.
assign rready = 1'b1;
assign rxfer = rready & rvalid;

always_comb begin 
  decr_r_transaction_cntr = rxfer & rlast;
end
xdma_counter #(
  .C_WIDTH ( LP_TRANSACTION_CNTR_WIDTH         ) ,
  .C_INIT  ( {LP_TRANSACTION_CNTR_WIDTH{1'b0}} ) 
)
inst_r_transaction_cntr ( 
  .clk        ( aclk                          ) ,
  .clken      ( 1'b1                          ) ,
  .rst        ( areset                        ) ,
  .load       ( start                         ) ,
  .incr       ( 1'b0                          ) ,
  .decr       ( decr_r_transaction_cntr       ) ,
  .load_value ( num_transactions              ) ,
  .count      ( r_transactions_to_go          ) ,
  .is_zero    ( r_final_transaction           ) 
);

endmodule : xdma_axi_read_master

`default_nettype wire