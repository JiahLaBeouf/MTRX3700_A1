// score_display.v
// 16-bit score on 4x 7-seg (HEX3..HEX0).
// 0..9999
// leading zeros on the left three digits
module score_display (
    input  wire        clk,        // not used internally
    input  wire [15:0] score,      // from FSM
    output wire [6:0]  display0,   // ones HEX0
    output wire [6:0]  display1,   // tens HEX1
    output wire [6:0]  display2,   // hund HEX2
    output wire [6:0]  display3    // thous HEX3
);
    // prevent overflow 4 digits
    wire [15:0] s = (score > 16'd9999) ? 16'd9999 : score;

    // split to BCD
    wire [3:0] d_th =  s / 16'd1000;
    wire [3:0] d_hu = (s % 16'd1000) / 16'd100;
    wire [3:0] d_te = (s % 16'd100)  / 16'd10;
    wire [3:0] d_on =  s % 16'd10;

    // decode to segs
    wire [6:0] seg_th, seg_hu, seg_te, seg_on;
    seg7_decoder u_th (.bin(d_th), .seg(seg_th));
    seg7_decoder u_hu (.bin(d_hu), .seg(seg_hu));
    seg7_decoder u_te (.bin(d_te), .seg(seg_te));
    seg7_decoder u_on (.bin(d_on), .seg(seg_on));

    // leading zero blanking on left 3 digits
    localparam [6:0] BLANK = 7'b1111111;
    assign display3 = (d_th==0)                           ? BLANK : seg_th; // HEX3
    assign display2 = (d_th==0 && d_hu==0)                ? BLANK : seg_hu; // HEX2
    assign display1 = (d_th==0 && d_hu==0 && d_te==0)     ? BLANK : seg_te; // HEX1
    assign display0 = seg_on;                                                    // HEX0
endmodule
