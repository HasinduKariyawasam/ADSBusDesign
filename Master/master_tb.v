`timescale 1ns/1ps

module master_tb();

localparam CLK_PERIOD = 20;

reg clock;						// clock signal
reg enable;						// enable signal to get inputs from the user
reg read_en;							// signal to select data read(=1)/write(=0)
reg [7:0] data_in;				// data bits from switches
reg [13:0] addr_in;			// address bits fron switches

reg data_rx;						//received data from slave
//reg slave_ready;				// signal indicating the availability of the slave ??
reg bus_ready;					// signal indicating the availability of the bus
reg slave_valid;

wire bus_req;


wire addr_tx;				// address for the output data 
wire data_tx;				// output data
wire valid;					// signal that indicates validity of the data from master
wire valid_s;
wire master_busy;	



master master(
	.clock(clock),						
	.enable(enable),						
	.read_en(read_en),							
	.data_in(data_in),				
	.addr_in(addr_in),		

	.data_rx(data_rx),						
//	.slave_ready(slave_ready),
	.bus_ready(bus_ready),					// signal indicating the availability of the bus
	.slave_valid(slave_valid),
	
	.bus_req(bus_req),	

	.addr_tx(addr_tx),				 
	.data_tx(data_tx),				
	.valid(valid),
	.valid_s(valid_s),
	.master_busy(master_busy)			

 );

initial begin
	clock = 1'b0;
	enable = 0;
	bus_ready = 0;
//	slave_ready = 0;
	slave_valid = 0;
	data_rx = 0;
	forever begin
		#(CLK_PERIOD/2);
		clock = ~clock;
	end
end

initial begin
	enable = 0; read_en = 0; bus_ready = 0; 
	#100
	enable = 1;
	read_en = 0;
//	slave_ready = 0;
	data_in = 8'b11010101;
	addr_in = 14'b10110010110010;
	
	#100
	enable = 0;
	bus_ready = 1;
	
	#100
//	slave_ready = 1;
	
///////////////////////////////////////////	
	#500
	enable = 0;
	bus_ready = 0;
//	slave_ready = 0;

	#100
	enable = 1;
	read_en = 0;

//	slave_ready = 0;
	data_in = 8'b11010101;
	addr_in = 14'b10110010110010;
	
	#100
	enable = 0;
	bus_ready = 1;
	
	#40
	bus_ready = 0;
	
	#120
	bus_ready = 1;
//////////////////////////////////////////////////
	#500
	enable = 0;
	bus_ready = 0;
//	slave_ready = 0;

	#100
	enable = 1;
	read_en = 0;
	
//	slave_ready = 0;
	data_in = 8'b11010101;
	addr_in = 14'b10110010110010;
	
	#200
	bus_ready = 1;
	#90
	bus_ready = 0;
	enable = 0;
	
	#400
	bus_ready = 1;

	#1000
	enable = 0;
	bus_ready = 0;
//	slave_ready = 0;

	#10
	$stop;





// 	#100
// 	enable = 1;
// 	read_en = 1;
// //	slave_ready = 0;
// 	data_in = 8'd0;
// 	addr_in = 14'b10101010110010;
	
// 	#100
// 	enable = 0;
// 	bus_ready = 1;
// //	slave_ready = 1;
	
// 	#1000
// 	slave_valid = 1;
	
// 	#20
// 	data_rx = 1;
	
// 	#20
// 	data_rx = 0;
	
// 	#20
// 	data_rx = 1;
	
// 	#20
// 	data_rx = 1;
	
// 	#20
// 	data_rx = 0;
	
// 	#20
// 	data_rx = 1;
	
// 	#20
// 	data_rx = 0;
	
// 	#20
// 	data_rx = 1;
	
// 	#1000
// 	enable = 0;
// 	bus_ready = 0;
// 	slave_valid = 0;

	
	
	
//	#100
//	enable = 1;
//	read = 1;
//	data_rx = 0;
//	addr_in = 13'b1000101011001;
//
//	#1000
//	enable = 1;
//	read = 1;
//	data_rx = 0;
//	addr_in = 13'b1000101011001;

end


endmodule
