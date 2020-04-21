// ==============================================================
// Vivado(TM) HLS - High-Level Synthesis from C, C++ and SystemC v2019.2 (64-bit)
// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// ==============================================================
`timescale 1ns/1ps
module erbium_control_s_axi
#(parameter
    C_S_AXI_ADDR_WIDTH = 7,
    C_S_AXI_DATA_WIDTH = 32
)(
    // axi4 lite slave signals
    input  wire                          aclk,
    input  wire                          areset,
    input  wire                          aclk_en,
    input  wire [C_S_AXI_ADDR_WIDTH-1:0] awaddr,
    input  wire                          awvalid,
    output wire                          awready,
    input  wire [C_S_AXI_DATA_WIDTH-1:0] wdata,
    input  wire [C_S_AXI_DATA_WIDTH/8-1:0] wstrb,
    input  wire                          wvalid,
    output wire                          wready,
    output wire [1:0]                    bresp,
    output wire                          bvalid,
    input  wire                          bready,
    input  wire [C_S_AXI_ADDR_WIDTH-1:0] araddr,
    input  wire                          arvalid,
    output wire                          arready,
    output wire [C_S_AXI_DATA_WIDTH-1:0] rdata,
    output wire [1:0]                    rresp,
    output wire                          rvalid,
    input  wire                          rready,
    output wire                          interrupt,
    // control and user signals
    output wire                          ap_start,
    input  wire                          ap_done,
    input  wire                          ap_ready,
    input  wire                          ap_idle,
    output wire [31:0]                   nfadata_cls,
    output wire [31:0]                   queries_cls,
    output wire [31:0]                   results_cls,
    output wire [63:0]                   nfa_hash,
    output wire [63:0]                   nfadata_ptr,
    output wire [63:0]                   queries_ptr,
    output wire [63:0]                   results_ptr
);
//------------------------Address Info-------------------
// 0x00 : Control signals
//        bit 0  - ap_start (Read/Write/COH)
//        bit 1  - ap_done (Read/COR)
//        bit 2  - ap_idle (Read)
//        bit 3  - ap_ready (Read)
//        bit 7  - auto_restart (Read/Write)
//        others - reserved
// 0x04 : Global Interrupt Enable Register
//        bit 0  - Global Interrupt Enable (Read/Write)
//        others - reserved
// 0x08 : IP Interrupt Enable Register (Read/Write)
//        bit 0  - Channel 0 (ap_done)
//        bit 1  - Channel 1 (ap_ready)
//        others - reserved
// 0x0c : IP Interrupt Status Register (Read/TOW)
//        bit 0  - Channel 0 (ap_done)
//        bit 1  - Channel 1 (ap_ready)
//        others - reserved
// 0x10 : Data signal of nfadata_cls
//        bit 31~0 - nfadata_cls[31:0] (Read/Write)
// 0x14 : reserved
// 0x18 : Data signal of queries_cls
//        bit 31~0 - queries_cls[31:0] (Read/Write)
// 0x1c : reserved
// 0x20 : Data signal of results_cls
//        bit 31~0 - results_cls[31:0] (Read/Write)
// 0x24 : reserved
// 0x28 : Data signal of nfa_hash
//        bit 31~0 - nfa_hash[31:0] (Read/Write)
// 0x2c : Data signal of nfa_hash
//        bit 31~0 - nfa_hash[63:32] (Read/Write)
// 0x30 : reserved
// 0x34 : Data signal of nfadata_ptr
//        bit 31~0 - nfadata_ptr[31:0] (Read/Write)
// 0x38 : Data signal of nfadata_ptr
//        bit 31~0 - nfadata_ptr[63:32] (Read/Write)
// 0x3c : reserved
// 0x40 : Data signal of queries_ptr
//        bit 31~0 - queries_ptr[31:0] (Read/Write)
// 0x44 : Data signal of queries_ptr
//        bit 31~0 - queries_ptr[63:32] (Read/Write)
// 0x48 : reserved
// 0x4c : Data signal of results_ptr
//        bit 31~0 - results_ptr[31:0] (Read/Write)
// 0x50 : Data signal of results_ptr
//        bit 31~0 - results_ptr[63:32] (Read/Write)
// 0x54 : reserved
// (SC = Self Clear, COR = Clear on Read, TOW = Toggle on Write, COH = Clear on Handshake)

//------------------------Parameter----------------------
localparam
    ADDR_AP_CTRL            = 7'h00,
    ADDR_GIE                = 7'h04,
    ADDR_IER                = 7'h08,
    ADDR_ISR                = 7'h0c,
    ADDR_NFADATA_CLS_DATA_0 = 7'h10,
    ADDR_NFADATA_CLS_CTRL   = 7'h14,
    ADDR_QUERIES_CLS_DATA_0 = 7'h18,
    ADDR_QUERIES_CLS_CTRL   = 7'h1c,
    ADDR_RESULTS_CLS_DATA_0 = 7'h20,
    ADDR_RESULTS_CLS_CTRL   = 7'h24,
    ADDR_NFA_HASH_DATA_0    = 7'h28,
    ADDR_NFA_HASH_DATA_1    = 7'h2c,
    ADDR_NFA_HASH_CTRL      = 7'h30,
    ADDR_NFADATA_PTR_DATA_0 = 7'h34,
    ADDR_NFADATA_PTR_DATA_1 = 7'h38,
    ADDR_NFADATA_PTR_CTRL   = 7'h3c,
    ADDR_QUERIES_PTR_DATA_0 = 7'h40,
    ADDR_QUERIES_PTR_DATA_1 = 7'h44,
    ADDR_QUERIES_PTR_CTRL   = 7'h48,
    ADDR_RESULTS_PTR_DATA_0 = 7'h4c,
    ADDR_RESULTS_PTR_DATA_1 = 7'h50,
    ADDR_RESULTS_PTR_CTRL   = 7'h54,
    WRIDLE                  = 2'd0,
    WRDATA                  = 2'd1,
    WRRESP                  = 2'd2,
    WRRESET                 = 2'd3,
    RDIDLE                  = 2'd0,
    RDDATA                  = 2'd1,
    RDRESET                 = 2'd2,
    ADDR_BITS               = 7;

//------------------------Local signal-------------------
    reg  [1:0]                    wstate = WRRESET;
    reg  [1:0]                    wnext;
    reg  [ADDR_BITS-1:0]          waddr;
    wire [31:0]                   wmask;
    wire                          aw_hs;
    wire                          w_hs;
    reg  [1:0]                    rstate = RDRESET;
    reg  [1:0]                    rnext;
    reg  [31:0]                   rdata_r;
    wire                          ar_hs;
    wire [ADDR_BITS-1:0]          raddr;
    // internal registers
    reg                           int_ap_idle;
    reg                           int_ap_ready;
    reg                           int_ap_done = 1'b0;
    reg                           int_ap_start = 1'b0;
    reg                           int_auto_restart = 1'b0;
    reg                           int_gie = 1'b0;
    reg  [1:0]                    int_ier = 2'b0;
    reg  [1:0]                    int_isr = 2'b0;
    reg  [31:0]                   int_nfadata_cls = 'b0;
    reg  [31:0]                   int_queries_cls = 'b0;
    reg  [31:0]                   int_results_cls = 'b0;
    reg  [63:0]                   int_nfa_hash = 'b0;
    reg  [63:0]                   int_nfadata_ptr = 'b0;
    reg  [63:0]                   int_queries_ptr = 'b0;
    reg  [63:0]                   int_results_ptr = 'b0;

//------------------------Instantiation------------------

//------------------------AXI write fsm------------------
assign awready = (wstate == WRIDLE);
assign wready  = (wstate == WRDATA);
assign bresp   = 2'b00;  // OKAY
assign bvalid  = (wstate == WRRESP);
assign wmask   = { {8{wstrb[3]}}, {8{wstrb[2]}}, {8{wstrb[1]}}, {8{wstrb[0]}} };
assign aw_hs   = awvalid & awready;
assign w_hs    = wvalid & wready;

// wstate
always @(posedge aclk) begin
    if (areset)
        wstate <= WRRESET;
    else if (aclk_en)
        wstate <= wnext;
end

// wnext
always @(*) begin
    case (wstate)
        WRIDLE:
            if (awvalid)
                wnext = WRDATA;
            else
                wnext = WRIDLE;
        WRDATA:
            if (wvalid)
                wnext = WRRESP;
            else
                wnext = WRDATA;
        WRRESP:
            if (bready)
                wnext = WRIDLE;
            else
                wnext = WRRESP;
        default:
            wnext = WRIDLE;
    endcase
end

// waddr
always @(posedge aclk) begin
    if (aclk_en) begin
        if (aw_hs)
            waddr <= awaddr[ADDR_BITS-1:0];
    end
end

//------------------------AXI read fsm-------------------
assign arready = (rstate == RDIDLE);
assign rdata   = rdata_r;
assign rresp   = 2'b00;  // OKAY
assign rvalid  = (rstate == RDDATA);
assign ar_hs   = arvalid & arready;
assign raddr   = araddr[ADDR_BITS-1:0];

// rstate
always @(posedge aclk) begin
    if (areset)
        rstate <= RDRESET;
    else if (aclk_en)
        rstate <= rnext;
end

// rnext
always @(*) begin
    case (rstate)
        RDIDLE:
            if (arvalid)
                rnext = RDDATA;
            else
                rnext = RDIDLE;
        RDDATA:
            if (rready & rvalid)
                rnext = RDIDLE;
            else
                rnext = RDDATA;
        default:
            rnext = RDIDLE;
    endcase
end

// rdata_r
always @(posedge aclk) begin
    if (aclk_en) begin
        if (ar_hs) begin
            rdata_r <= 1'b0;
            case (raddr)
                ADDR_AP_CTRL: begin
                    rdata_r[0] <= int_ap_start;
                    rdata_r[1] <= int_ap_done;
                    rdata_r[2] <= int_ap_idle;
                    rdata_r[3] <= int_ap_ready;
                    rdata_r[7] <= int_auto_restart;
                end
                ADDR_GIE: begin
                    rdata_r <= int_gie;
                end
                ADDR_IER: begin
                    rdata_r <= int_ier;
                end
                ADDR_ISR: begin
                    rdata_r <= int_isr;
                end
                ADDR_NFADATA_CLS_DATA_0: begin
                    rdata_r <= int_nfadata_cls[31:0];
                end
                ADDR_QUERIES_CLS_DATA_0: begin
                    rdata_r <= int_queries_cls[31:0];
                end
                ADDR_RESULTS_CLS_DATA_0: begin
                    rdata_r <= int_results_cls[31:0];
                end
                ADDR_NFA_HASH_DATA_0: begin
                    rdata_r <= int_nfa_hash[31:0];
                end
                ADDR_NFA_HASH_DATA_1: begin
                    rdata_r <= int_nfa_hash[63:32];
                end
                ADDR_NFADATA_PTR_DATA_0: begin
                    rdata_r <= int_nfadata_ptr[31:0];
                end
                ADDR_NFADATA_PTR_DATA_1: begin
                    rdata_r <= int_nfadata_ptr[63:32];
                end
                ADDR_QUERIES_PTR_DATA_0: begin
                    rdata_r <= int_queries_ptr[31:0];
                end
                ADDR_QUERIES_PTR_DATA_1: begin
                    rdata_r <= int_queries_ptr[63:32];
                end
                ADDR_RESULTS_PTR_DATA_0: begin
                    rdata_r <= int_results_ptr[31:0];
                end
                ADDR_RESULTS_PTR_DATA_1: begin
                    rdata_r <= int_results_ptr[63:32];
                end
            endcase
        end
    end
end


//------------------------Register logic-----------------
assign interrupt   = int_gie & (|int_isr);
assign ap_start    = int_ap_start;
assign nfadata_cls = int_nfadata_cls;
assign queries_cls = int_queries_cls;
assign results_cls = int_results_cls;
assign nfa_hash    = int_nfa_hash;
assign nfadata_ptr = int_nfadata_ptr;
assign queries_ptr = int_queries_ptr;
assign results_ptr = int_results_ptr;
// int_ap_start
always @(posedge aclk) begin
    if (areset)
        int_ap_start <= 1'b0;
    else if (aclk_en) begin
        if (w_hs && waddr == ADDR_AP_CTRL && wstrb[0] && wdata[0])
            int_ap_start <= 1'b1;
        else if (ap_ready)
            int_ap_start <= int_auto_restart; // clear on handshake/auto restart
    end
end

// int_ap_done
always @(posedge aclk) begin
    if (areset)
        int_ap_done <= 1'b0;
    else if (aclk_en) begin
        if (ap_done)
            int_ap_done <= 1'b1;
        else if (ar_hs && raddr == ADDR_AP_CTRL)
            int_ap_done <= 1'b0; // clear on read
    end
end

// int_ap_idle
always @(posedge aclk) begin
    if (areset)
        int_ap_idle <= 1'b0;
    else if (aclk_en) begin
            int_ap_idle <= ap_idle;
    end
end

// int_ap_ready
always @(posedge aclk) begin
    if (areset)
        int_ap_ready <= 1'b0;
    else if (aclk_en) begin
            int_ap_ready <= ap_ready;
    end
end

// int_auto_restart
always @(posedge aclk) begin
    if (areset)
        int_auto_restart <= 1'b0;
    else if (aclk_en) begin
        if (w_hs && waddr == ADDR_AP_CTRL && wstrb[0])
            int_auto_restart <=  wdata[7];
    end
end

// int_gie
always @(posedge aclk) begin
    if (areset)
        int_gie <= 1'b0;
    else if (aclk_en) begin
        if (w_hs && waddr == ADDR_GIE && wstrb[0])
            int_gie <= wdata[0];
    end
end

// int_ier
always @(posedge aclk) begin
    if (areset)
        int_ier <= 1'b0;
    else if (aclk_en) begin
        if (w_hs && waddr == ADDR_IER && wstrb[0])
            int_ier <= wdata[1:0];
    end
end

// int_isr[0]
always @(posedge aclk) begin
    if (areset)
        int_isr[0] <= 1'b0;
    else if (aclk_en) begin
        if (int_ier[0] & ap_done)
            int_isr[0] <= 1'b1;
        else if (w_hs && waddr == ADDR_ISR && wstrb[0])
            int_isr[0] <= int_isr[0] ^ wdata[0]; // toggle on write
    end
end

// int_isr[1]
always @(posedge aclk) begin
    if (areset)
        int_isr[1] <= 1'b0;
    else if (aclk_en) begin
        if (int_ier[1] & ap_ready)
            int_isr[1] <= 1'b1;
        else if (w_hs && waddr == ADDR_ISR && wstrb[0])
            int_isr[1] <= int_isr[1] ^ wdata[1]; // toggle on write
    end
end

// int_nfadata_cls[31:0]
always @(posedge aclk) begin
    if (areset)
        int_nfadata_cls[31:0] <= 0;
    else if (aclk_en) begin
        if (w_hs && waddr == ADDR_NFADATA_CLS_DATA_0)
            int_nfadata_cls[31:0] <= (wdata[31:0] & wmask) | (int_nfadata_cls[31:0] & ~wmask);
    end
end

// int_queries_cls[31:0]
always @(posedge aclk) begin
    if (areset)
        int_queries_cls[31:0] <= 0;
    else if (aclk_en) begin
        if (w_hs && waddr == ADDR_QUERIES_CLS_DATA_0)
            int_queries_cls[31:0] <= (wdata[31:0] & wmask) | (int_queries_cls[31:0] & ~wmask);
    end
end

// int_results_cls[31:0]
always @(posedge aclk) begin
    if (areset)
        int_results_cls[31:0] <= 0;
    else if (aclk_en) begin
        if (w_hs && waddr == ADDR_RESULTS_CLS_DATA_0)
            int_results_cls[31:0] <= (wdata[31:0] & wmask) | (int_results_cls[31:0] & ~wmask);
    end
end

// int_nfa_hash[31:0]
always @(posedge aclk) begin
    if (areset)
        int_nfa_hash[31:0] <= 0;
    else if (aclk_en) begin
        if (w_hs && waddr == ADDR_NFA_HASH_DATA_0)
            int_nfa_hash[31:0] <= (wdata[31:0] & wmask) | (int_nfa_hash[31:0] & ~wmask);
    end
end

// int_nfa_hash[63:32]
always @(posedge aclk) begin
    if (areset)
        int_nfa_hash[63:32] <= 0;
    else if (aclk_en) begin
        if (w_hs && waddr == ADDR_NFA_HASH_DATA_1)
            int_nfa_hash[63:32] <= (wdata[31:0] & wmask) | (int_nfa_hash[63:32] & ~wmask);
    end
end

// int_nfadata_ptr[31:0]
always @(posedge aclk) begin
    if (areset)
        int_nfadata_ptr[31:0] <= 0;
    else if (aclk_en) begin
        if (w_hs && waddr == ADDR_NFADATA_PTR_DATA_0)
            int_nfadata_ptr[31:0] <= (wdata[31:0] & wmask) | (int_nfadata_ptr[31:0] & ~wmask);
    end
end

// int_nfadata_ptr[63:32]
always @(posedge aclk) begin
    if (areset)
        int_nfadata_ptr[63:32] <= 0;
    else if (aclk_en) begin
        if (w_hs && waddr == ADDR_NFADATA_PTR_DATA_1)
            int_nfadata_ptr[63:32] <= (wdata[31:0] & wmask) | (int_nfadata_ptr[63:32] & ~wmask);
    end
end

// int_queries_ptr[31:0]
always @(posedge aclk) begin
    if (areset)
        int_queries_ptr[31:0] <= 0;
    else if (aclk_en) begin
        if (w_hs && waddr == ADDR_QUERIES_PTR_DATA_0)
            int_queries_ptr[31:0] <= (wdata[31:0] & wmask) | (int_queries_ptr[31:0] & ~wmask);
    end
end

// int_queries_ptr[63:32]
always @(posedge aclk) begin
    if (areset)
        int_queries_ptr[63:32] <= 0;
    else if (aclk_en) begin
        if (w_hs && waddr == ADDR_QUERIES_PTR_DATA_1)
            int_queries_ptr[63:32] <= (wdata[31:0] & wmask) | (int_queries_ptr[63:32] & ~wmask);
    end
end

// int_results_ptr[31:0]
always @(posedge aclk) begin
    if (areset)
        int_results_ptr[31:0] <= 0;
    else if (aclk_en) begin
        if (w_hs && waddr == ADDR_RESULTS_PTR_DATA_0)
            int_results_ptr[31:0] <= (wdata[31:0] & wmask) | (int_results_ptr[31:0] & ~wmask);
    end
end

// int_results_ptr[63:32]
always @(posedge aclk) begin
    if (areset)
        int_results_ptr[63:32] <= 0;
    else if (aclk_en) begin
        if (w_hs && waddr == ADDR_RESULTS_PTR_DATA_1)
            int_results_ptr[63:32] <= (wdata[31:0] & wmask) | (int_results_ptr[63:32] & ~wmask);
    end
end


//------------------------Memory logic-------------------

endmodule