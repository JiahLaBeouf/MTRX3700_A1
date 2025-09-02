module top_level (
    input CLOCK_50,           // DE2-115's 50MHz clock signal
    input [3:0] KEY,          // The 4 push buttons on the board
    input [17:0] SW,          // 18 toggle switches 
    output [17:0] LEDR,       // 18 red LEDs (represent moles)
    output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6  // Four 7-segment displays for score, 2 for time, 1 for difficulty
);

    // Intermediate wires 
    wire game_reset, timer_reset, timer_up, timer_enable;
    wire button_pressed;
    wire [10:0] timer_value, random_value;
    wire [8:0] mole_positions;  // 9 moles (using SW[8:0])
    wire [15:0] score;

    // Timer setup
    timer #(.MAX_MS(2047), .CLKS_PER_MS(50000)) u_timer (
        .clk(CLOCK_50),
        .reset(timer_reset),
        .up(timer_up),
        .enable(timer_enable),
        .start_value(11'b0),
        .timer_value(timer_value)
    );

    // RNG setup
    rng #(.OFFSET(0), .MAX_VALUE(1023), .SEED(156)) u_rng (
        .clk(CLOCK_50),
        .random_value(random_value)
    );

    // Debounce
    debounce #(.DELAY_COUNTS(2500000)) u_debounce (  // 50ms debounce for DE2-115
        .clk(CLOCK_50),
        .button(~KEY[0]),          // KEY[0] = start/reset button (active low)
        .button_pressed(button_pressed)
    );

    // Game FSM
    whac_a_mole_fsm u_game_fsm (
        .clk(CLOCK_50),
        .button_pressed(button_pressed),
        .timer_value(timer_value),
        .random_value(random_value),
        .switches(SW[8:0]),        // Use first 9 switches for moles
        .difficulty_switches(~KEY[3:1]), 
        .reset(timer_reset),
        .up(timer_up),
        .enable(timer_enable),
        .mole_positions(mole_positions),
        .score(score)
    );

    // Assign LEDs - show moles on first 9 LEDs, others off
    assign LEDR[8:0] = mole_positions;
    assign LEDR[17:9] = 9'b0;

    // display module
    score_display u_display (
        .clk(CLOCK_50),
        .score(score),
        .display0(HEX0),
        .display1(HEX1),
        .display2(HEX2),
        .display3(HEX3)
    );

    // Time display
    time_display u_time_display (
        .clk(CLOCK_50),
        .time_value(timer_value[7:0]),   // pick bits that fit in 2 digits
        .display0(HEX5),
        .display1(HEX6)
    );

    // Difficulty display
    diff_display u_diff_display(
        .diff(~KEY[3:1]),
        .hex(HEX4)
    );


endmodule