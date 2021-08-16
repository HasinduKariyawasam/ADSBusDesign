`timescale 1ns/1ps
module arbiter_testbench ();

reg clk, reset;
reg m1_address, m1_data, m1_valid, m1_address_valid, s1_ready, s2_ready, s3_ready;
wire m1_ready;
wire s1_address, s1_data, s1_valid;
wire s2_address, s2_data, s2_valid;
wire s3_address, s3_data, s3_valid;

always begin
    clk = 1; #5; clk = 0; #5;
end

arbiter dut(clk, reset, m1_address, m1_data, m1_valid, m1_address_valid, s1_ready, s2_ready,
            s3_ready, m1_ready, s1_address, s1_data, s1_valid, s2_address,
            s2_data, s2_valid, s3_address, s3_data, s3_valid);

initial begin
    reset = 1;
    m1_address = 0; m1_data = 0; m1_valid = 0; m1_address_valid = 0;
    s1_ready = 0; s2_ready = 0; s3_ready = 0;
    #17;
    reset = 0; #3;
    m1_valid = 1; m1_address_valid = 1; #10;
    m1_address = 1; m1_address_valid = 0; #10;
    m1_address = 0; #10;
    m1_address = 1; #10;
    m1_address = 0; #10;
    m1_address = 1; #10;
    m1_address = 0; #10;
    m1_address = 1; #10;
    m1_address = 1; #10;
    m1_address = 1; #10;
    m1_address = 0; #10;
    m1_address = 0; #10;
    m1_address = 0; #10;
    m1_address = 1; #10;
    m1_address = 1; #10;
    m1_address = 0; #10;

    m1_data = 1; #10;
    m1_data = 0; #10;
    m1_data = 1; #10;
    m1_data = 0; #10;
    m1_data = 1; #10;
    m1_data = 1; #10;
    m1_data = 0; #10;
    m1_data = 1; #10;
    m1_valid = 0;
    #100;
    $stop;
end

endmodule //arbiter_testbench