module seg7_decoder(
    input [3:0] bin,    // 二进制输入 (0-9)
    output reg [6:0] seg // 7段数码管输出 (共阳极)
);

    // 共阳极7段数码管，0表示亮，1表示灭
    // 段码定义: seg = {g,f,e,d,c,b,a}
    always @(*) begin
        case (bin)
            4'd0: seg = 7'b1000000; // 0
            4'd1: seg = 7'b1111001; // 1
            4'd2: seg = 7'b0100100; // 2
            4'd3: seg = 7'b0110000; // 3
            4'd4: seg = 7'b0011001; // 4
            4'd5: seg = 7'b0010010; // 5
            4'd6: seg = 7'b0000010; // 6
            4'd7: seg = 7'b1111000; // 7
            4'd8: seg = 7'b0000000; // 8
            4'd9: seg = 7'b0010000; // 9
            default: seg = 7'b1111111; // 全灭
        endcase
    end

endmodule