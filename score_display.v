//Score split into thousands/hundreds/tens/ones.
//blank leading zeros on the left so "0024" shows as "24".
module score_display (
    input             clk,           
    input      [15:0] score,         // game score from FSM
    output     [6:0]  display0,      // ones HEX0
    output     [6:0]  display1,      // tens HEX1
    output     [6:0]  display2,      // hund HEX2
    output     [6:0]  display3       // thous HEX3
);
    // never show > 9999, to fit 4 digits
    wire [15:0] s = (score > 16'd9999) ? 16'd9999 : score;

    // Split into decimal digits using integer division/mod.
    wire [3:0] d_th =  s / 1000;            // thousands digit
    wire [3:0] d_hu = (s % 1000) / 100;     // hundreds digit
    wire [3:0] d_te = (s % 100)  / 10;      // tens digit
    wire [3:0] d_on =  s % 10;              // ones digit

    // Running each digit through the class seven-seg decoder.
    wire [6:0] seg_th, seg_hu, seg_te, seg_on;
    seg7_decoder u_th (.bin(d_th), .seg(seg_th));
    seg7_decoder u_hu (.bin(d_hu), .seg(seg_hu));
    seg7_decoder u_te (.bin(d_te), .seg(seg_te));
    seg7_decoder u_on (.bin(d_on), .seg(seg_on));

    //blanking
    localparam [6:0] SEG_BLANK = 7'b1111111;

    // Leading-zero blanking on the left three digits.
    // Ones is never blanked (still show 0).
    assign display3 = (d_th == 4'd0) ? SEG_BLANK : seg_th;                              // HEX3
    assign display2 = (d_th == 4'd0 && d_hu == 4'd0) ? SEG_BLANK : seg_hu;             // HEX2
    assign display1 = (d_th == 4'd0 && d_hu == 4'd0 && d_te == 4'd0) ? SEG_BLANK : seg_te; // HEX1
    assign display0 = seg_on;                                                          // HEX0
endmodule
