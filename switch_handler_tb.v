module switch_handler_tb;
    // Step 1: Signal Declarations
    localparam integer N_SW          = 18;
    localparam integer CLK_HZ        = 50000000;
    localparam integer TB_DB_MS      = 10;                // 2ms for quick sim; set to 10 for real
    localparam integer NS_PER_MS     = 1000000;        // 1ms = 1e6 ns
    localparam integer DB_NS         = TB_DB_MS * NS_PER_MS;

    reg clk;
    reg rst_n;
    reg[N_SW-1:0] switches;
    reg[N_SW-1:0] curr_target;
    reg game_over;
    wire[13:0] score;
    wire[N_SW-1:0] switches_stable;
    wire[N_SW-1:0] switch_changed;

    // Step 2: Device Under Test (DUT) instantiation
    switch_handler #(
        .N_SW(N_SW),
        .CLK_HZ(CLK_HZ),
        .DEBOUNCE_MS(TB_DB_MS)
    ) DUT (
        .clk(clk),
        .rst_n(rst_n),
        .switches(switches),
        .curr_target(curr_target),
        .game_over(game_over),
        .score(score),
        .target_hit(target_hit),
        .switches_stable(switches_stable),
        .switch_changed(switch_changed)
    );

    // Step 3: Test Stimulus Generation
    initial begin : clock_block
            clk = 1'b0;
            forever begin
                #10;
                clk = ~clk;
            end
    end

    // Step 4: Test sequence (stimulus + self-check)
    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars();

        // One-line live monitor of key signals
        $display(" time   rst go  tgtIdx  sw[3] sw[5]  STB[3] STB[5]  CHG[3] CHG[5]   score  hit");
        $monitor("%5t   %b   %b    --     %b     %b      %b      %b       %b      %b     %0d     %b",
                $time, rst_n, game_over,
                switches[3], switches[5],
                switches_stable[3], switches_stable[5],
                switch_changed[3],  switch_changed[5],
                score, target_hit);

        // ---- Reset & init ----
        rst_n      = 0;
        game_over  = 0;
        switches   = '0;
        curr_target= '0;
        #100 rst_n = 1;

        // ===================== Scenario 1: HIT (add 1) =====================
        // target = idx 3
        curr_target = (({N_SW{1'b0}} | 1'b1) << 3);
        // press switch 3 with a little bounce, then settle high
        #100 switches[3] = 1;
        #40  switches[3] = 0;
        #40  switches[3] = 1;  // begin stable=1
        #(DB_NS + 2000);       // wait beyond debounce; expect score+1 and a target_hit pulse

        // ===================== Scenario 2: MISS (subtract 1) =================
        // target = idx 7, but press idx 5 -> miss
        curr_target = (({N_SW{1'b0}} | 1'b1) << 7);
        #120 switches[5] = 1;
        #40  switches[5] = 0;
        #40  switches[5] = 1;  // stable high on wrong switch
        #(DB_NS + 2000);       // expect score-1 (but not below 0), no target_hit

        // ===================== Scenario 3: HIT again (back +1) ==============
        // press the correct target 7
        #120 switches[7] = 1;
        #40  switches[7] = 0;
        #40  switches[7] = 1;
        #(DB_NS + 2000);       // expect score+1 and a hit pulse

        // ===================== Scenario 4: game_over blocks scoring =========
        game_over = 1;
        // even if we press the correct target, no scoring and no hit pulse
        #120 switches[7] = 0;  // release first
        #60  switches[7] = 1;  // press again under game_over
        #(DB_NS + 2000);
        game_over = 0;

        // Finish
        #200 $finish;
    end


endmodule