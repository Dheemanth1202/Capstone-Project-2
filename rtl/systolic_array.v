// =============================================================================
// Module      : systolic_array
// Description : NxN Systolic Array Multiplier — Correct Architecture
//
//  Uses the standard "AND-array + ripple-carry accumulation" approach:
//
//  Step 1: Generate all N×N partial product bits pp[i][j] = a[i] & b[j]
//          Bit pp[i][j] has weight 2^(i+j).
//
//  Step 2: Accumulate row by row using an N-bit ripple-carry adder:
//          acc[0]   = { pp[0][N-1], ..., pp[0][0] }         (row 0)
//          acc[1]   = acc[0] + (pp[1] << 1)                 (row 1 shifted)
//          acc[i]   = acc[i-1] + (pp[i] << i)               (row i shifted)
//          acc[N-1] = final product
//
//  The "shift" is achieved by wiring the accumulator correctly:
//    - The lowest i bits of the product are frozen from previous rows
//    - The adder at row i only sees bits [2N-1 : i]
//
//  This is equivalent to the standard array multiplier topology used in
//  textbooks and is often called a "carry-save array multiplier".
//
// Parameters  : N          - operand width (default = 8)
// Inputs      : a[N-1:0], b[N-1:0]
// Outputs     : product[2*N-1:0]  - full unsigned product
// =============================================================================

`timescale 1ns / 1ps

module systolic_array #(
    parameter N = 8
)(
    input  wire [N-1:0]     a,
    input  wire [N-1:0]     b,

    output wire [2*N-1:0]   product
);

    // =========================================================================
    // Partial product array: pp[i][j] = a[i] & b[j], weight 2^(i+j)
    // =========================================================================
    wire pp [0:N-1][0:N-1];

    genvar i, j;

    generate
        for (i = 0; i < N; i = i + 1) begin : pp_row
            for (j = 0; j < N; j = j + 1) begin : pp_col
                assign pp[i][j] = a[i] & b[j];
            end
        end
    endgenerate

    // =========================================================================
    // Accumulator array:
    //   acc[row][bit]  — 2N bits wide to hold full result
    //   acc[0]  is just the first partial product row (row 0) zero-padded
    //   acc[i]  = acc[i-1] + (row_i partial product shifted left by i bits)
    // =========================================================================
    wire [2*N-1:0] acc [0:N-1];

    // Row 0: no addition needed — just place pp[0][j] at bit j
    generate
        for (j = 0; j < N; j = j + 1) begin : acc0
            assign acc[0][j] = pp[0][j];
        end
        for (j = N; j < 2*N; j = j + 1) begin : acc0_high
            assign acc[0][j] = 1'b0;
        end
    endgenerate

    // =========================================================================
    // Row-by-row adder: for row i (1..N-1)
    //   Add pp[i][j] (at bit position i+j) to acc[i-1]
    //
    //   We instantiate an (N+1)-bit ripple-carry adder for bits [i+N : i]
    //   (the N active bits of row i plus the carry-out bit).
    //   Bits [i-1 : 0] of acc[i-1] are unchanged (already frozen).
    // =========================================================================

    // carry_row[i][k] = carry wire for row-i adder at bit position k
    // We need carries for N+1 positions per row
    wire carry_row [1:N-1][0:N];

    // sum_row[i][k] = sum bit for row-i adder at position k within the adder
    wire sum_row   [1:N-1][0:N-1];

    generate
        for (i = 1; i < N; i = i + 1) begin : row_adder

            // No carry in from left
            assign carry_row[i][0] = 1'b0;

            // N full adders: bit position (i + j), j = 0..N-1
            for (j = 0; j < N; j = j + 1) begin : fa_cells
                full_adder FA (
                    .a    (acc[i-1][i + j]),    // Previous accumulator bit at weight 2^(i+j)
                    .b    (pp[i][j]),            // Current row pp bit at weight 2^(i+j)
                    .cin  (carry_row[i][j]),
                    .sum  (sum_row[i][j]),
                    .cout (carry_row[i][j+1])
                );
            end

            // Assemble acc[i]:
            //   bits [i-1 : 0]       = unchanged from acc[i-1]
            //   bits [i+N-1 : i]     = sum_row[i]
            //   bits [2N-1 : i+N]    = carry propagation
            for (j = 0; j < i; j = j + 1) begin : acc_low
                assign acc[i][j] = acc[i-1][j];
            end
            for (j = 0; j < N; j = j + 1) begin : acc_mid
                assign acc[i][i + j] = sum_row[i][j];
            end
            // MSB carry-out from the adder goes to bit i+N
            assign acc[i][i + N] = carry_row[i][N];
            // Any bits above i+N are zero (no more rows contribute here)
            for (j = i + N + 1; j < 2*N; j = j + 1) begin : acc_high
                assign acc[i][j] = 1'b0;
            end

        end
    endgenerate

    // =========================================================================
    // Final product = last accumulator row
    // =========================================================================
    assign product = acc[N-1];

endmodule
