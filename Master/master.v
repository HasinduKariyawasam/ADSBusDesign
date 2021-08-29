module master(

input clock,						// clock signal
input enable,						// enable signal to get inputs from the user
input read_en,						// signal to select data read(=1)/write(=0)
input [7:0] data_in,				// data bits from switches
input [13:0] addr_in,			// address bits fron switches
input [2:0] burst_mode_in,

input data_rx,						//received data from slave
input slave_ready,					// signal indicating the availability of the slave
input bus_ready,					// signal indicating the availability of the bus
input slave_valid,

output reg bus_req = 0,				//signal to request access to the bus

output reg addr_tx = 0,				// address for the output data 
output reg data_tx = 0,				// output data
output reg valid = 0,					// signal that indicates validity of the data from master
output reg valid_s = 0,				// valid signal for slave
output reg write_en_slave = 0, 	// signal to select data read(=1)/write(=0) for slave
output reg burst_mode = 0,
output reg master_busy = 0,			// signal that indicates the availability of the master to get data from user
output reg [7:0] data_read = 8'd0,
output reg [4:0] present = 5'd0,
output reg [4:0] next = 5'd0,
output reg [4:0] w_counter = 5'd0,
output reg [4:0] r_counter = 5'd0,
output reg [15:0]clk_counter = 16'd0	
);
 

reg [7:0] data_buffer = 8'd0;		// buffer to keep input data
reg [7:0] data_buffer_inc = 8'd0;
reg [13:0] addr_buffer = 14'd0;		// buffer to keep input address
reg [2:0] burst_mode_buffer = 3'd0; 	// buffer to keep burst mode
//reg [4:0] w_counter = 5'd0;		// counter to count number of transmitted bits
//reg [4:0] r_counter = 5'd0;		// counter to count clock cycles in read operation
reg [1:0] enable_posedge = 2'd0;	// register to identify positive edge of the enable signal
reg clk = 0;
//reg [15:0]clk_counter = 16'd0;
reg [9:0] burst_counter = 10'd0;
reg [9:0] burst_size = 10'd0;

//reg [3:0] present = 4'd0;
//reg [3:0] next = 4'd0;
 
parameter
idle = 5'd0,
check_bus = 5'd1,
fetch = 5'd2,
write1 = 5'd3,
write2 = 5'd4,
write3 = 5'd5,
write4 = 5'd6,
read1 = 5'd7,
read2 = 5'd8,
read3 = 5'd9,
read4 = 5'd10,
read5 = 5'd11,
burst_wr1 = 5'd12,
burst_wr2 = 5'd13,
burst_wr3 = 5'd14,
burst_wr4 = 5'd15,
burst_wr5 = 5'd16,
burst_wr6 = 5'd17,
burst_rd1 = 5'd18,
burst_rd2 = 5'd19,
burst_rd3 = 5'd20,
burst_rd4 = 5'd21,
burst_rd5 = 5'd22,
burst_rd6 = 5'd23;

///////////////////////////////////////////////////
//next state decoder
always @(*)
case(present)

idle:
	begin
	if (enable == 1)
		next <= check_bus;
	else
		next <= idle;
	end

check_bus: next <= fetch;

