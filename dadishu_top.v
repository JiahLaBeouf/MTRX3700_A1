module dadishu_top(
    input clk,                  // 50MHz系统时钟
    input rst_n,                // 复位按键，低电平有效
    input speed1,               // 速度1按键（2秒/次），低电平有效
    input speed2,               // 速度2按键（1.5秒/次），低电平有效
    input speed3,               // 速度3按键（1秒/次），低电平有效
    input [17:0] switches,      // 18个拨码开关
    output [17:0] leds,         // 18个LED
    output [6:0] HEX5, // 倒计时十位数码管
    output [6:0] HEX4, // 倒计时个位数码管
    output [6:0] HEX3, // 分数千位数码管
    output [6:0] HEX2, // 分数百位数码管
    output [6:0] HEX1, // 分数十位数码管
    output [6:0] HEX0, // 分数个位数码管
    output [6:0] HEX6      // 速度档位数码管
);

    // 内部信号定义
    wire clk_1hz;               // 1Hz时钟
    wire clk_067hz;             // 0.67Hz时钟 (1.5秒周期)
    wire clk_05hz;              // 0.5Hz时钟 (2秒周期)
    wire [4:0] random_pos;      // 随机位置 (0-17)
    wire [17:0] target_led;     // 目标LED
    
    wire [5:0] timer;           // 60秒倒计时
    wire [13:0] score;          // 游戏分数 (最大9999)
    wire [1:0] speed_level;     // 速度等级 (0,1,2)
    wire game_over;             // 游戏结束标志
    
    // 时钟分频模块
    clock_divider clock_div_inst(
        .clk(clk),
        .rst_n(rst_n),
        .clk_1hz(clk_1hz),
        .clk_067hz(clk_067hz),
        .clk_05hz(clk_05hz)
    );
    
    // 随机数生成模块
    random_generator rand_gen_inst(
        .clk(clk),
        .rst_n(rst_n),
        .random_pos(random_pos)
    );
    
    // 游戏控制模块
    game_controller game_ctrl_inst(
        .clk(clk),
        .rst_n(rst_n),
        .clk_1hz(clk_1hz),
        .clk_067hz(clk_067hz),
        .clk_05hz(clk_05hz),
        .speed1(speed1),
        .speed2(speed2),
        .speed3(speed3),
        .switches(switches),
        .random_pos(random_pos),
        .timer(timer),
        .score(score),
        .speed_level(speed_level),
        .game_over(game_over),
        .target_led(target_led)
    );
    
    // LED输出
    assign leds = target_led;
    
    // 数码管显示模块 - 倒计时
    seg7_decoder seg_time_tens_inst(
        .bin(timer / 10),
        .seg(HEX5)
    );
    
    seg7_decoder seg_time_ones_inst(
        .bin(timer % 10),
        .seg(HEX4)
    );
    
    // 数码管显示模块 - 分数
    seg7_decoder seg_score_thou_inst(
        .bin(score / 1000),
        .seg(HEX3)
    );
    
    seg7_decoder seg_score_hund_inst(
        .bin((score % 1000) / 100),
        .seg(HEX2)
    );
    
    seg7_decoder seg_score_tens_inst(
        .bin((score % 100) / 10),
        .seg(HEX1)
    );
    
    seg7_decoder seg_score_ones_inst(
        .bin(score % 10),
        .seg(HEX0)
    );
    
    // 数码管显示模块 - 速度档位
    seg7_decoder seg_speed_inst(
        .bin(speed_level + 1),  // 显示1,2,3
        .seg(HEX6)
    );

endmodule