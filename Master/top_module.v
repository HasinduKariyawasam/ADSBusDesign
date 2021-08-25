module top_module(

input clock_in,						// clock signal
input enable,						// enable signal to get inputs from the user
input read_en,						// signal to select data read(=1)/write(=0)
input [7:0] data_in,				// data bits from switches
input [13:0] addr_in,			// address bits fron switches

input data_rx,						//received data from slave
//input slave_ready,				// signal indicating the availability of the slave
input bus_ready,					// signal indicating the availability of the bus
input slave_valid,

output bus_req ,				//signal to request access to the bus

output addr_tx ,				// address for the output data 
output data_tx ,				// output data
output valid ,					// signal that indicates validity of the data from master
output valid_s ,				// valid signal for slave
output master_busy ,			// signal that indicates the availability of the master to get data from user
output [7:0] data_read,

output psegmentA,output psegmentB,output psegmentC,output psegmentD ,output psegmentE,output psegmentF,output psegmentG,
output nsegmentA,output nsegmentB,output nsegmentC,output nsegmentD ,output nsegmentE,output nsegmentF,output nsegmentG,
output wsegmentA,output wsegmentB,output wsegmentC,output wsegmentD ,output wsegmentE,output wsegmentF,output wsegmentG,
output rsegmentA,output rsegmentB,output rsegmentC,output rsegmentD ,output rsegmentE,output rsegmentF,output rsegmentG,
output c1segmentA,output c1segmentB,output c1segmentC,output c1segmentD ,output c1segmentE,output c1segmentF,output c1segmentG,
output c2segmentA,output c2segmentB,output c2segmentC,output c2segmentD ,output c2segmentE,output c2segmentF,output c2segmentG

 );
 
wire clock;
wire [3:0] p_state;
wire [3:0] n_state;
wire [4:0] w_counter ;
wire [4:0] r_counter ;
wire [15:0]clk_counter ;
 
 
 
 
master master(
	.clock(clock),						
	.enable(enable),						
	.read_en(read_en),							
	.data_in(8'b11010101),				
	.addr_in(14'b10110010110010),		

	.data_rx(data_rx),						
	.bus_ready(bus_ready),					
	.slave_valid(slave_valid),
	
	.bus_req(bus_req),	

	.addr_tx(addr_tx),				 
	.data_tx(data_tx),				
	.valid(valid),
	.valid_s(valid_s),
	.master_busy(master_busy),
	.data_read(data_read),
	.present(p_state),
	.next(n_state),
	.w_counter(w_counter),
	.r_counter(r_counter),
	.clk_counter(clk_counter)	

 );

//module to scale down 50MHz clock
clock_divider clock_divider(.inclk(clock_in),.ena(1),.clk(clock));

//Seven segments//
//present state
 bin27 present_state(.clk(clock),.ctrlsig_in(p_state),.segmentA(psegmentA),.segmentB(psegmentB),.segmentC(psegmentC),
.segmentD(psegmentD) ,.segmentE(psegmentE),.segmentF(psegmentF),.segmentG(psegmentG));

//next state
 bin27 next_state(.clk(clock),.ctrlsig_in(n_state),.segmentA(nsegmentA),.segmentB(nsegmentB),.segmentC(nsegmentC),
.segmentD(nsegmentD) ,.segmentE(nsegmentE),.segmentF(nsegmentF),.segmentG(nsegmentG));

//counter in write state
 bin27 w_count(.clk(clock),.ctrlsig_in(w_counter),.segmentA(wsegmentA),.segmentB(wsegmentB),.segmentC(wsegmentC),
.segmentD(wsegmentD) ,.segmentE(wsegmentE),.segmentF(wsegmentF),.segmentG(wsegmentG));

//counter in read state
 bin27 r_count(.clk(clock),.ctrlsig_in(r_counter),.segmentA(rsegmentA),.segmentB(rsegmentB),.segmentC(rsegmentC),
.segmentD(rsegmentD) ,.segmentE(rsegmentE),.segmentF(rsegmentF),.segmentG(rsegmentG));

//counter for number of clock cycles 
 bin27 clk1(.clk(clock),.ctrlsig_in(clk_counter[3:0]),.segmentA(c1segmentA),.segmentB(c1segmentB),.segmentC(c1segmentC),
.segmentD(c1segmentD) ,.segmentE(c1segmentE),.segmentF(c1segmentF),.segmentG(c1segmentG));

 bin27 clk2(.clk(clock),.ctrlsig_in(clk_counter[7:4]),.segmentA(c2segmentA),.segmentB(c2segmentB),.segmentC(c2segmentC),
.segmentD(c2segmentD) ,.segmentE(c2segmentE),.segmentF(c2segmentF),.segmentG(c2segmentG));

endmodule
