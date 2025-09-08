module game_controller(
    input        clk,            // System clock
    input        rst_n,          // Active-low reset
    input        clk_1hz,        // 1 Hz clock
    input        clk_067hz,      // 0.67 Hz clock (1.5 s period)
    input        clk_05hz,       // 0.5 Hz clock (2 s period)
    input        speed1,         // Speed button 1 (2 s/step), active-low
    input        speed2,         // Speed button 2 (1.5 s/step), active-low
    input        speed3,         // Speed button 3 (1 s/step), active-low
    input  [17:0] switches,      // 18 DIP switches
    input  [4:0]  random_pos,    // Random position (0–17)
    output reg [5:0]  timer,     // 60-second countdown
    output reg [13:0] score,     // Game score (max 9999)
    output reg [1:0]  speed_level, // Speed level (0,1,2)
    output reg        game_over, // Game-over flag
    output reg [17:0] target_led // Target LED one-hot
);

    // Game state
    reg  [17:0] prev_switches;   // Previously sampled switch state
    reg  [17:0] curr_target;     // Current target one-hot
    reg         target_hit;      // Target-hit flag
    wire        game_clk;        // Game tick clock selected by speed

    // Debounced switch signals
    wire [17:0] switches_stable;   // Debounced switch levels
    wire [17:0] switch_changed;    // One-cycle pulses when a bit changes (debounced)

    // Debounce instance (10 ms @ 50 MHz by default)
    debounce #(
        .CLK_HZ(50_000_000),
        .DEBOUNCE_MS(10)
    ) u_sw_deb (
        .clk             (clk),
        .rst_n           (rst_n),
        .switches        (switches),
        .switches_stable (switches_stable),
        .switch_changed  (switch_changed)
    );
    
    // Game clock selection based on speed level
    assign game_clk = (speed_level == 2'b00) ? clk_05hz :   // Speed 1: 0.5 Hz (2 s/step)
                      (speed_level == 2'b01) ? clk_067hz :  // Speed 2: 0.67 Hz (1.5 s/step)
                                               clk_1hz;     // Speed 3: 1 Hz (1 s/step)
    
    // Speed control (active-low buttons)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            speed_level <= 2'b00;            // Default to speed 1 (2 s/step)
        end else begin
            if (!speed1)       speed_level <= 2'b00; // Speed 1
            else if (!speed2)  speed_level <= 2'b01; // Speed 2
            else if (!speed3)  speed_level <= 2'b10; // Speed 3
        end
    end
    
    // Game timer (counts down every 1 Hz tick)
    always @(posedge clk_1hz or negedge rst_n) begin
        if (!rst_n) begin
            timer     <= 6'd60;              // Start at 60 s
            game_over <= 1'b0;               // Game active
        end else begin
            if (timer > 6'd0) begin
                timer <= timer - 1'b1;
            end else begin
                game_over <= 1'b1;           // Game over
                timer     <= 6'd0;
            end
        end
    end
    
    // Save sampled switch state
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_switches <= 18'd0;
        end else begin
            prev_switches <= switches;
        end
    end
    
    // Target LED control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            curr_target <= 18'd0;
            target_led  <= 18'd0;
        end else if (target_hit) begin
            // Clear current target once it is hit
            curr_target <= 18'd0;
            target_led  <= 18'd0;
        end else if (!game_over) begin
            // Update target only while the game is active
            if (game_clk) begin
                // Convert random position to one-hot
                curr_target <= 18'd1 << random_pos;
                target_led  <= 18'd1 << random_pos;
            end else begin
                curr_target <= curr_target;  // Hold
                target_led  <= target_led;   // Hold
            end
        end else begin
            // Turn off all LEDs when the game is over
            curr_target <= 18'd0;
            target_led  <= 18'd0;
        end
    end

    // Hit detection and scoring
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            score      <= 14'd0;             // Initial score
            target_hit <= 1'b0;
        end else if (!game_over) begin
            // Update score only while the game is active

            // Detect newly asserted debounced switches
            if ((switches_stable & switch_changed) != 18'd0) begin
                if ((switches_stable & switch_changed & curr_target) != 18'd0) begin
                    // Correct hit
                    score      <= score + 1'b1;
                    target_hit <= 1'b1;
                end else if (score > 14'd0) begin
                    // Missed hit → decrement if score > 0
                    score      <= score - 1'b1;
                    target_hit <= 1'b0;
                end
            end else begin
                target_hit <= 1'b0;
            end
        end
    end

endmodule