fetch:
	begin
	if ((read_en == 0) & (bus_ready == 1)) begin
		if (burst_mode_in == 3'd0)
			next <= write1;
		else 
			next <= burst_wr1;
		end
		
	

	else if ((read_en == 1) & (bus_ready == 1)) begin
		if (burst_mode_in == 3'd0)
			next <= read1;
		else 
			next <= burst_rd1;
	end

	else
		next <= fetch;
	end

write1:
	next <= write2;


write2:
	begin
	if  (w_counter < 5'd2)
		next <= write2;	
	else if (w_counter >= 5'd2)
		next <= write3;
	end

write3:
	next <= write4;

write4:
	begin
	if  (w_counter < 5'd14)
		next <= write4;	
	else if (w_counter >= 5'd14)
		next <= idle;
	end

	
read1:
	next <= read2;	
	
read2:
	begin
	if  (r_counter < 5'd2)
		next <= read2;
	else
		next <= read3;
	end

read3:
	next <= read4;

read4:
	begin
	if  (r_counter < 5'd14)
		next <= read4;
	else if (slave_valid == 1)
		next <= read5;
	else
		next <= read4;
	end

read5:
	begin
	if (r_counter < 5'd8)
		next <= read5;
	else
		next <= idle;
	end

burst_wr1:begin
	next <= burst_wr2;
end

burst_wr2: begin
	if  (w_counter < 5'd2)
		next <= burst_wr2;
	else 
		next <= burst_wr3;
end

burst_wr3: next <= burst_wr4;

burst_wr4: begin
	if  (w_counter < 5'd6)
		next <= burst_wr4;

	else if (w_counter < 5'd11)
		next <= burst_wr4;

	else if (w_counter < 5'd14)
		next <= burst_wr4;

	else if (w_counter == 5'd14)
		next <= burst_wr5;
end

burst_wr5:begin
	if (burst_counter < burst_size) begin
		if (slave_ready == 1 ) 
			next <= burst_wr6;

		else
			next <= burst_wr5;
	end

	else 
		next <= idle;
end

burst_wr6: begin
	if (w_counter < 5'd8)
		next <= burst_wr6;

	else
		next <= burst_wr5; 
end

burst_rd1:
	next <= burst_rd2;	
	
burst_rd2:
	begin
	if  (r_counter < 5'd2)
		next <= burst_rd2;
	else
		next <= burst_rd3;
	end

burst_rd3:
	next <= burst_rd4;

burst_rd4:
	begin
	if  (r_counter < 5'd14)
		next <= burst_rd4;
	else if (slave_valid == 1)
		next <= burst_rd5;
	else
		next <= burst_rd4;
	end

burst_rd5:
	begin
	if (r_counter < 5'd8)
		next <= burst_rd5;
	else
		next <= burst_rd6;
	end

burst_rd6: begin
	if (burst_counter < burst_size) begin
		if (slave_valid == 1)
			next <= burst_rd5;
		else	
			next <= burst_rd6;
	end

	else
		next <= idle;

end

endcase
	

///////////////////////////////////////////////////////
always @(posedge clock)
	begin
	clk_counter <= clk_counter +1;
	present <= next;
	write_en_slave <= ~read_en;
	enable_posedge <= (enable_posedge << 1);
	enable_posedge[0] <= enable;
	clk <= ~clk;
	end

////////////////////////////////////////////////////////	
always @ (posedge clock)
case(present)
//idle state
idle: 
	begin
	data_buffer <= 8'd0;	
	addr_buffer <= 14'd0;
	// bus_req	<= 0;
	master_busy <= 0;
	w_counter <= 5'd0;
	r_counter <= 5'd0;
	burst_counter = 10'd0;
	burst_size = 10'd0;

	addr_tx <= 0;
	data_tx <= 0;
	// valid <= 0;
	valid_s <= 0;
	if (enable==1) begin
		bus_req <= 1;
		valid <= 1;
	end	
	else begin
		bus_req <= 0;
		valid <= 0;
	end			
	
	end

//take inputs from the user
fetch:
	begin
		bus_req <= 1;
		master_busy <= 1;
		data_buffer <= data_in;
		data_buffer_inc <= data_in;
		addr_buffer <= addr_in;
		burst_mode_buffer <= burst_mode_in;
		w_counter <= 5'd0;
		r_counter <= 5'd0;
		if (bus_ready)	valid <= 0;
		else			valid <= 1;


		if (burst_mode_in == 3'd1) 
			burst_size <= 10'd8;
		else if (burst_mode_in == 3'd2) 
			burst_size <= 10'd16;
		else if (burst_mode_in == 3'd3) 
			burst_size <= 10'd32;
		else if (burst_mode_in == 3'd4) 
			burst_size <= 10'd64;
		else if (burst_mode_in == 3'd5) 
			burst_size <= 10'd128;
		else if (burst_mode_in == 3'd6) 
			burst_size <= 10'd256;
		else if (burst_mode_in == 3'd7) 
			burst_size <= 10'd512;
		else 
			burst_size <= 10'd0;
		
	
	end

//write data 
// set data valid signal high
write1:
	begin
	valid <= 0;
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

write3:
	begin
		valid_s <= 1;
	end

write4:
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
	valid <= 0;
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

read3:
	begin
	valid_s <= 1;
	end	
	
read4:
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
read5:
	begin
	if (r_counter < 5'd8)
		begin
		data_buffer <= (data_buffer << 1);
		data_buffer[0] <= data_rx;
		data_read <= data_buffer;
		r_counter <= r_counter + 1;
		end
		
	else
		data_read <= data_buffer;
		// bus_req	<= 0;
		
end

burst_wr1:begin
	valid <= 0;
	valid_s <= 1;
	burst_mode <= 1;
	w_counter <= 5'd0;
end

burst_wr2: begin
	if  (w_counter < 5'd6)
		begin
		w_counter <= w_counter + 5'd1;
		valid <= 0;
		addr_tx <= addr_buffer[13];
		addr_buffer <= (addr_buffer << 1);
	end
	

	else if (w_counter < 5'd11)
		begin
		w_counter <= w_counter + 5'd1;
		addr_tx <= addr_buffer[13];
		addr_buffer <= (addr_buffer << 1);
		data_tx <= data_buffer[7];
		data_buffer <= (data_buffer << 1);
	end

	else if (w_counter < 5'd14)
		begin
		w_counter <= w_counter + 5'd1;
		addr_tx <= addr_buffer[13];
		addr_buffer <= (addr_buffer << 1);
		data_tx <= data_buffer[7];
		data_buffer <= (data_buffer << 1);
		burst_mode <= burst_mode_buffer[2];
		burst_mode_buffer <= (burst_mode_buffer << 1);
	end	

	else if (w_counter == 5'd14)
		begin
		burst_counter <= burst_counter + 10'd1;
		valid_s <= 0;
		data_buffer_inc <= data_buffer_inc + 8'd1;
	end
end

burst_wr3: valid_s <= 1;

burst_wr4: begin
	if  (w_counter < 5'd6)
		begin
		w_counter <= w_counter + 5'd1;
		valid <= 0;
		addr_tx <= addr_buffer[13];
		addr_buffer <= (addr_buffer << 1);
	end
	

	else if (w_counter < 5'd11)
		begin
		w_counter <= w_counter + 5'd1;
		addr_tx <= addr_buffer[13];
		addr_buffer <= (addr_buffer << 1);
		data_tx <= data_buffer[7];
		data_buffer <= (data_buffer << 1);
	end

	else if (w_counter < 5'd14)
		begin
		w_counter <= w_counter + 5'd1;
		addr_tx <= addr_buffer[13];
		addr_buffer <= (addr_buffer << 1);
		data_tx <= data_buffer[7];
		data_buffer <= (data_buffer << 1);
		burst_mode <= burst_mode_buffer[2];
		burst_mode_buffer <= (burst_mode_buffer << 1);
	end	

	else if (w_counter == 5'd14)
		begin
		burst_counter <= burst_counter + 10'd1;
		valid_s <= 0;
		data_buffer_inc <= data_buffer_inc + 8'd1;
	end
end

burst_wr5:begin
	if (burst_counter < burst_size) begin
		if (slave_ready == 1 ) begin
			valid_s <= 1;
			burst_mode <= 1;
			data_buffer <= data_buffer_inc;
			w_counter <= 5'd0;
		end

		else
			valid_s <= 0;
	end

	else
		valid_s <= 0;
	
end

burst_wr6: begin
	if (w_counter < 5'd8) begin
		w_counter <= w_counter + 5'd1;
		data_tx <= data_buffer[7];
		data_buffer <= (data_buffer << 1);
	end

	else begin
		burst_counter <= burst_counter + 1;
		data_buffer_inc <= data_buffer_inc + 8'd1;
		valid_s <= 0;
	end

end

burst_rd1:begin
	valid_s <= 1;
	burst_mode <= 1;
	valid <= 0;
	// next <= burst_rd2;
end

burst_rd2:
	begin
	if  (r_counter < 5'd11)	//sending the read address
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

burst_rd3:
	begin
	valid_s <= 1;
	end	
	
burst_rd4:
	begin
	if  (r_counter < 5'd11)	//sending the read address
		begin
		valid <= 0;
		addr_tx <= addr_buffer[13];
		addr_buffer <= (addr_buffer << 1);
		r_counter <= r_counter + 1;
		end

	else if (r_counter < 5'd14)
		begin
		r_counter <= r_counter + 5'd1;
		addr_tx <= addr_buffer[13];
		addr_buffer <= (addr_buffer << 1);
		burst_mode <= burst_mode_buffer[2];
		burst_mode_buffer <= (burst_mode_buffer << 1);
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
burst_rd5:
	begin
	if (r_counter < 5'd8)
		begin
		data_buffer <= (data_buffer << 1);
		data_buffer[0] <= data_rx;
		data_read <= data_buffer;
		r_counter <= r_counter + 1;
	end
		
	else begin
		data_read <= data_buffer;
		burst_counter <= burst_counter + 1;
		// bus_req	<= 0;
	end
		
		
end

burst_rd6:
	r_counter <= 5'd0;





endcase


endmodule
 
 
 
 
 
 