module debounce
(
    clk,
    rst_n,
    switches,
    switches_stable,
    switch_changed
);
    // Ports
    input        clk;
    input        rst_n;            // active-low reset
    input  [17:0] switches;        // raw asynchronous switches
    output [17:0] switches_stable; // debounced stable values
    output [17:0] switch_changed;  // 1-cycle pulse on change per bit

    // Parameters (override with defparam if needed)
    parameter CLK_HZ      = 50000000; // system clock frequency (Hz)
    parameter DEBOUNCE_MS = 10;       // debounce time in milliseconds
    // Derived constant
    localparam DEBOUNCE_TICKS = (CLK_HZ/1000)*DEBOUNCE_MS; // e.g., 500_000 for 10ms @ 50MHz

    // Internal regs
    reg [17:0] switches_sync1;
    reg [17:0] switches_sync2;
    reg [17:0] switches_stable_reg;
    reg [17:0] switch_changed_reg;

    // Expose registered outputs
    assign switches_stable = switches_stable_reg;
    assign switch_changed  = switch_changed_reg;

    // Per-switch counters: 20 bits enough for up to ~1,048,575
    reg [19:0] debounce_cnt [0:17];

    integer i;

    // Two-stage synchronizers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            switches_sync1 <= 18'd0;
            switches_sync2 <= 18'd0;
        end else begin
            switches_sync1 <= switches;
            switches_sync2 <= switches_sync1;
        end
    end

    // Debounce logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            switches_stable_reg <= 18'd0;
            switch_changed_reg  <= 18'd0;
            for (i = 0; i < 18; i = i + 1) begin
                debounce_cnt[i] <= 20'd0;
            end
        end else begin
            // default: no change pulse (1-cycle)
            switch_changed_reg <= 18'd0;

            for (i = 0; i < 18; i = i + 1) begin
                if (switches_sync2[i] != switches_stable_reg[i]) begin
                    // candidate state persists? count until threshold
                    if (debounce_cnt[i] < DEBOUNCE_TICKS[19:0]) begin
                        debounce_cnt[i] <= debounce_cnt[i] + 1'b1;
                    end else begin
                        // reached threshold: accept new stable state and flag change
                        switches_stable_reg[i] <= switches_sync2[i];
                        debounce_cnt[i]        <= 20'd0;
                        switch_changed_reg[i]  <= 1'b1;
                    end
                end else begin
                    // consistent: reset counter
                    debounce_cnt[i] <= 20'd0;
                end
            end
        end
    end

endmodule
