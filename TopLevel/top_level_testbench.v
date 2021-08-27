`timescale 1ns/1ps
module top_level_testbench ();

    reg clk, reset;
    reg m1_enable, m1_read_en, m2_enable, m2_read_en;
    reg [7:0] data_in1, data_in2;
    reg [13:0] addr_in1, addr_in2;

    always begin
        clk = 1; #10; clk = 0; #10;
    end

    top_level dut(.clk(clk),
                  .reset(reset),
                  .m1_enable(m1_enable),
                  .m1_read_en(m1_read_en),
                  .m2_enable(m2_enable),
                  .m2_read_en(m2_read_en),
                  .data_in1(data_in1),
                  .addr_in1(addr_in1),
                  .data_in2(data_in2),
                  .addr_in2(addr_in2));

    initial begin
        m1_enable = 0; m1_read_en = 0;
        m2_enable = 0; m2_read_en = 0;
        reset = 1; #23; reset = 0;
        addr_in1 = 14'd1001; data_in1 = 8'd101;
        m1_enable = 1; #40; m1_enable = 0;
        #450;

        m1_read_en = 1; data_in1 = 8'd0; 
        m1_enable = 1; #40; m1_enable = 0;
        #1000;

        m1_read_en = 0;
        addr_in1 = 14'd5097; data_in1 = 8'd101;
        m1_enable = 1; #40; m1_enable = 0;
        #450;

        m1_read_en = 1; data_in1 = 8'd0; 
        m1_enable = 1; #40; m1_enable = 0;
        #1000;


        addr_in2 = 14'd9193; data_in2 = 8'd101;
        m2_enable = 1; #40; m2_enable = 0;
        #450;

        m2_read_en = 1; data_in2 = 8'd0; 
        m2_enable = 1; #40; m2_enable = 0;
        #1000;

        m1_read_en = 0; m2_read_en = 0;
        addr_in1 = 14'd5097; data_in1 = 8'd102;
        addr_in2 = 14'd5098; data_in2 = 8'd102;
        m1_enable = 1; m2_enable = 1; #40; 
        m1_enable = 0; m2_enable = 0;
        #450;

        m1_read_en = 1; data_in1 = 8'd0; 
        m1_enable = 1; #40; m1_enable = 0;
        #1000;

        $stop;
    end

endmodule //top_level_testbench