module game_controller(

    input clk,                  // 系统时钟
    input rst_n,                // 复位信号，低电平有效
    input clk_1hz,              // 1Hz时钟
    input clk_067hz,            // 0.67Hz时钟 (1.5秒周期)
    input clk_05hz,             // 0.5Hz时钟 (2秒周期)
    input speed1,               // 速度1按键 (2秒/次)，低电平有效
    input speed2,               // 速度2按键 (1.5秒/次)，低电平有效
    input speed3,               // 速度3按键 (1秒/次)，低电平有效
    input [17:0] switches,      // 18个拨码开关
    input [4:0] random_pos,     // 随机位置 (0-17)
    output reg [5:0] timer,     // 60秒倒计时
    output reg [13:0] score,    // 游戏分数 (最大9999)
    output reg [1:0] speed_level, // 速度等级 (0,1,2)
    output reg game_over,       // 游戏结束标志
    output reg [17:0] target_led // 目标LED
);

    // 游戏状态
    reg [17:0] prev_switches;   // 上一个时钟周期的开关状态
    reg [17:0] curr_target;     // 当前目标
    reg target_hit;             // 目标被击中标志
    wire game_clk;              // 游戏时钟，根据速度选择
    
	 // Debounced switch signals
    wire [17:0] switches_stable;
    wire [17:0] switch_changed;

    // Instantiate debounce module (10ms @ 50MHz by default)
    debounce #(
        .CLK_HZ(50_000_000),
        .DEBOUNCE_MS(10)
	)u_sw_deb(
        .clk             (clk),
        .rst_n           (rst_n),
        .switches        (switches),
        .switches_stable (switches_stable),
        .switch_changed  (switch_changed)
    );
	 
    // 游戏时钟选择
    assign game_clk = (speed_level == 2'b00) ? clk_05hz :   // 速度1: 0.5Hz (2秒/次)
                     (speed_level == 2'b01) ? clk_067hz :  // 速度2: 0.67Hz (1.5秒/次)
                     clk_1hz;                              // 速度3: 1Hz (1秒/次)
    
    // 速度控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            speed_level <= 2'b00;  // 默认速度1 (2秒/次)
        end else begin
            if (!speed1) begin
                speed_level <= 2'b00;  // 速度1 (2秒/次)
            end else if (!speed2) begin
                speed_level <= 2'b01;  // 速度2 (1.5秒/次)
            end else if (!speed3) begin
                speed_level <= 2'b10;  // 速度3 (1秒/次)
            end
        end
    end
    
    // 游戏计时器
    always @(posedge clk_1hz or negedge rst_n) begin
        if (!rst_n) begin
            timer <= 6'd60;     // 初始60秒
            game_over <= 1'b0;  // 游戏未结束
        end else begin
            if (timer > 6'd0) begin
                timer <= timer - 1'b1;
            end else begin
                game_over <= 1'b1;  // 游戏结束
					 timer <= 6'd0;
            end
        end
    end
    
    // save the state of the switch(which is 1 or 0)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_switches <= 18'd0;
        end else begin
            prev_switches <= switches;
        end
    end
    
    // target LED control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            curr_target <= 18'd0;
            target_led <= 18'd0;
		  end else if (target_hit)begin
            curr_target <= 18'd0;
            target_led <= 18'd0;			
        end else if (!game_over) begin
            // 只在游戏未结束时更新目标
				if(game_clk)begin
            curr_target <= 18'd1 << random_pos;  // 将随机位置转换为one-hot编码
            target_led <= 18'd1 << random_pos;
			end else begin
				curr_target<=curr_target;
				target_led<=target_led;
				end
        end else begin
            // 游戏结束时关闭所有LED
				curr_target <= 18'd0;
            target_led <= 18'd0;
        end
    end
    
    // 检测击中和计分
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            score <= 14'd0;     // 初始分数为0
            target_hit <= 1'b0;
        end else if (!game_over) begin
            // 只在游戏未结束时更新分数
            
            // 检测稳定后新按下的开关
            if ((switches_stable & switch_changed) != 18'd0) begin
                if ((switches_stable & switch_changed & curr_target) != 18'd0) begin
                    // 击中目标
                    score <= score + 1'b1;
                    target_hit <= 1'b1;
                end else if (score > 14'd0) begin
                    // 未击中目标且分数大于0，减分
                    score <= score - 1'b1;
                    target_hit <= 1'b0;
                end
            end else begin
                target_hit <= 1'b0;
            end
        end
    end
endmodule
