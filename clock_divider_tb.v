// synthesis translate_off
//Compiler directive that specifies the time unit and precision
`timescale 1ns/1ps

module clock_divider_tb;
    // Step 1: Signal Declarations
    reg clk;
    reg rst_n;

    wire clk_1hz;
    wire clk_067hz;
    wire clk_05hz;

    localparam integer SIM_MAX_1HZ   = 50000000 - 1;
    localparam integer SIM_MAX_067HZ = 75000000 - 1;
    localparam integer SIM_MAX_05HZ  = 100000000 - 1;

    // Step 2: Device Under Test (DUT) instantiation
    clock_divider #(
        .MAX_1HZ (SIM_MAX_1HZ),
        .MAX_067HZ (SIM_MAX_067HZ),
        .MAX_05HZ (SIM_MAX_05HZ)
    )DUT(
        .clk(clk), .rst_n(rst_n), .clk_1hz(clk_1hz), .clk_067hz(clk_067hz), .clk_05hz(clk_05hz)
    );

     
    // Step 3: Test Stimulus Generation
    initial clk = 1'b0;
    always #10 clk = ~clk;

    // Step 4: Test sequence (stimulus + self-check)
    // Count system clock cycles as a "unified yardstick"
    integer cycle_cnt;
integer c1_prev, c1_curr, c067_prev, c067_curr, c5_pos1, c5_neg1, c5_pos2;
    always @(posedge clk or negedge rst_n) begin
    if (!rst_n) cycle_cnt <= 0;
    else        cycle_cnt <= cycle_cnt + 1;
    end

    // --------------- Test sequence (stimulus + self-check) ---------------
    initial begin : test_process
        $dumpfile("waveform.vcd");
        $dumpvars();
        // 1) Power-on reset: active-low; hold for several cycles, then release near a clock edge
        rst_n = 1'b0;                 // Low -> enter reset
        repeat (5) @(posedge clk);    // Hold for 5 cycles to ensure reset fully takes effect
        rst_n = 1'b1;                 // High -> exit reset
        @(posedge clk);               // Wait 1 more cycle for outputs to settle

        // 2) ---------- Verify 1 Hz pulse: interval between two rising edges = SIM_MAX_1HZ + 1 ----------
// moved integer c1_prev,c1_curr
        @(posedge clk_1hz);               // Wait for the first 1 Hz pulse
        c1_prev = cycle_cnt;

        @(posedge clk_1hz);               // Second 1 Hz pulse
        c1_curr = cycle_cnt;
        if (c1_curr - c1_prev !== (SIM_MAX_1HZ + 1))
            $error("clk_1hz period mismatch: got %0d cycles, exp %0d",
                c1_curr - c1_prev, SIM_MAX_1HZ + 1);
        else
            $display("[PASS] clk_1hz period = %0d cycles", c1_curr - c1_prev);

        // 3) ---------- Verify 0.67 Hz pulse: interval between two rising edges = SIM_MAX_067HZ + 1 ----------
// moved integer c067_prev,c067_curr
        @(posedge clk_067hz);
        c067_prev = cycle_cnt;
        
        @(posedge clk_067hz);
        c067_curr = cycle_cnt;
        if (c067_curr - c067_prev !== (SIM_MAX_067HZ + 1))
            $error("clk_067hz period mismatch: got %0d cycles, exp %0d",
                c067_curr - c067_prev, SIM_MAX_067HZ + 1);
        else
            $display("[PASS] clk_067hz period = %0d cycles", c067_curr - c067_prev);

        // 4) ---------- Verify 0.5 Hz square wave: half period / full period ----------
// moved integer c5_pos1,c5_neg1,c5_pos2
        @(posedge clk_05hz);             // First rising edge
        c5_pos1 = cycle_cnt;
        

        @(posedge clk_05hz);             // Next rising edge (full period)
        c5_pos2 = cycle_cnt;
        if (c5_pos2 - c5_pos1 !== 2*(SIM_MAX_05HZ + 1))
            $error("clk_05hz FULL period mismatch: got %0d cycles, exp %0d",
                c5_pos2 - c5_pos1, 2*(SIM_MAX_05HZ + 1));
        else
            $display("[PASS] clk_05hz FULL period = %0d cycles", c5_pos2 - c5_pos1);

        // 5) Finish
        $display("[DONE] All checks completed at t=%0t", $time);
        $finish;
    end



endmodule
// synthesis translate_on