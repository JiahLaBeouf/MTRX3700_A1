// Shows difficulty (1,2,3) on HEX4 from a one-hot diff input:
//   diff = 3'b001 -> "1" (easy)
//   diff = 3'b010 -> "2" (medium)
//   diff = 3'b100 -> "3" (hard)
module diff_display (
    input  [2:0] diff,   // one-hot difficulty from top_level (~KEY[3:1])
    output [6:0] hex     // -> HEX4
);
    // Convert one-hot to numeric digit
    reg  [3:0] digit;
    always @(*) begin
        case (diff)
            3'b001: digit = 4'd1;   // easy
            3'b010: digit = 4'd2;   // medium
            3'b100: digit = 4'd3;   // hard
        endcase
    end

    // Decode with your class seven-seg decoder.
    wire [6:0] seg;
    seg7_decoder u_dec (.bin(digit), .seg(seg));

    // Drive HEX4.
    assign hex = seg;
endmodule
