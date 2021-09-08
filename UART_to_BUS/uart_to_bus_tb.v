`timescale 1ns/1ps

module uart_to_bus_tb();

localparam CLK_PERIOD = 10;

reg clk = 0; //clk50,       // bus clock and 50MHz clock
reg reset;            // reset signal
reg data_rx;          // UART rx
reg bus_ready;		// signal indicating the availability of the bus

wire ack_out;         // external acknowledgement signal out
wire bus_req;
wire addr_tx;		// address for the output data 
wire data_tx;		// output data
wire valid;	    // signal that indicates validity of the data from master
wire valid_s;		// valid signal for slave
wire write_en_slave; 	// signal to select data read(=1)/write(=0) for slave
wire [7:0] data_read;


uart_to_bus dut (.*);

initial begin
      forever begin
        #(CLK_PERIOD/2);
        clk <= ~clk;
      end
    end

initial begin
    reset = 0; data_rx = 1; bus_ready = 0;

    #40;
    data_rx = 0; #10;
    data_rx = 1; #10;
    data_rx = 0; #10;
    data_rx = 1; #10;
    data_rx = 0; #10;
    data_rx = 1; #10;
    data_rx = 0; #10;
    data_rx = 1; #10;
    data_rx = 0; #10;
    data_rx = 1; #100;

    bus_ready = 1;
    #500;

    data_rx = 1; bus_ready = 0;

    #40;
    data_rx = 0; #10;
    data_rx = 1; #10;
    data_rx = 1; #10;
    data_rx = 1; #10;
    data_rx = 0; #10;
    data_rx = 1; #10;
    data_rx = 0; #10;
    data_rx = 0; #10;
    data_rx = 1; #10;
    data_rx = 1; #100;

    bus_ready = 1;
    #500;
    $stop;
end

endmodule