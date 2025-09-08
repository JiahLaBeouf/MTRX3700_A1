// switch_handler.v 
module switch_handler #(
    parameter integer N_SW        = 18,
    parameter integer CLK_HZ      = 50_000_000,
    parameter integer DEBOUNCE_MS = 10
)(
    input                   clk,
    input                   rst_n,
    input  [N_SW-1:0]       switches,     
    input  [N_SW-1:0]       curr_target,  
    input                   game_over,
    output reg  [13:0]      score,        // point counting
    output reg              target_hit,   
    output      [N_SW-1:0]  switches_stable,
    output      [N_SW-1:0]  switch_changed 
);
    debounce #(
        .CLK_HZ(CLK_HZ),
        .DEBOUNCE_MS(DEBOUNCE_MS)
    ) u_deb (
        .clk             (clk),
        .rst_n           (rst_n),
        .switches        (switches),
        .switches_stable (switches_stable),
        .switch_changed  (switch_changed)
    );

    wire [N_SW-1:0] newly_on = switches_stable & switch_changed;

    // hit check  +  mark
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            score      <= 14'd0;
            target_hit <= 1'b0;
        end else if (game_over) begin
            target_hit <= 1'b0;
        end else begin
            target_hit <= 1'b0; 
            if (|newly_on) begin
                if (|(newly_on & curr_target)) begin
                    score      <= score + 1'b1; // hit successful
                    target_hit <= 1'b1;
                end else if (score > 0) begin
                    score      <= score - 1'b1; //miss, minus mark
                end
            end
        end
    end

endmodule