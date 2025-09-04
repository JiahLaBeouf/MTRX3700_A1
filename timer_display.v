module timer_display #(
    parameter integer CLKS_PER_MS = 50000  // 50 MHz default
)(
    input  wire        clk,
    input  wire        rst_n,       // active-low reset
    input  wire        start_evt,   // 1-cycle pulse when mole appears
    input  wire        stop_evt,    // 1-cycle pulse when player hits
    output wire [6:0]  display0,    // ones  -> HEX5
    output wire [6:0]  display1     // tens  -> HEX6
);

    // counting state
    reg        running;            
    reg [31:0] clk_cnt;             // counts 0..CLKS_PER_MS-1
    reg [7:0]  time_ms;             // live time in ms (saturates at 255)
    reg [7:0]  latched_ms;          // value captured at stop

    //stopwatch
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            running    <= 1'b0;
            clk_cnt    <= 32'd0;
            time_ms    <= 8'd0;
            latched_ms <= 8'd0;
        end else begin
            // start: clear and run
            if (start_evt) begin
                running    <= 1'b1;
                clk_cnt    <= 32'd0;
                time_ms    <= 8'd0;
                latched_ms <= 8'd0;
            end
            // stop: latch result and stop
            if (stop_evt && running) begin
                running    <= 1'b0;
                latched_ms <= time_ms;
            end

            // ms ticking when running
            if (running) begin
                if (clk_cnt == CLKS_PER_MS-1) begin
                    clk_cnt <= 32'd0;
                    if (time_ms != 8'hFF)        // saturate just in case
                        time_ms <= time_ms + 8'd1;
                end else begin
                    clk_cnt <= clk_cnt + 32'd1;
                end
            end else begin
                clk_cnt <= 32'd0; // keep stable when not running
            end
        end
    end

    // choose what to show: live while running, else the latched result
    wire [7:0] show = running ? time_ms : latched_ms;

    // clamp to 0..99 before splitting into digits
    wire [7:0] t  = (show > 8'd99) ? 8'd99 : show;

    // compute tens
    wire [7:0] tens8 = (t * 8'd205) >> 11;
    wire [3:0] te    = tens8[3:0];           // tens nibble
    wire [3:0] on    = t - (te * 4'd10);     // ones nibble

    // 7-seg decode (active-low on DE2-115)
    wire [6:0] seg_te, seg_on;
    seg7_decoder u_tens (.bin(te), .seg(seg_te));
    seg7_decoder u_ones (.bin(on), .seg(seg_on));

    assign display1 = seg_te;  // HEX6 tens
    assign display0 = seg_on;  // HEX5 ones

endmodule
