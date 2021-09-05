`timescale 1ns/1ps
module top_level_testbench ();

    reg clk, reset,start;
    reg [4:0] state_in;


    always begin
        clk = 1; #10; clk = 0; #10;
    end

    top_level dut(.clk(clk),.reset(reset),.start(start),
                    .state_in(state_in));

    initial begin
        reset = 0; 
        start = 0;   
        state_in = 5'd0; #40;
        
        // M1 writes to S1
        state_in = 5'd1; start = 1; #40; start = 0;
        #1500;
        $stop;
        // M2 writes to S2
        state_in = 5'd2; start = 1; #40; start = 0;
        #1500;
        $stop;

        // M1 reads from S2 and M2 reads from S1
        // state_in = 5'd3; start = 1; #40; start = 0;
        // #3000;

        // M1 writes to S2 and M2 writes to S1
        // state_in = 5'd9; start = 1; #40; start = 0;
        // #3000;

        // // M1 and M2 write at the same time
        // state_in = 5'd7; start = 1; #40; start = 0;
        // #1500;

        // // M1 and M2 read at the same time
        // state_in = 5'd8; start = 1; #40; start = 0;
        // #1500;

        // #2000;
        // state_in = 5'd6; start = 1; #40; start = 0;
        // m1_enable = 0; m1_read_en = 0;
        // m2_enable = 0; m2_read_en = 0;
        // reset = 1; #23; reset = 0;
        // addr_in1 = 14'd1001; data_in1 = 8'd101;
        // m1_enable = 1; #40; m1_enable = 0;
        // #450;

        // m1_read_en = 1; data_in1 = 8'd0; 
        // m1_enable = 1; #40; m1_enable = 0;
        // #1000;

        // m1_read_en = 0;
        // addr_in1 = 14'd5097; data_in1 = 8'd101;
        // m1_enable = 1; #40; m1_enable = 0;
        // #450;

        // m1_read_en = 1; data_in1 = 8'd0; 
        // m1_enable = 1; #40; m1_enable = 0;
        // #1000;


        // addr_in2 = 14'd9193; data_in2 = 8'd101;
        // m2_enable = 1; #40; m2_enable = 0;
        // #450;

        // m2_read_en = 1; data_in2 = 8'd0; 
        // m2_enable = 1; #40; m2_enable = 0;
        // #1000;

        // m1_read_en = 0; m2_read_en = 0;
        // addr_in1 = 14'd5097; data_in1 = 8'd102;
        // addr_in2 = 14'd5098; data_in2 = 8'd102;
        // m1_enable = 1; m2_enable = 1; #40; 
        // m1_enable = 0; m2_enable = 0;
        // #450;

        // m1_read_en = 1; data_in1 = 8'd0; 
        // m1_enable = 1; #40; m1_enable = 0;
        #3000;

        $stop;
    end

endmodule //top_level_testbench