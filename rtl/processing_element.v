`timescale 1ns / 1ps

module processing_element (
    input  wire clk,
    input  wire rst,

    input  wire a_in,       
    input  wire b_in,       


    input  wire p_in,       
    input  wire c_in,       


    output wire a_out,
    output wire b_out,
    output wire p_out,
    output wire c_out
);

    wire and_bit;
    wire fa_sum;
    wire fa_cout;

    assign and_bit = a_in & b_in;

    full_adder FA (
        .a    (and_bit),
        .b    (p_in),
        .cin  (c_in),
        .sum  (fa_sum),
        .cout (fa_cout)
    );

    register #(.WIDTH(1)) REG_A (
        .clk (clk),
        .rst (rst),
        .d   (a_in),
        .q   (a_out)
    );

    register #(.WIDTH(1)) REG_B (
        .clk (clk),
        .rst (rst),
        .d   (b_in),
        .q   (b_out)
    );

    register #(.WIDTH(1)) REG_P (
        .clk (clk),
        .rst (rst),
        .d   (fa_sum),
        .q   (p_out)
    );

    register #(.WIDTH(1)) REG_C (
        .clk (clk),
        .rst (rst),
        .d   (fa_cout),
        .q   (c_out)
    );

endmodule
