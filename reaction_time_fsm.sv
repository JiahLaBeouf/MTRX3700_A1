module reaction_time_fsm #(
    parameter MAX_MS=2047    
)(
    input                             clk,
    input                             button_pressed,
    input        [$clog2(MAX_MS)-1:0] timer_value,
    output logic                      reset,
    output logic                      up,
    output logic                      enable,
    output logic                      led_on
);

    // Edge detection block here!
    logic button_q0, button_edge;/* FILL-IN VARIABLES */
    always_ff @(posedge clk) begin : edge_detect
        button_q0 <= button_pressed;
    end : edge_detect
    assign button_edge = (button_pressed > button_q0);
    /* Complete remaining block here */

    // State typedef enum here! (See 3.1 code snippets)
    typedef enum logic [1:0] {S0,S1,S2,S3} state_type;
    state_type current_state, next_state;
    
    // always_comb for next_state_logic here! (See 3.1 code snippets)
    // Set the default next state as the current state
    always_comb begin
        case(current_state)
            S0: next_state = (button_edge == 1) ? S1:S0;
            S1: next_state = (timer_value == 0) ? S2:S1;
            S2: next_state = (button_edge == 1) ? S3:S2;
            S3: next_state = (button_edge == 1) ? S0:S3;
            default: next_state = current_state;
        endcase
    end


    /* Complete code block here */
    
    // always_ff for FSM state variable flip-flops here! (See 3.1 code snippets)
    // Set the current state as the next state (Think about whether a blocking or non-blocking assignment should be used here)
    always_ff @(posedge clk) begin
        current_state <= next_state;
    end

    /* Complete code block here */

    // Continuously assign outputs of reset, up, enable and led_on based on the current state here! (See 3.1 code snippets)

    /* Complete code block here */
    assign reset = (current_state == S0) ? 1:0 || (current_state == S1)?(timer_value==0):0; 

    assign up = (current_state == S1) ? 1:0;
    assign enable = (current_state == S1 || current_state == S2) ? 1:0;
    assign led_on = (current_state == S2) ? 1:0;

endmodule
