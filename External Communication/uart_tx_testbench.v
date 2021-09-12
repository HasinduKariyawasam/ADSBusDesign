`timescale 1ns/1ps
module uart_tx_testbench ();
    reg clk, reset;
    reg [7:0] data_in;
    reg tx_external, ack;

    wire data_out;
    wire uart_busy;

    always begin
        clk = 1; #25; clk = 0; #25;
    end

    //dut
    uart_tx dut(.clk(clk), .reset(reset), .data_in(data_in),
                .tx_external(tx_external), .ack(ack),
                .data_out(data_out), .uart_busy(uart_busy));

    initial begin
        data_in = 8'd0; tx_external = 0; ack = 1;
        reset = 1; #63; reset = 0;
        #37;
        tx_external = 1; data_in = 8'd125;
        #50; tx_external = 0; 

        #16000;
        // #6500;
        #18500;
        ack = 0; #550;
        ack = 1; #550;
        ack = 1; #550;
        ack = 0; #550;
        ack = 0; #550;
        ack = 1; #550;
        ack = 1; #550;
        ack = 0; #550;
        ack = 0; #550;
        #2000;
        $stop;
    end

endmodule //uart_tx_testbench