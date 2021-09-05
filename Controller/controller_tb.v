`timescale 1ns/1ps
module controller_tb ();
    reg clk,reset,start;
    reg m1_request,m2_request;
    reg [4:0] state_in;
    wire m1_enable,m2_enable;
    wire m1_read_en,m2_read_en;
    wire [7:0] data_in1,data_in2;
    wire [13:0] addr_in1, addr_in2;

    always begin
        clk = 1; #10; clk = 0; #10;
    end

    controller dut(.*);

    initial begin
        reset = 0; 
        start = 0; 
        m1_request = 0; m2_request = 0;
        state_in = 5'd0; #40;
        m1_request = 1; m2_request = 0;
        state_in = 5'd1; start = 1; #40; start = 0;

        #450;
        m1_request = 0; m2_request = 0;

        #50;
        m1_request = 1; m2_request = 0;
        state_in = 5'd2; start = 1; #40; start = 0;

        #450;
        m1_request = 0; m2_request = 0;

        #50;
        m1_request = 1; m2_request = 0;
        state_in = 5'd8; start = 1; #40; start = 0;

    end


endmodule