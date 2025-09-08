module Game_top(
    input clk,                  // 50 MHz system clock
    input rst_n,                // Reset button, active-low
    input speed1,               // Speed level 1 button (one step per 2 s), active-low
    input speed2,               // Speed level 2 button (one step per 1.5 s), active-low
    input speed3,               // Speed level 3 button (one step per 1 s), active-low
    input [17:0] switches,      // 18 DIP switches
    output [17:0] leds,         // 18 LEDs
    output [6:0] HEX5,          // Countdown tens (7-seg)
    output [6:0] HEX4,          // Countdown ones (7-seg)
    output [6:0] HEX3,          // Score thousands (7-seg)
    output [6:0] HEX2,          // Score hundreds (7-seg)
    output [6:0] HEX1,          // Score tens (7-seg)
    output [6:0] HEX0,          // Score ones (7-seg)
    output [6:0] HEX6           // Speed level (7-seg)
);

    // Internal signals
    wire clk_1hz;               // 1 Hz clock
    wire clk_067hz;             // 0.67 Hz clock (1.5 s period)
    wire clk_05hz;              // 0.5 Hz clock (2 s period)
    wire [4:0] random_pos;      // Random position (0–17)
    wire [17:0] target_led;     // Target LED pattern
    
    wire [5:0]  timer;          // 60-second countdown
    wire [13:0] score;          // Game score (max 9999)
    wire [1:0]  speed_level;    // Speed level (0,1,2)
    wire        game_over;      // Game-over flag
    
    // Clock divider
    clock_divider clock_div_inst(
        .clk(clk),
        .rst_n(rst_n),
        .clk_1hz(clk_1hz),
        .clk_067hz(clk_067hz),
        .clk_05hz(clk_05hz)
    );
    
    // Pseudo-random generator
    random_generator rand_gen_inst(
        .clk(clk),
        .rst_n(rst_n),
        .random_pos(random_pos)
    );
    
    // Game controller
    game_controller game_ctrl_inst(
        .clk(clk),
        .rst_n(rst_n),
        .clk_1hz(clk_1hz),
        .clk_067hz(clk_067hz),
        .clk_05hz(clk_05hz),
        .speed1(speed1),
        .speed2(speed2),
        .speed3(speed3),
        .switches(switches),
        .random_pos(random_pos),
        .timer(timer),
        .score(score),
        .speed_level(speed_level),
        .game_over(game_over),
        .target_led(target_led)
    );
    
    // LED outputs
    assign leds = target_led;
    
    // Seven-seg display — countdown
    seg7_decoder seg_time_tens_inst(
        .bin(timer / 10),
        .seg(HEX5)
    );
    
    seg7_decoder seg_time_ones_inst(
        .bin(timer % 10),
        .seg(HEX4)
    );
    
    // Seven-seg display — score
    seg7_decoder seg_score_thou_inst(
        .bin(score / 1000),
        .seg(HEX3)
    );
    
    seg7_decoder seg_score_hund_inst(
        .bin((score % 1000) / 100),
        .seg(HEX2)
    );
    
    seg7_decoder seg_score_tens_inst(
        .bin((score % 100) / 10),
        .seg(HEX1)
    );
    
    seg7_decoder seg_score_ones_inst(
        .bin(score % 10),
        .seg(HEX0)
    );
    
    // Seven-seg display — speed level (show 1, 2, or 3)
    seg7_decoder seg_speed_inst(
        .bin(speed_level + 1),
        .seg(HEX6)
    );

endmodule
