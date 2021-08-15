`timescale 1ns/1ps
module address_reader_testbench ();

    reg clk, reset, en, address_in;
    wire [13:0] address;
    wire read_end;

    // clock generation
    always begin
        clk = 1; #5; clk = 0; #5;
    end

    // device under test
    address_reader dut(clk, reset, en, address_in, address, read_end);

    initial begin
        reset = 1; #23; reset = 0; #7;
        en = 0; #20; en = 1;
        address_in = 1; #10;
        address_in = 0; #10;
        address_in = 0; #10;
        address_in = 0; #10;
        address_in = 1; #10;
        address_in = 0; #10;
        address_in = 1; #10;
        address_in = 1; #10;
        address_in = 1; #10;
        address_in = 0; #10;
        address_in = 0; #10;
        address_in = 0; #10;
        address_in = 1; #10;
        address_in = 0; #10; en = 0;
        address_in = 0;
        #50;
        $stop;
    end

endmodule //address_reader_testbench