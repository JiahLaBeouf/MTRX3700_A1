module led_control (
  input  logic        clk,
  input  logic        rst_n,

  input  logic        spawn_tick,       
  input  logic [4:0]  random_pos,       
  input  logic [17:0] sw,               //  switches

  output logic [17:0] led_mask          //  LEDR  his
);

  logic [17:0] curr_target;

  logic [17:0] sw_d1, sw_d2, sw_prev;
  wire  [17:0] sw_edge = sw_d2 & ~sw_prev;     

  wire  [17:0] hit_vec = sw_edge & curr_target;
  wire         hit_any = |hit_vec;

  wire [17:0] spawn_onehot = (random_pos < 18) ? (18'b1 << random_pos) : 18'b0;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      curr_target <= 18'd0;
      sw_d1 <= 18'd0; sw_d2 <= 18'd0; sw_prev <= 18'd0;
    end else begin
      // sync switches
      sw_d1   <= sw;
      sw_d2   <= sw_d1;
      sw_prev <= sw_d2;

      if (spawn_tick && (curr_target == 18'd0))
        curr_target <= spawn_onehot;

      if (hit_any)
        curr_target <= 18'd0;
    end
  end

  assign led_mask = curr_target;  // connect to LEDR at the top level
endmodule
