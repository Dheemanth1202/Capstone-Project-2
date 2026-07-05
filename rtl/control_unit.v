`timescale 1ns / 1ps

module control_unit #(
    parameter N = 8
)(
    input  wire clk,
    input  wire rst,
    input  wire start,

    output reg  load,
    output reg  busy,
    output reg  valid_out
);

    localparam LATENCY = (2 * N) - 1;


    localparam CNT_W = $clog2(LATENCY + 1);

    reg [CNT_W-1:0] cycle_cnt;


    localparam IDLE    = 2'b00;
    localparam LOAD_ST = 2'b01;
    localparam COMPUTE = 2'b10;
    localparam DONE    = 2'b11;

    reg [1:0] state, next_state;


    always @(posedge clk) begin
        if (rst)
            state <= IDLE;
        else
            state <= next_state;
    end


    always @(*) begin
        next_state = state;
        case (state)
            IDLE:    if (start)                      next_state = LOAD_ST;
            LOAD_ST:                                 next_state = COMPUTE;
            COMPUTE: if (cycle_cnt == LATENCY - 1)   next_state = DONE;
            DONE:    if (!start)                     next_state = IDLE;
            default:                                 next_state = IDLE;
        endcase
    end


    always @(posedge clk) begin
        if (rst)
            cycle_cnt <= 0;
        else if (state == COMPUTE)
            cycle_cnt <= cycle_cnt + 1;
        else
            cycle_cnt <= 0;
    end


    always @(*) begin
        load      = (state == LOAD_ST);
        busy      = (state == COMPUTE);
        valid_out = (state == DONE);
    end

endmodule
