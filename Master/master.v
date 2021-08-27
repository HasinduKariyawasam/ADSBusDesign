module master(

input clock,						// clock signal
input enable,						// enable signal to get inputs from the user
input read_en,						// signal to select data read(=1)/write(=0)
input [7:0] data_in,				// data bits from switches
input [13:0] addr_in,			// address bits fron switches

input data_rx,						//received data from slave
//input slave_ready,				// signal indicating the availability of the slave
input bus_ready,					// signal indicating the availability of the bus
input slave_valid,

output reg bus_req = 0,				//signal to request access to the bus

output reg addr_tx = 0,				// address for the output data 
output reg data_tx = 0,				// output data
output reg valid = 0,					// signal that indicates validity of the data from master
output reg valid_s = 0,				// valid signal for slave
output reg read_en_slave = 0, 	// signal to select data read(=1)/write(=0) for slave
output reg master_busy = 0,			// signal that indicates the availability of the master to get data from user
output reg [7:0] data_read = 8'd0,
output reg [3:0] present = 4'd0,
output reg [3:0] next = 4'd0,
output reg [4:0] w_counter = 5'd0,
output reg [4:0] r_counter = 5'd0,
output reg [15:0]clk_counter = 16'd0	

 );
 
reg [7:0] data_buffer = 8'd0;		// buffer to keep input data
reg [13:0] addr_buffer = 14'd0;	// buffer to keep input address
//reg [4:0] w_counter = 5'd0;		// counter to count number of transmitted bits
//reg [4:0] r_counter = 5'd0;		// counter to count clock cycles in read operation
reg [1:0] enable_posedge = 2'd0;	// register to identify positive edge of the enable signal
reg clk = 0;
//reg [15:0]clk_counter = 16'd0;

//reg [3:0] present = 4'd0;
//reg [3:0] next = 4'd0;
 
parameter
idle = 4'd0,
fetch = 4'd1,
write1 = 4'd2,
write2 = 4'd3,
write3 = 4'd4,
read1 = 4'd5,
read2 = 4'd6,
read3 = 4'd7,
read4 = 4'd8;

///////////////////////////////////////////////////
//next state decoder
always @(*)
case(present)

idle:
	begin
	if (enable == 1)
		next <= fetch;
	else
		next <= idle;
	end

fetch:
	begin
	if ((read_en == 0) & (bus_ready == 1))
		next <= write1;
	else if ((read_en == 1) & (bus_ready == 1))
		next <= read1;
	else
		next <= fetch;
	end

write1:
	next <= write2;


write2:
	begin
	if  (w_counter < 5'd14)
		next <= write2;	
	else if (w_counter >= 5'd14)
		next <= idle;
	end

	
read1:
	next <= read2;	
	
read2:
	begin
	if  (r_counter < 5'd14)
		next <= read2;
	else if (slave_valid == 1)
		next <= read3;
	else
		next <= read2;
	end


read3:
	begin
	if (r_counter < 5'd8)
		next <= read3;
	else
		next <= idle;
	end

endcase
	

///////////////////////////////////////////////////////
always @(posedge clock)
	begin
	clk_counter <= clk_counter +1;
	present <= next;
	read_en_slave <= ~read_en;
	enable_posedge <= (enable_posedge << 1);
	enable_posedge[0] <= enable;
	clk <= ~clk;
	data_read <= data_buffer;
	end

////////////////////////////////////////////////////////	
always @ (posedge clock)
case(present)
//idle state
idle: 
	begin
	data_buffer <= 8'd0;	
	addr_buffer <= 14'd0;
	bus_req	<= 0;
	master_busy <= 0;
	w_counter <= 5'd0;
	r_counter <= 5'd0;
	addr_tx <= 0;
	data_tx <= 0;
	valid <= 0;
	valid_s <= 0;
	
	end

//take inputs from the user
fetch:
	begin
	bus_req <= 1;
	master_busy <= 1;
	data_buffer <= data_in;
	addr_buffer <= addr_in;
	w_counter <= 5'd0;
	r_counter <= 5'd0;
	end

//write data 
// set data valid signal high
write1:
	begin
	valid <= 1;
	valid_s <= 1;
	w_counter <= 5'd0;
	end


write2:
	begin
	//sending first 6 bits of the address
	if  (w_counter < 5'd6)
		begin
		w_counter <= w_counter + 5'd1;
		valid <= 0;
		addr_tx <= addr_buffer[13];
		addr_buffer <= (addr_buffer << 1);
		end
	
	//sending remaining bits of the address and data
	else if (w_counter < 5'd14)
		begin
		w_counter <= w_counter + 5'd1;
		addr_tx <= addr_buffer[13];
		addr_buffer <= (addr_buffer << 1);
		data_tx <= data_buffer[7];
		data_buffer <= (data_buffer << 1);
		end
			
	else if (w_counter == 5'd14)
		begin
		valid_s <= 0;
		end
	end
	
	

//read data 
// set data valid signal high
read1:
	begin
	valid_s <= 1;
	valid <= 1;
	end	
	
read2:
	begin
	if  (r_counter < 5'd14)	//sending the read address
		begin
		valid <= 0;
		addr_tx <= addr_buffer[13];
		addr_buffer <= (addr_buffer << 1);
		r_counter <= r_counter + 1;
		end
	else if (slave_valid == 1) //wait until slave_valid signal
		begin
		valid_s <= 0;
		r_counter <=0;
		end
	else
		begin
		valid_s <= 0;
		end
	end

//getting inputs from the data_rx
read3:
	begin
	if (r_counter < 5'd8)
		begin
		data_buffer <= (data_buffer << 1);
		data_buffer[0] <= data_rx;
		r_counter <= r_counter + 1;
		end
		
	else
		bus_req	<= 0;
		
	end

endcase


endmodule
 
 
 
 
 
 