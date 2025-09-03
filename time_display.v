// display 8-bit time value on two 7-seg displays (HEX6 tens, HEX5 ones).
module time_display (
    input  [7:0] time_value,         // lower 8 bits passed from top_level (timer_value[7:0])
    output [6:0] display0,           // ones -> HEX5
    output [6:0] display1            // tens -> HEX6
);
    // Constrain to 0..99 so it fits on two digits.
    wire [7:0] t  = time_value % 8'd100;

    // Split into tens and ones.
    wire [3:0] te = t / 10;          // tens digit
    wire [3:0] on = t % 10;          // ones digit

    // Decode to 7-seg.
    wire [6:0] seg_te, seg_on;
    seg7_decoder u_tens (.bin(te), .seg(seg_te));
    seg7_decoder u_ones (.bin(on), .seg(seg_on));

    // Wire to top-level pins (note: your top maps display1->HEX6, display0->HEX5).
    assign display1 = seg_te;        // HEX6
    assign display0 = seg_on;        // HEX5
endmodule
