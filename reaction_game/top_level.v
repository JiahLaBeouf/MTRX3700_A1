module top_level (
    input         CLOCK_50,              // DE2-115's 50MHz clock signal
    input  [3:0]  KEY,                   // The 4 push buttons on the board
    output [17:0] LEDR,                  // 18 red LEDs
    output [6:0]  HEX0, HEX1, HEX2, HEX3 // Four 7-segment displays
);

    // Intermediate wires: (DO NOT EDIT WIRE NAMES!)
    wire        timer_reset, timer_up, timer_enable, button_pressed;
    wire [10:0] timer_value, random_value;

    // First module instantiated for you as an example:
    timer           u_timer         (// Inputs:
                                    .clk(CLOCK_50),
                                    .reset(timer_reset),
                                    .up(timer_up),
                                    .enable(timer_enable),
                                    .start_value(random_value),
                                    // Outputs:
                                    .timer_value(timer_value));

    // Add remaining module instantiations here!
    rng u_rng (
        .clk(CLOCK_50),
        //Outputs
        .random_value(random_value)
    );

    //Debounce
    debounce #(.DELAY_COUNTS(1)) u_debounce (
        //Inputs
        .clk(CLOCK_50),
        .button(~KEY[0]),
        //outputs
        .button_pressed(button_pressed)
    );

    //reaction time fsm
    reaction_time_fsm u_reaction_time_fsm (

        //Inputs
        .clk(CLOCK_50),
        .button_pressed(button_pressed),
        .timer_value(timer_value),
        //outputs
        .reset(timer_reset),
        .up(timer_up),
        .enable(timer_enable),
        .led_on(LEDR[0])
    );

    //displays
    display u_display (
        //Inputs
        .clk(CLOCK_50),
        .value(timer_value),
        //outputs
        .display0(HEX0),
        .display1(HEX1),
        .display2(HEX2),
        .display3(HEX3)
    );

endmodule
