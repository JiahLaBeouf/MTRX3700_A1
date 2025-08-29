module random_generator(
    input clk,              // 系统时钟
    input rst_n,            // 复位信号，低电平有效
    output [4:0] random_pos // 随机位置 (0-17)
);

    // 使用线性反馈移位寄存器(LFSR)生成伪随机数
    reg [15:0] lfsr;
    wire feedback;
    
    // LFSR反馈多项式: x^16 + x^14 + x^13 + x^11 + 1
    assign feedback = lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10];
    
    // LFSR更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 非零初始值
            lfsr <= 16'hACE1;
        end else begin
            lfsr <= {lfsr[14:0], feedback};
        end
    end
    
    // 将16位LFSR映射到0-17的范围
    // 使用模运算确保结果在0-17范围内
    assign random_pos = (lfsr % 18);

endmodule