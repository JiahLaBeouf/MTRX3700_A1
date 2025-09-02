module whack_a_mole_fsm #(
    parameter MAX_MS = 2047
)(
    input clk,
    input button_pressed,
    input [10:0] timer_value,
    input [10:0] random_value,
    input [8:0] switches,           // 9 switches for mole whacking
    input [2:0] difficulty_switches, // 3 switches for difficulty selection
    output logic reset,
    output logic up,
    output logic enable,
    output logic [8:0] mole_positions,
    output logic [15:0] score
);

    // Edge detection for button 
    logic button_q0, button_edge;
    always_ff @(posedge clk) begin : edge_detect
        button_q0 <= button_pressed;
    end : edge_detect
    assign button_edge = (button_pressed > button_q0);

    // Edge detection for switches
    logic [8:0] switches_q0, switch_edges;
    always_ff @(posedge clk) begin : switch_edge_detect
        switches_q0 <= switches;
    end : switch_edge_detect
    assign switch_edges = switches & ~switches_q0;

    // State typedef enum 
    typedef enum logic [1:0] {S0, S1, S2, S3} state_type;
    state_type current_state, next_state;

    // Internal game registers
    reg [8:0] active_moles;
    reg [15:0] game_score;
    reg [3:0] hit_count;
    reg [10:0] mole_timeout;

    // Set mole timeout based on difficulty
    always_comb begin
        case(difficulty_switches)
            3'b001: mole_timeout = 11'd800;   // Easy
            3'b010: mole_timeout = 11'd600;   // Medium
            3'b100: mole_timeout = 11'd400;   // Hard
            default: mole_timeout = 11'd700;  // Default
        endcase
    end

    // Next state logic 
    always_comb begin
        case(current_state)
            S0: next_state = (button_edge == 1) ? S1 : S0;              // IDLE -> START
            S1: next_state = (timer_value >= mole_timeout) ? S2 : S1;   // SPAWN_WAIT -> MOLE_ACTIVE
            S2: next_state = (|switch_edges) ? S3 : 
                           (timer_value >= 11'd1500) ? S1 : S2;        // MOLE_ACTIVE -> HIT or TIMEOUT
            S3: next_state = (button_edge == 1) ? S0 : S1;              // SCORE_UPDATE -> CONTINUE or END
            default: next_state = current_state;
        endcase
    end

    // State flip-flops 
    always_ff @(posedge clk) begin
        current_state <= next_state;
    end

    // Game logic in state machine
    always_ff @(posedge clk) begin
        case(current_state)
            S0: begin // IDLE
                active_moles <= 9'b0;
                game_score <= 16'b0;
                hit_count <= 4'b0;
            end
            
            S1: begin // SPAWN_WAIT / NEW_MOLES
                // Generate new moles when timer resets
                if (timer_value == 0) begin
                    case(difficulty_switches)
                        3'b001: active_moles <= (1 << (random_value[2:0]));  // Easy: 1 mole
                        3'b010: active_moles <= (1 << (random_value[2:0])) | 
                                              (1 << (random_value[5:3]));    // Medium: 2 moles
                        3'b100: active_moles <= (1 << (random_value[2:0])) | 
                                              (1 << (random_value[5:3])) | 
                                              (1 << (random_value[8:6]));    // Hard: 3 moles
                        default: active_moles <= (1 << (random_value[2:0]));
                    endcase
                end
            end
            
            S2: begin // MOLE_ACTIVE
                // Remove hit moles
                active_moles <= active_moles & ~switch_edges;
            end
            
            S3: begin // SCORE_UPDATE
                // Calculate score
                if (|(switch_edges & active_moles)) begin
                    hit_count <= hit_count + 1;
                    case(difficulty_switches)
                        3'b001: game_score <= game_score + 16'd10;  // Easy
                        3'b010: game_score <= game_score + 16'd20;  // Medium
                        3'b100: game_score <= game_score + 16'd30;  // Hard
                        default: game_score <= game_score + 16'd15;
                    endcase
                    
                    // Bonus for consecutive hits
                    if (hit_count >= 3) begin
                        game_score <= game_score + 16'd50;
                    end
                end else begin
                    hit_count <= 4'b0;  // Reset consecutive hits
                end
            end
        endcase
    end

    // Output assignments 
    assign reset = (current_state == S0) ? 1'b1 : 
                   (current_state == S1) ? (timer_value == 0) : 1'b0;

    assign up = (current_state == S1 || current_state == S2) ? 1'b1 : 1'b0;
    assign enable = (current_state == S1 || current_state == S2) ? 1'b1 : 1'b0;
    assign mole_positions = active_moles;
    assign score = game_score;

endmodule
