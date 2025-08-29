module clock_divider(
    input clk,              // 50MHz系统时钟
    input rst_n,            // 复位信号，低电平有效
    output reg clk_1hz,     // 1Hz时钟 (1秒周期)
    output reg clk_067hz,   // 0.67Hz时钟 (1.5秒周期)
    output reg clk_05hz     // 0.5Hz时钟 (2秒周期)
);

    // 计数器
    reg [25:0] cnt_1hz;     // 1Hz计数器
    reg [26:0] cnt_067hz;   // 0.67Hz计数器
    reg [26:0] cnt_05hz;    // 0.5Hz计数器
    
    // 计数器最大值 (50MHz时钟)
    parameter MAX_1HZ = 50000000 - 1;    // 1Hz: 50M-1
    parameter MAX_067HZ = 75000000 - 1;  // 0.67Hz: 75M-1 (1.5秒)
    parameter MAX_05HZ = 100000000 - 1;  // 0.5Hz: 100M-1 (2秒)
    
    // 1Hz时钟生成
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt_1hz <= 26'd0;
            clk_1hz <= 1'b0;
        end else begin
            if (cnt_1hz >= MAX_1HZ) begin
                cnt_1hz <= 26'd0;
                clk_1hz <= 1'b1;
            end else begin
                cnt_1hz <= cnt_1hz + 1'b1;
					 clk_1hz <= 1'b0;
            end
        end
    end
    
    // 0.67Hz时钟生成 (1.5秒周期)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt_067hz <= 27'd0;
            clk_067hz <= 1'b0;
        end else begin
            if (cnt_067hz >= MAX_067HZ) begin
                cnt_067hz <= 27'd0;
                clk_067hz <= 1'b1;
            end else begin
                cnt_067hz <= cnt_067hz + 1'b1;
					 clk_067hz <= 1'b0;
            end
        end
    end
    
    // 0.5Hz时钟生成 (2秒周期)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt_05hz <= 27'd0;
            clk_05hz <= 1'b0;
        end else begin
            if (cnt_05hz >= MAX_05HZ) begin
                cnt_05hz <= 27'd0;
                clk_05hz <= ~clk_05hz;
            end else begin
                cnt_05hz <= cnt_05hz + 1'b1;
            end
        end
    end

endmodule