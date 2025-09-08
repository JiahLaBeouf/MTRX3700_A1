`timescale 1ns/1ps

module tb_led_control;

  // Clock / reset
  logic clk;
  logic rst_n;

  // DUT I/O
  logic        spawn_tick;
  logic [4:0]  random_pos;
  logic [17:0] sw;
  wire  [17:0] led_mask;

  // Clock: 100 MHz (10 ns period)
  localparam real TCLK_NS = 10.0;

  // Device Under Test
  led_control dut (
    .clk(clk),
    .rst_n(rst_n),
    .spawn_tick(spawn_tick),
    .random_pos(random_pos),
    .sw(sw),
    .led_mask(led_mask)
  );

  // Clock gen
  always #(TCLK_NS/2.0) clk = ~clk;

  // Helpers

  task automatic wait_n_clks(int n);
    repeat (n) @(posedge clk);
  endtask

  // Press a switch (hold for N cycles to cross the 3-FF sync)
  task automatic press_switch(int idx, int hold_cycles = 6);
    if (idx < 0 || idx > 17) return;
    sw[idx] = 1'b1;
    wait_n_clks(hold_cycles);
    sw[idx] = 1'b0;
    wait_n_clks(2);
  endtask

  // Spawn one target
  task automatic spawn_at(int pos);
    random_pos  = pos[4:0];
    spawn_tick  = 1'b1;
    @(posedge clk);
    spawn_tick  = 1'b0;
    wait_n_clks(1);
  endtask

  // Pulse reset mid-sim
  task automatic pulse_reset(int cycles_low = 3);
    rst_n = 1'b0;
    wait_n_clks(cycles_low);
    rst_n = 1'b1;
    wait_n_clks(2);
  endtask

  // Expect LED onehot at position pos
  task automatic expect_led_at(int pos, string msg);
    logic [17:0] onehot;
    onehot = (pos >= 0 && pos < 18) ? (18'b1 << pos) : 18'b0;
    if (led_mask !== onehot) begin
      $display("[%0t] ERROR %s: led_mask=%b expected=%b",
                $time, msg, led_mask, onehot);
      $fatal(1);
    end else begin
      $display("[%0t] PASS %s: led_mask=%b", $time, msg, led_mask);
    end
  endtask

  // Expect all LEDs off
  task automatic expect_leds_off(string msg);
    if (led_mask !== 18'd0) begin
      $display("[%0t] ERROR %s: led_mask=%b expected all off",
                $time, msg, led_mask);
      $fatal(1);
    end else begin
      $display("[%0t] PASS %s: all LEDs off", $time, msg);
    end
  endtask


  initial begin
    $dumpfile("waves.vcd");
    $dumpvars(0, tb_led_control);
  end

  initial begin
    // init
    clk        = 0;
    rst_n      = 0;
    spawn_tick = 0;
    random_pos = 0;
    sw         = '0;

    // power-on reset
    wait_n_clks(4);
    rst_n = 1;
    wait_n_clks(4);

    // ---- Test 1: spawn 7, wrong press 3, correct press 7 ----
    spawn_at(7);
    #100;                         // spacing for the waveform
    expect_led_at(7, "T1 after spawn at 7");

    press_switch(3);
    #80;
    expect_led_at(7, "T1 after wrong press (3) should still show 7");

    press_switch(7);
    #80;
    expect_leds_off("T1 after correct press (7)");

    // ---- Test 2: spawn 12, ignore spawn while active, then clear ----
    #120;
    spawn_at(12);
    #80;  expect_led_at(12, "T2 after spawn 12");

    // try to spawn 5 while active -> should be ignored
    spawn_at(5);
    #60;  expect_led_at(12, "T2 spawn at 5 ignored (still 12)");

    press_switch(12);
    #80;  expect_leds_off("T2 cleared 12");

    // ---- Test 3: mid-run reset clears immediately ----
    #120;
    spawn_at(2);
    #80;  expect_led_at(2, "T3 active before reset");
    pulse_reset(5);
    #40;  expect_leds_off("T3 cleared by reset");

    // ---- Test 4: randomized smoke (5 rounds) ----
    for (int i = 0; i < 5; i++) begin
      int pos = $urandom_range(0,17);
      #80;
      spawn_at(pos);
      #60; expect_led_at(pos, $sformatf("T4 spawn at %0d", pos));

      // 50% wrong press first
      if ($urandom_range(0,1)) begin
        int wrong = (pos+1)%18;
        press_switch(wrong);
        #60; expect_led_at(pos, "T4 wrong press keeps LED");
      end
      press_switch(pos);
      #60; expect_leds_off("T4 cleared by correct press");
    end

    $display("All tests passed ✅");
    #100;
    $finish;
  end

endmodule
