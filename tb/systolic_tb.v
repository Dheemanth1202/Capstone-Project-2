// =============================================================================
// Testbench   : systolic_tb
// Description : Waveform-styled self-checking testbench
//               Signal names match the sample waveform image:
//                 clk, rst_n (active-low), start, A[7:0], B[7:0], P[15:0], valid
//               Test vectors chosen to produce distinctive 4-digit hex products:
//                 00×00 = 0000
//                 A5×09 = 05CD
//                 58×E7 = 4F68
//                 D9×97 = 7FFF
//                 FF×FF = FE01
// =============================================================================

`timescale 1ns / 1ps

module systolic_tb;

    // -------------------------------------------------------------------------
    // Parameters
    // -------------------------------------------------------------------------
    parameter N          = 8;
    parameter CLK_PERIOD = 10;
    parameter LATENCY    = (2 * N) - 1;

    // -------------------------------------------------------------------------
    // Primary signals (named to match waveform viewer labels)
    // -------------------------------------------------------------------------
    reg              clk;
    reg              rst_n;     // Active-low reset (shown in waveform)
    reg              start;
    reg  [N-1:0]     A;         // Multiplicand  — uppercase to match image
    reg  [N-1:0]     B;         // Multiplier    — uppercase to match image
    wire [2*N-1:0]   P;         // Product       — uppercase to match image
    wire             valid;
    wire             busy;

    // -------------------------------------------------------------------------
    // DUT — internal RTL uses active-high rst, driven by ~rst_n
    // -------------------------------------------------------------------------
    systolic_top #(.N(N)) DUT (
        .clk     (clk),
        .rst     (~rst_n),       // Invert rst_n for active-high internal reset
        .start   (start),
        .a       (A),
        .b       (B),
        .product (P),
        .valid   (valid),
        .busy    (busy)
    );

    // -------------------------------------------------------------------------
    // Clock generation — 100 MHz (10 ns period)
    // -------------------------------------------------------------------------
    initial clk = 0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    // -------------------------------------------------------------------------
    // Test tracking
    // -------------------------------------------------------------------------
    integer pass_cnt, fail_cnt, test_num;
    reg [2*N-1:0] captured_P;

    // -------------------------------------------------------------------------
    // Task: run_multiply
    //   Drives start for one cycle, waits for valid, captures P
    // -------------------------------------------------------------------------
    task run_multiply;
        input [N-1:0]   op_a;
        input [N-1:0]   op_b;
        input [2*N-1:0] golden;
        input [127:0]   label;
        integer timeout_cnt;
        begin
            test_num   = test_num + 1;
            captured_P = {2*N{1'bx}};

            A     = op_a;
            B     = op_b;
            start = 1'b1;
            @(posedge clk); #1;
            start = 1'b0;

            timeout_cnt = 0;
            while (!valid && timeout_cnt < LATENCY + 10) begin
                @(posedge clk); #1;
                timeout_cnt = timeout_cnt + 1;
            end

            // Capture P immediately while valid is high
            captured_P = P;
            @(posedge clk); #1;     // Let FSM return to IDLE

            if (^captured_P === 1'bx) begin
                $display("[TIMEOUT] Test %0d (%s): valid never asserted!", test_num, label);
                fail_cnt = fail_cnt + 1;
            end else if (captured_P !== golden) begin
                $display("[FAIL]  Test %0d (%s): 0x%02h x 0x%02h = 0x%04h  (expected 0x%04h)",
                          test_num, label, op_a, op_b, captured_P, golden);
                fail_cnt = fail_cnt + 1;
            end else begin
                $display("[PASS]  Test %0d (%s): 0x%02h x 0x%02h = 0x%04h",
                          test_num, label, op_a, op_b, captured_P);
                pass_cnt = pass_cnt + 1;
            end
        end
    endtask

    // -------------------------------------------------------------------------
    // Random seed
    // -------------------------------------------------------------------------
    integer seed;

    // -------------------------------------------------------------------------
    // Main stimulus
    // -------------------------------------------------------------------------
    initial begin
        // Initialise
        test_num = 0; pass_cnt = 0; fail_cnt = 0; seed = 99;
        clk = 0; rst_n = 0; start = 0; A = 0; B = 0;

        // VCD dump for GTKWave
        $dumpfile("sim/waveform.vcd");
        $dumpvars(0, systolic_tb);

        // Assert reset (rst_n=0) for 5 cycles
        repeat (5) @(posedge clk);
        #1;
        rst_n = 1;                  // Deassert reset — waveform goes high here
        @(posedge clk); #1;

        $display("================================================");
        $display("  Systolic Array Multiplier  (N = %0d bits)", N);
        $display("================================================");

        // ------------------------------------------------------------------
        // Waveform-matching test vectors — chosen for distinctive hex outputs
        // 1) 0x00 × 0x00 = 0x0000
        // 2) 0xA5 × 0x09 = 0x05CD   (165 × 9  = 1485)
        // 3) 0x58 × 0xE7 = 0x4F68   (88  × 231 = 20328)
        // 4) 0xD9 × 0x97 = 0x7FFF   (217 × 151 = 32767)
        // 5) 0xFF × 0xFF = 0xFE01   (255 × 255 = 65025)
        // ------------------------------------------------------------------
        run_multiply(8'h00, 8'h00, 16'h0000, "00 x 00     ");
        run_multiply(8'hA5, 8'h09, 16'h05CD, "A5 x 09     ");
        run_multiply(8'h58, 8'hE7, 16'h4F68, "58 x E7     ");
        run_multiply(8'hD9, 8'h97, 16'h7FFF, "D9 x 97     ");
        run_multiply(8'hFF, 8'hFF, 16'hFE01, "FF x FF     ");

        // ------------------------------------------------------------------
        // Additional random tests
        // ------------------------------------------------------------------
        begin : rand_tests
            integer k;
            reg [N-1:0]   ra, rb;
            reg [2*N-1:0] golden;
            for (k = 0; k < 10; k = k + 1) begin
                ra     = $random(seed) % 256;
                rb     = $random(seed) % 256;
                golden = ra * rb;
                run_multiply(ra, rb, golden, "RANDOM      ");
            end
        end

        // Summary
        $display("================================================");
        $display("  RESULTS: %0d Passed / %0d Failed / %0d Total",
                  pass_cnt, fail_cnt, test_num);
        if (fail_cnt == 0)
            $display("  ** ALL TESTS PASSED **");
        else
            $display("  ** SOME TESTS FAILED **");
        $display("================================================");

        #(CLK_PERIOD * 5);
        $finish;
    end

    // Watchdog
    initial begin
        #(CLK_PERIOD * (LATENCY + 50) * 20);
        $display("[WATCHDOG] Simulation timed out!");
        $finish;
    end

endmodule
