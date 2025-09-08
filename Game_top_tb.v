`timescale 1ns/1ps

module dadishu_tb();
    // Input signals
    reg clk;
    reg rst_n;
    reg speed1;
    reg speed2;
    reg speed3;
    reg [17:0] switches;
    
    // Output signals
    wire [17:0] leds;
    wire [6:0] seg_time_tens;
    wire [6:0] seg_time_ones;
    wire [6:0] seg_score_thou;
    wire [6:0] seg_score_hund;
    wire [6:0] seg_score_tens;
    wire [6:0] seg_score_ones;
    wire [6:0] seg_speed;
    
    // Instantiate the top-level module
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
    
    // Clock generation
    initial begin
        clk = 0;
        forever #10 clk = ~clk; // 50 MHz clock, 20 ns period
    end
    
    // Test sequence
    initial begin
        // Initialization
        rst_n   = 1;
        speed1  = 1;
        speed2  = 1;
        speed3  = 1;
        switches = 18'd0;
        
        // Reset pulse (active-low)
        #100 rst_n = 0;
        #100 rst_n = 1;
        
        // Select speed level 2
        #1000 speed2 = 0;
        #100  speed2 = 1;
        
        // Simulate a correct hit
        #5_000_000;          // wait 5 ms
        switches = leds;     // mimic a correct hit
        #100 switches = 18'd0;
        
        // Simulate an incorrect hit
        #5_000_000;                      // wait 5 ms
        switches = ~leds & 18'h3FFFF;    // mimic a wrong hit
        #100 switches = 18'd0;
        
        // Select speed level 3
        #1000 speed3 = 0;
        #100  speed3 = 1;
        
        // Continue simulating correct hits
        repeat (10) begin
            #3_000_000;     // wait 3 ms
            switches = leds;
            #100 switches = 18'd0;
        end
        
        // End simulation
        #10_000_000 $finish;
    end
    
    // Monitor key outputs
    initial begin
        $monitor("Time=%0t, LED=%b, Score=%d%d%d%d, Timer=%d%d, Speed=%d",
                 $time,
                 leds,
                 seg_score_thou, seg_score_hund, seg_score_tens, seg_score_ones,
                 seg_time_tens, seg_time_ones,
                 seg_speed);
    end

endmodule
