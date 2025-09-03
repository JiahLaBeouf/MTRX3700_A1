
module rng_two_leds #(
    parameter [10:1] SEED_A = 10'b00_0001_0011, // different non-zero seeds
    parameter [10:1] SEED_B = 10'b00_0010_1011
)(
    input  wire        clk,
    input  wire        step,           
    output reg  [4:0]  idx_a,          
    output reg  [4:0]  idx_b,          
    output wire [17:0] led_mask        
);
    wire [4:0] a_cand, b_cand;

    // Two independent RNGs
    rng_led18 #(.SEED(SEED_A)) u_a (
        .clk(clk), .step(step), .idx(a_cand)
    );

    rng_led18 #(.SEED(SEED_B)) u_b (
        .clk(clk), .step(step), .idx(b_cand)
    );

    
    // If there is a collision, change B by +1 (wrap at 18).
    always @(posedge clk) begin
        if (step) begin
            idx_a <= a_cand;
            idx_b <= (b_cand == a_cand) ? ((b_cand + 5'd1) % 5'd18) : b_cand;
        end
    end

    // One-hot masks
    wire [17:0] onehot_a = (18'b1 << idx_a);
    wire [17:0] onehot_b = (18'b1 << idx_b);

    assign led_mask = onehot_a | onehot_b; 
endmodule
