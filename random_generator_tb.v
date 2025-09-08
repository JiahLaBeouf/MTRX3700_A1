`timescale 1ns/1ps

module random_generator_tb;

    // Testbench signals
    reg clk;
    reg rst_n;
    wire [4:0] random_pos;

    // Instantiate DUT (Device Under Test)
    random_generator uut (
        .clk(clk),
        .rst_n(rst_n),
        .random_pos(random_pos)
    );

    // Generate a 10ns period clock (100 MHz)
    always #5 clk = ~clk;

    // Test sequence
    initial begin
        // Initialize signals
        clk = 0;
        rst_n = 0;

        // Apply reset for 20ns
        #20;
        rst_n = 1;

        // Run for some time
        #200;

        // Apply reset again mid-simulation
        rst_n = 0;
        #15;
        rst_n = 1;

        // Run again
        #200;

        // Finish simulation
        $finish;
    end

    // Monitor values
    initial begin
        $monitor("Time=%0t | rst_n=%b | random_pos=%0d", $time, rst_n, random_pos);
    end

endmodule
