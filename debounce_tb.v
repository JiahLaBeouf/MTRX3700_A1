module debounce_tb;
    // Step 1: Signal Declarations
    reg clk;
    reg rst_n;
    reg[17:0] switches;
    
    wire[17:0]  switches_stable;
    wire [17:0] switch_changed;

    localparam integer DEBOUNCE_MS = 10;
    localparam integer CLK_HZ         = 50000000;
    localparam integer NS_PER_MS      = CLK_HZ/1000;         // 1 ms = 1_000_000 ns
    localparam integer DB_NS          = DEBOUNCE_MS * NS_PER_MS;

    // Step 2: Device Under Test (DUT) instantiation
    debounce #(
        .CLK_HZ(CLK_HZ),
        .DEBOUNCE_MS(DEBOUNCE_MS)
    ) DUT (
        .clk(clk),
        .rst_n(rst_n),
        .switches(switches),
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

        // Header & live monitor (teacher style: one line watches key signals)
        $display(" time    rst  sw[0] sw[5]  STB[0] STB[5]  CHG[0] CHG[5]");
        $monitor("%6t   %b     %b     %b      %b      %b      %b      %b",
                $time, rst_n, switches[0], switches[5],
                switches_stable[0], switches_stable[5],
                switch_changed[0],  switch_changed[5]);

        // Reset & init
        rst_n    = 0;
        switches = 18'd0;#100 rst_n = 1;

        // -------- Press: channel 0 "bounce first, then settle to 1" --------
        // Quick bouncing (much shorter than debounce interval)
        #100  switches[0] = 1;
        #50   switches[0] = 0;
        #50   switches[0] = 1;   // begins to stay at 1
        // Wait less than the debounce threshold: should NOT latch
        #(DB_NS/2);
        // Then wait beyond the threshold: should latch to 1, with a 1-cycle pulse on switch_changed[0]
        #(DB_NS + 2000);

        // -------- Release: channel 0 "bounce first, then settle to 0" --------
        // Add a bit of bounce
        #100  switches[0] = 0;
        #50   switches[0] = 1;
        #50   switches[0] = 0;   // begins to stay at 0
        #(DB_NS + 2000);

        // -------- Also test another channel (ch 5) press -> release --------
        // Press with bounce
        #100  switches[5] = 1;
        #40   switches[5] = 0;
        #40   switches[5] = 1;   // settles at 1
        #(DB_NS + 2000);
        // Release with bounce
        #80   switches[5] = 0;
        #40   switches[5] = 1;
        #40   switches[5] = 0;   // settles at 0
        #(DB_NS + 2000);

        // Finish
        #200 $finish;

    end

endmodule