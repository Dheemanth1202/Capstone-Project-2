`timescale 1ns / 1ps

module systolic_top #(
    parameter N = 8
)(
    input  wire             clk,
    input  wire             rst,
    input  wire             start,

    input  wire [N-1:0]     a,              // Multiplicand
    input  wire [N-1:0]     b,              // Multiplier

    output wire [2*N-1:0]   product,        // Final 2N-bit product
    output wire             valid,          // Result valid flag
    output wire             busy            // Computation busy flag
);

    wire             load_en;
    reg  [N-1:0]     a_reg, b_reg;

    wire [2*N-1:0]   array_product;         // Full 2N-bit result from array

    control_unit #(.N(N)) CU (
        .clk       (clk),
        .rst       (rst),
        .start     (start),
        .load      (load_en),
        .busy      (busy),
        .valid_out (valid)
    );

    always @(posedge clk) begin
        if (rst) begin
            a_reg <= {N{1'b0}};
            b_reg <= {N{1'b0}};
        end else if (load_en) begin
            a_reg <= a;
            b_reg <= b;
        end
    end

    systolic_array #(.N(N)) SA (
        .a          (a_reg),
        .b          (b_reg),
        .product    (array_product)
    );

    // product is directly the combinational output of the array
    assign product = array_product;

endmodule
