
module nfabre_testbench();
    reg            sys_clk, sys_rst, z_en = 1'b0;
    reg      [7:0] query_rule, query_mrkta, query_mrktb, query_datea, query_dateb, query_cabin, query_opair, query_flgrp, query_bkg;
    reg  [(8*9)-1:0] queries;
    reg    [200:0] z_mem = 201'd0;
    wire   [157:0] result;

    top_bram (
        .clk_i(sys_clk),
        .rst_i(sys_rst),
        .query_i(queries),
        .result_o(result),
        .mem_i(z_mem),
        .meme_i(z_en)
    );

    assign {queries} = {query_rule &
            query_mrkta &
            query_mrktb &
            query_datea &
            query_dateb &
            query_cabin &
            query_opair &
            query_flgrp &
            query_bkg};

    initial begin
        query_rule  = 8'h00;
        query_mrkta = 8'h00;
        query_mrktb = 8'h00;
        query_datea = 8'h00;
        query_dateb = 8'h00;
        query_cabin = 8'h00;
        query_opair = 8'h00;
        query_flgrp = 8'h00;
        query_bkg   = 8'h00;
        #20
        query_rule  = 8'h00;
        query_mrkta = 8'h00;
        query_mrktb = 8'h00;
        query_datea = 8'h00;
        query_dateb = 8'h00;
        query_cabin = 8'h00;
        query_opair = 8'h00;
        query_flgrp = 8'h00;
        query_bkg   = 8'h00;
        #20
        query_rule  = 8'h00;
        query_mrkta = 8'h00;
        query_mrktb = 8'h00;
        query_datea = 8'h00;
        query_dateb = 8'h00;
        query_cabin = 8'h00;
        query_opair = 8'h00;
        query_flgrp = 8'h00;
        query_bkg   = 8'h00;
        #20
        query_rule  = 8'h00;
        query_mrkta = 8'h00;
        query_mrktb = 8'h00;
        query_datea = 8'h00;
        query_dateb = 8'h00;
        query_cabin = 8'h00;
        query_opair = 8'h00;
        query_flgrp = 8'h00;
        query_bkg   = 8'h00;
        #20
        query_rule  = 8'h00;
        query_mrkta = 8'h00;
        query_mrktb = 8'h00;
        query_datea = 8'h00;
        query_dateb = 8'h00;
        query_cabin = 8'h00;
        query_opair = 8'h00;
        query_flgrp = 8'h00;
        query_bkg   = 8'h00;
        #20
        $finish;
    end

    always begin
        // 10ns period
        sys_clk = 1; #5;
        sys_clk = 0; #5;
    end
    
    initial begin
        sys_rst = 1; #10;
        sys_rst = 0;
    end

endmodule