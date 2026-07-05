// Quick debug: probe array_product and control signals directly
`timescale 1ns/1ps
module dbg2;
    parameter N = 8;
    reg [N-1:0] a, b;
    wire [2*N-1:0] prod;
    systolic_array #(.N(N)) DUT(.a(a),.b(b),.product(prod));

    initial begin
        a = 8'd3; b = 8'd5;
        #1;
        $display("3 x 5 = %0d (expect 15)", prod);
        a = 8'd255; b = 8'd255;
        #1;
        $display("255 x 255 = %0d (expect 65025)", prod);
        a = 8'd12; b = 8'd13;
        #1;
        $display("12 x 13 = %0d (expect 156)", prod);
        $finish;
    end
endmodule
