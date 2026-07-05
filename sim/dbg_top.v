// Minimal focused debug TB
`timescale 1ns / 1ps
module dbg_top;
    parameter N = 8;
    reg clk, rst, start;
    reg [N-1:0] a_in, b_in;
    wire [2*N-1:0] product;
    wire valid, busy;

    systolic_top #(.N(N)) DUT (
        .clk(clk), .rst(rst), .start(start),
        .a(a_in), .b(b_in),
        .product(product), .valid(valid), .busy(busy)
    );

    // Monitor internals
    wire [N-1:0] a_reg = DUT.a_reg;
    wire [N-1:0] b_reg = DUT.b_reg;
    wire [2*N-1:0] arr_prod = DUT.array_product;
    wire load_en = DUT.load_en;

    initial clk = 0;
    always #5 clk = ~clk;

    integer t;
    initial begin
        rst=1; start=0; a_in=0; b_in=0;
        repeat(4) @(posedge clk); #1;
        rst = 0;
        @(posedge clk); #1;

        $display("--- Starting multiplication 12 x 13 ---");
        a_in = 12; b_in = 13;
        start = 1;
        @(posedge clk); #1;
        start = 0;

        // Watch every cycle
        for (t = 0; t < 25; t = t + 1) begin
            $display("t=%0d: load=%b busy=%b valid=%b | a_reg=%0d b_reg=%0d | arr_prod=%0d product=%0d",
                t, load_en, busy, valid, a_reg, b_reg, arr_prod, product);
            @(posedge clk); #1;
        end
        $finish;
    end
endmodule
