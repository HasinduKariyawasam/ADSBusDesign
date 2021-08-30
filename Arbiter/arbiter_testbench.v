`timescale 1ns/1ps
module arbiter_testbench ();

reg clk, reset;
reg m1_request, m1_address, m1_data, m1_valid, m1_address_valid, m1_write_en, 
    m2_request, m2_address, m2_data, m2_valid, m2_address_valid, m2_write_en,
    s1_data_in, s2_data_in, s3_data_in,
    s1_ready, s2_ready, s3_ready,
    s1_valid_out, s2_valid_out, s3_valid_out;
wire m1_data_out, m2_data_out;
wire m1_ready, m2_ready, m1_available, m2_available;
wire m1_valid_in, m2_valid_in;
wire s1_address, s1_data, s1_valid, s1_write_en;
wire s2_address, s2_data, s2_valid, s2_write_en;
wire s3_address, s3_data, s3_valid, s3_write_en;
wire [2:0] state;
wire m1_connect1, m1_connect2, m1_connect3;
wire m2_connect1, m2_connect2, m2_connect3;
// wire clk_led, reset_led;

always begin
    clk = 1; #5; clk = 0; #5;
end

arbiter dut(clk, reset, 
            m1_request, m1_address, m1_data, m1_valid, m1_address_valid, m1_write_en, 
            m2_request, m2_address, m2_data, m2_valid, m2_address_valid, m2_write_en,
            s1_data_in, s2_data_in, s3_data_in,
            s1_ready, s2_ready, s3_ready,
            s1_valid_out, s2_valid_out, s3_valid_out, 
            m1_data_out, m2_data_out,
            m1_ready, m2_ready, m1_available, m2_available,
            m1_valid_in, m2_valid_in,
            s1_address, s1_data, s1_valid, s1_write_en,
            s2_address, s2_data, s2_valid, s2_write_en,
            s3_address, s3_data, s3_valid, s3_write_en, state,
            m1_connect1, m1_connect2, m1_connect3,
            m2_connect1, m2_connect2, m2_connect3);

// arbiter_board_test dut(clk, reset, 
//                         m1_request, m1_address, m1_data, m1_valid, m1_address_valid, 
//                         m2_request, m2_address, m2_data, m2_valid, m2_address_valid,
//                         s1_ready, s2_ready, s3_ready, 
//                         m1_ready, m2_ready, m1_available, m2_available,
//                         s1_address, s1_data, s1_valid, 
//                         s2_address, s2_data, s2_valid, 
//                         s3_address, s3_data, s3_valid, 
//                         state,
//                         m1_connect1, m1_connect2, m1_connect3,
//                         m2_connect1, m2_connect2, m2_connect3,
//                         clk_led, reset_led);

initial begin
    reset = 1;
    m1_request = 0; m1_address = 0; m1_data = 0; m1_valid = 0; m1_address_valid = 0;
    m2_request = 0; m2_address = 0; m2_data = 0; m2_valid = 0; m2_address_valid = 0;
    s1_ready = 1; s2_ready = 1; s3_ready = 1;
    #17;
    reset = 0; #3;
    m1_request = 1; m1_address_valid = 1; #10;
    m1_address_valid = 0; #10;
    m1_valid = 1; #10;
    m1_address = 0; #10;
    m1_address = 1; #20;
    m1_address = 1; #10;
    m1_address = 0; #10;
    m1_address = 1; #10;
    m1_address = 0; #10;
    m1_address = 1; #10;
    m1_address = 1; m1_data = 1; #10;
    m1_address = 1; m1_data = 0; #10;
    m1_address = 0; m1_data = 1; #10;
    m1_address = 0; m1_data = 0; #10;
    m1_address = 0; m1_data = 1; #10;
    m1_address = 1; m1_data = 1; #10;
    m1_address = 1; m1_data = 0; #10;
    m1_address = 0; m1_data = 1; #10;

    // m1_valid = 0;
    // #100;

    // m1_valid = 1; 
    // m1_address_valid = 1; #10;
    // m1_address_valid = 0; #20;
    m1_address = 0; #10;
    m1_address = 1; #20;
    m1_address = 1; #10;
    m1_address = 0; m2_request = 1; m2_address_valid = 1; #10;
    m1_address = 1; m2_address_valid = 0; #10;
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
    #10;
    s2_ready = 0; #60;
    m2_valid = 1; #10;

    m2_address = 0; #10;
    m2_address = 1; #20;
    m2_address = 1; #10;
    m2_address = 0; #10;
    m2_address = 1; #10;
    m2_address = 0; #10;
    m2_address = 1; #10;
    m2_address = 1; #10;
    m2_address = 1; #10;
    m2_address = 0; #10;
    m2_address = 0; #10;
    m2_address = 0; #10;
    m2_address = 1; #10;
    m2_address = 1; #10;
    m2_address = 0; #10;

    // m1_data = 1; #10;
    // m1_data = 0; #10;
    // m1_data = 1; #10;
    // m1_data = 0; #10;
    // m1_data = 1; #10;
    // m1_data = 1; #10;
    // m1_data = 0; #10;
    // m1_data = 1; #10;
    // m1_valid = 0;
    // #100;

    // // m1_valid = 1; 
    // m1_address_valid = 1; #10;
    // m1_address = 0; m1_address_valid = 0; #10;
    // m1_address = 1; #10;
    // m1_address = 1; #10;
    // m1_address = 0; #10;
    // m1_address = 1; #10;
    // m1_address = 0; #10;
    // m1_address = 1; #10;
    // m1_address = 1; #10;
    // m1_address = 1; #10;
    // m1_address = 0; #10;
    // m1_address = 0; #10;
    // m1_address = 0; #10;
    // m1_address = 1; #10;
    // m1_address = 1; #10;
    // m1_address = 0; #10;

    // m1_data = 1; #10;
    // m1_data = 0; #10;
    // m1_data = 1; #10;
    // m1_data = 0; #10;
    // m1_data = 1; #10;
    // m1_data = 1; #10;
    // m1_data = 0; #10;
    // m1_data = 1; #10;
    // m1_valid = 0; m1_request = 0; 

    // // master 2
    // m2_request = 1; #10;
    // #10;
    // m2_valid = 1; m2_address_valid = 1; #10;
    // m2_address = 1; m2_address_valid = 0; #10;
    // m2_address = 0; #10;
    // m2_address = 1; #10;
    // m2_address = 0; #10;
    // m2_address = 1; #10;
    // m2_address = 0; #10;
    // m2_address = 1; #10;
    // m2_address = 1; #10;
    // m2_address = 1; #10;
    // m2_address = 0; #10;
    // m2_address = 0; #10;
    // m2_address = 0; #10;
    // m2_address = 1; #10;
    // m2_address = 1; #10;
    // m2_address = 0; #10;

    // m2_data = 1; #10;
    // m2_data = 0; #10;
    // m2_data = 1; #10;
    // m2_data = 0; #10;
    // m2_data = 1; #10;
    // m2_data = 1; #10;
    // m2_data = 0; #10;
    // m2_data = 1; #10;
    // // m1_valid = 0;
    // // #100;

    // // m1_valid = 1; 
    // m2_address_valid = 1; #10;
    // m2_address = 0; m2_address_valid = 0; #10;
    // m2_address = 1; #10;
    // m2_address = 1; #10;
    // m2_address = 0; #10;
    // m2_address = 1; #10;
    // m2_address = 0; #10;
    // m2_address = 1; #10;
    // m2_address = 1; #10;
    // m2_address = 1; #10;
    // m2_address = 0; #10;
    // m2_address = 0; #10;
    // m2_address = 0; #10;
    // m2_address = 1; #10;
    // m2_address = 1; #10;
    // m2_address = 0; #10;

    // m2_data = 1; #10;
    // m2_data = 0; #10;
    // m2_data = 1; #10;
    // m2_data = 0; #10;
    // m2_data = 1; #10;
    // m2_data = 1; #10;
    // m2_data = 0; #10;
    // m2_data = 1; #10;
    // // m1_valid = 0;
    // // #100;

    // // m1_valid = 1; 
    // m2_address_valid = 1; #10;
    // m2_address = 0; m2_address_valid = 0; #10;
    // m2_address = 1; #10;
    // m2_address = 1; #10;
    // m2_address = 0; #10;
    // m2_address = 1; #10;
    // m2_address = 0; #10;
    // m2_address = 1; #10;
    // m2_address = 1; #10;
    // m2_address = 1; #10;
    // m2_address = 0; #10;
    // m2_address = 0; #10;
    // m2_address = 0; #10;
    // m2_address = 1; #10;
    // m2_address = 1; #10;
    // m2_address = 0; #10;

    // m2_data = 1; #10;
    // m2_data = 0; #10;
    // m2_data = 1; #10;
    // m2_data = 0; #10;
    // m2_data = 1; #10;
    // m2_data = 1; #10;
    // m2_data = 0; #10;
    // m2_data = 1; #10;
    // m2_valid = 0; m2_request = 0;

    // #50;

    // m1_request = 1; m2_request = 1; #10;
    // #10;
    // m1_valid = 1; m1_address_valid = 1; #10;
    // m1_address = 1; m1_address_valid = 0; #10;
    // m1_address = 0; #10;
    // m1_address = 1; #10;
    // m1_address = 0; #10;
    // m1_address = 1; #10;
    // m1_address = 0; #10;
    // m1_address = 1; #10;
    // m1_address = 1; #10;
    // m1_address = 1; #10;
    // m1_address = 0; #10;
    // m1_address = 0; #10;
    // m1_address = 0; #10;
    // m1_address = 1; #10;
    // m1_address = 1; #10;
    // m1_address = 0; #10;

    // m1_data = 1; #10;
    // m1_data = 0; #10;
    // m1_data = 1; #10;
    // m1_data = 0; #10;
    // m1_data = 1; #10;
    // m1_data = 1; #10;
    // m1_data = 0; #10;
    // m1_data = 1; #10;
    #100;
    $stop;
end

endmodule //arbiter_testbench