`timescale 1ns/1ps

module dadishu_tb();
    // 输入信号
    reg clk;
    reg rst_n;
    reg speed1;
    reg speed2;
    reg speed3;
    reg [17:0] switches;
    
    // 输出信号
    wire [17:0] leds;
    wire [6:0] seg_time_tens;
    wire [6:0] seg_time_ones;
    wire [6:0] seg_score_thou;
    wire [6:0] seg_score_hund;
    wire [6:0] seg_score_tens;
    wire [6:0] seg_score_ones;
    wire [6:0] seg_speed;
    
    // 实例化顶层模块
    dadishu_top dut(
        .clk(clk),
        .rst_n(rst_n),
        .speed1(speed1),
        .speed2(speed2),
        .speed3(speed3),
        .switches(switches),
        .leds(leds),
        .seg_time_tens(seg_time_tens),
        .seg_time_ones(seg_time_ones),
        .seg_score_thou(seg_score_thou),
        .seg_score_hund(seg_score_hund),
        .seg_score_tens(seg_score_tens),
        .seg_score_ones(seg_score_ones),
        .seg_speed(seg_speed)
    );
    
    // 时钟生成
    initial begin
        clk = 0;
        forever #10 clk = ~clk; // 50MHz时钟，周期20ns
    end
    
    // 测试过程
    initial begin
        // 初始化
        rst_n = 1;
        speed1 = 1;
        speed2 = 1;
        speed3 = 1;
        switches = 18'd0;
        
        // 复位
        #100 rst_n = 0;
        #100 rst_n = 1;
        
        // 选择速度2
        #1000 speed2 = 0;
        #100 speed2 = 1;
        
        // 模拟打击
        #5000000; // 等待5ms
        switches = leds; // 模拟正确打击
        #100 switches = 18'd0;
        
        // 模拟错误打击
        #5000000; // 等待5ms
        switches = ~leds & 18'h3FFFF; // 模拟错误打击
        #100 switches = 18'd0;
        
        // 选择速度3
        #1000 speed3 = 0;
        #100 speed3 = 1;
        
        // 继续模拟打击
        repeat (10) begin
            #3000000; // 等待3ms
            switches = leds; // 模拟正确打击
            #100 switches = 18'd0;
        end
        
        // 结束仿真
        #10000000 $finish;
    end
    
    // 监控输出
    initial begin
        $monitor("Time=%0t, LED=%b, Score=%d%d%d%d, Timer=%d%d, Speed=%d",
                 $time,
                 leds,
                 seg_score_thou, seg_score_hund, seg_score_tens, seg_score_ones,
                 seg_time_tens, seg_time_ones,
                 seg_speed);
    end

endmodule