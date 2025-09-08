`timescale 1ns/1ps
// synthesis translate_off
module seg7_decoder_tb;
  reg  [3:0] bin;
  wire [6:0] seg;

  // DUT instance
  seg7_decoder DUT (
    .bin (bin),
    .seg (seg)
  );

  integer i;
  reg [6:0] expected;

  // Pretty print helper
  task show;
    input [3:0]  b;
    input [6:0]  s;
    input [6:0]  e;
    begin
      $display("t=%0t ns  bin=%0d (0x%0h)  seg=%07b  exp=%07b  %s",
               $time, b, b, s, e, (s===e) ? "OK" : "MISMATCH");
    end
  endtask

  initial begin
    $display("=== seg7_decoder TB (common anode, seg={g,f,e,d,c,b,a}) ===");
    bin = 0;
    #1;

    for (i = 0; i < 16; i = i + 1) begin
      bin = i[3:0];
      #1; // allow combinational logic to settle

      case (i)
        0: expected = 7'b1000000; // 0
        1: expected = 7'b1111001; // 1
        2: expected = 7'b0100100; // 2
        3: expected = 7'b0110000; // 3
        4: expected = 7'b0011001; // 4
        5: expected = 7'b0010010; // 5
        6: expected = 7'b0000010; // 6
        7: expected = 7'b1111000; // 7
        8: expected = 7'b0000000; // 8
        9: expected = 7'b0010000; // 9
        default: expected = 7'b1111111; // 全灭
      endcase

      if (seg !== expected) begin
        $error("Mismatch at bin=%0d: got seg=%07b, exp=%07b", i, seg, expected);
      end else begin
        $display("[PASS] bin=%0d -> seg=%07b", i, seg);
      end

      show(bin, seg, expected);
      #9; // 每个输入保持约10ns，便于在波形中分隔
    end

    $display("[DONE] seg7_decoder self-check finished at t=%0t ns", $time);
    $finish;
  end
endmodule
// synthesis translate_on
