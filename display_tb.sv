// display_tb.sv
// Testbench for all display blocks used in Whac-A-Mole:
//  - time_display: shows reaction time (HEX6 tens, HEX5 ones)
//  - score_display: shows score on HEX3..HEX0 with leading-zero blanking
//  - diff_display: shows level 1/2/3 on HEX4
//

//   1) Generates a 50 MHz-ish clock.
//   2) Sweeps difficulty 1→2→3.
//   3) Steps the score through some values (incl. clamp at 9999).
//   4) Performs two reaction-time measurements (~37 ms and ~8 ms).
//
// Produces display.vcd to inspect HEX segments.
//    In ModelSim/Questa: add all sources, set this TB as top, run.
//copy the below command line into model sim terminal to run the simulation using the testbench:
              //cd C:/Users/imran/Desktop/Quartus/seven_seg_display
              
              //vlib work
              //vmap work work
              
              //vlog -sv seven_seg_decoder.v
              //vlog -sv score_display.v
              //vlog -sv diff_display.v
              //vlog -sv timer_display.v
              //vlog -sv display_tb.sv
              
              //vsim work.display_tb
              //add wave -r /*
              //run -all

//       Common-anode patterns: 0=ON, 1=OFF.

`timescale 1ns/1ps

module display_tb;

  // Clocking (50 MHz / 20 ns)

  localparam int CLK_PERIOD_NS = 20;
  reg clk;
  initial clk = 1'b0;
  always #(CLK_PERIOD_NS/2) clk = ~clk;

  // DUT connections

  // timer_display (reaction timer)
  reg  rst_n;
  reg  start_evt;              // pulse when mole appears
  reg  stop_evt;               // pulse when player hits the correct switch
  wire [6:0] HEX5, HEX6;       // ones (HEX5), tens (HEX6)

  // score_display
  reg  [15:0] score;
  wire [6:0]  HEX0, HEX1, HEX2, HEX3;

  // diff_display (one-hot difficulty)
  reg  [2:0]  diff;            // 001=easy, 010=med, 100=hard
  wire [6:0]  HEX4;

  // Instantiate the DUTs

  // Speed up simulation: CLKS_PER_MS=5 means "1ms" every 5 clock cycles.
  timer_display #(.CLKS_PER_MS(5)) u_time (
    .clk       (clk),
    .rst_n     (rst_n),
    .start_evt (start_evt),
    .stop_evt  (stop_evt),
    .display0  (HEX5),   // ones
    .display1  (HEX6)    // tens
  );

  score_display u_score (
    .clk      (clk),
    .score    (score),
    .display0 (HEX0),    // ones
    .display1 (HEX1),    // tens
    .display2 (HEX2),    // hundreds
    .display3 (HEX3)     // thousands
  );

  diff_display u_diff (
    .diff (diff),
    .hex  (HEX4)
  );


  // Helpers

  // Because CLKS_PER_MS=5 in this TB, "wait_ms(x)" = x * 5 cycles.
  task automatic wait_ms(input int ms);
    int i;
    begin
      for (i = 0; i < ms*5; i++) @(posedge clk);
    end
  endtask

  // One-clock pulse helper
  task automatic pulse(input string name, inout reg sig);
    begin
      $display("[%0t] PULSE %s", $time, name);
      sig = 1'b1; @(posedge clk); sig = 1'b0;
    end
  endtask


  // Test sequence
  initial begin
    $dumpfile("display.vcd");
    $dumpvars(0, display_tb);

    // Defaults
    rst_n     = 1'b0;
    start_evt = 1'b0;
    stop_evt  = 1'b0;
    score     = 16'd0;
    diff      = 3'b001;   // start on "1"

    // Release reset
    repeat (5) @(posedge clk);
    rst_n = 1'b1;

    // ---- Difficulty sweep: 1 2 3 ----
    repeat (6) @(posedge clk);
    diff = 3'b001;  // "1"
    repeat (6) @(posedge clk);
    diff = 3'b010;  // "2"
    repeat (6) @(posedge clk);
    diff = 3'b100;  // "3"

    // Score steps (also tests leading-zero blanking + clamp) 
    score = 16'd0;     repeat (8) @(posedge clk);
    score = 16'd7;     repeat (8) @(posedge clk);
    score = 16'd12;    repeat (8) @(posedge clk);
    score = 16'd123;   repeat (8) @(posedge clk);
    score = 16'd9999;  repeat (8) @(posedge clk);
    score = 16'd10050; repeat (8) @(posedge clk); // should clamp to 9999 visually

    // Reaction time #1: 37 ms 
    pulse("start_evt", start_evt);
    wait_ms(37);
    pulse("stop_evt",  stop_evt);
    repeat (12) @(posedge clk);

    //Reaction time #2: 8 ms 
    pulse("start_evt", start_evt);
    wait_ms(8);
    pulse("stop_evt",  stop_evt);
    repeat (12) @(posedge clk);

    // Finish
    $display("[%0t] TB finished.", $time);
    $finish;
  end

endmodule
