module led_controller #(
  parameter int N_LEDS = 18
) (
  input  logic                  clk,
  input  logic                  rst_n,

  // Control from game FSM
  input  logic                  spawn_req,          // request a new mole
  output logic                  new_mole_pulse,     // 1 clk when a mole is lit
  output logic                  expired_pulse,      // 1 clk when a mole times out

  // Config / sources
  input  logic [15:0]           mole_duration_ticks, // how long each mole stays
  input  logic [10:0]           rng_value,           // from your LFSR/RNG

  // Outputs to board / other modules
  output logic [N_LEDS-1:0]     led_mask,           // drive LEDR with this
  output logic [2:0]            active_count,       // active count
  output logic                  busy                // at max concurrent
);

  // Simple single-mole baseline 
  typedef enum logic [1:0] {IDLE, ACTIVE} state_t;
  state_t state, next;

  logic [N_LEDS-1:0] mask_n, mask_q;
  logic [15:0]       ttl_n,  ttl_q;
  logic              new_pulse_n, new_pulse_q;
  logic              exp_pulse_n, exp_pulse_q;

  // Index selection
  logic [$clog2(N_LEDS)-1:0] idx;
  assign idx = rng_value % N_LEDS;

  // Combinational
  always_comb begin
    next          = state;
    mask_n        = mask_q;
    ttl_n         = ttl_q;
    new_pulse_n   = 1'b0;
    exp_pulse_n   = 1'b0;

    unique case (state)
      IDLE: begin
        if (spawn_req) begin
          mask_n       = '0;
          mask_n[idx]  = 1'b1;
          ttl_n        = mole_duration_ticks;
          new_pulse_n  = 1'b1;
          next         = ACTIVE;
        end
      end
      ACTIVE: begin
        if (ttl_q != 16'd0) begin
          ttl_n = ttl_q - 16'd1;
          if (ttl_q == 16'd1) begin
            // about to hit zero
            mask_n      = '0;
            exp_pulse_n = 1'b1;
            next        = IDLE;
          end
        end
      end
      default: next = IDLE;
    endcase
  end

  // Sequential
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state        <= IDLE;
      mask_q       <= '0;
      ttl_q        <= '0;
      new_pulse_q  <= 1'b0;
      exp_pulse_q  <= 1'b0;
    end else begin
      state        <= next;
      mask_q       <= mask_n;
      ttl_q        <= ttl_n;
      new_pulse_q  <= new_pulse_n;
      exp_pulse_q  <= exp_pulse_n;
    end
  end

  // Outputs, connections with the board(components)
  assign led_mask      = mask_q; // (LEDR)
  assign new_mole_pulse= new_pulse_q; // alert on spawn
  assign expired_pulse = exp_pulse_q; // mole expired 
  assign active_count  = (mask_q == '0) ? 3'd0 : 3'd1; // 0 or 1
  assign busy          = (state == ACTIVE); // FOR FSM
endmodule
