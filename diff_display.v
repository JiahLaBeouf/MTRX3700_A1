// diff_display.v
// One-hot difficulty to decimal digit on HEX4.
//   "1" (easy)
//   "2" (medium)
//   "3" (hard)

module diff_display (
    input  wire [2:0] diff,
    output wire [6:0] hex
);
    reg [3:0] digit;
    always @* begin
        case (diff)
            3'b001: digit = 4'd1; // easy
            3'b010: digit = 4'd2; // medium
            3'b100: digit = 4'd3; // hard
            default: digit = 4'd0;
        endcase
    end

    seg7_decoder u_dec (.bin(digit), .seg(hex));
endmodule
