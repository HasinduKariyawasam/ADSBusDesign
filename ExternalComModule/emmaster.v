module emmaster(

input clock,						// clock signal
input reset,
input enable,						// enable signal to get inputs from the user
input read_en,						// signal to select data read(=1)/write(=0)
input [7:0] data_in,				// data bits from switches
input [13:0] addr_in,			// address bits fron switches
input [2:0] burst_mode_in,

input [7:0] ExternalCounter,
input ExternalUpdated,

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
output reg [5:0] present = 6'd0,
output reg [5:0] next = 6'd0,
output reg [4:0] w_counter = 5'd0,
output reg [4:0] r_counter = 5'd0,
output reg [15:0]clk_counter = 16'd0	
);
 

reg [7:0] data_buffer = 8'd0;		// buffer to keep input data
reg [7:0] data_buffer_inc = 8'd0;
//////Changed addr_buffer to addr_buffer1 //reg [13:0] addr_buffer = 14'd0;		// buffer to keep input address
reg [2:0] burst_mode_buffer = 3'd0; 	// buffer to keep burst mode
reg [13:0] addr_buffer1 = 14'd0;	// buffer to keep input address
reg [13:0] addr_buffer2 = 14'd0;
reg [9:0] wait_counter = 10'd0;
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
idle      = 6'd0,
check_bus = 6'd1,
fetch     = 6'd2,
write1    = 6'd3,
write2    = 6'd4,
write3    = 6'd5,
writex    = 6'd6,
write4    = 6'd7,
write5    = 6'd8,
read1     = 6'd9,
read2     = 6'd10,
read3     = 6'd11,
readx     = 6'd12,
read4     = 6'd13,
read5     = 6'd14,
read6     = 6'd15,
burst_wr1 = 6'd16,
burst_wr2 = 6'd17,
burst_wr3 = 6'd18,
burst_wrx = 6'd19,
burst_wr4 = 6'd20,
burst_wr5 = 6'd21,
burst_wr6 = 6'd22,
burst_wr7 = 6'd23,
burst_rd1 = 6'd24,
burst_rd2 = 6'd25,
burst_rd3 = 6'd26,
burst_rdx = 6'd27,
burst_rd4 = 6'd28,
burst_rd5 = 6'd29,
burst_rd6 = 6'd30,
burst_rd7 = 6'd31,
check_busex = 6'd32,
fetchex 	= 6'd33;

///////////////////////////////////////////////////
//next state decoder
always @(*) begin
	if (reset) begin
		next <= idle;
	end
	else begin
		case(present)

		idle:
			begin
			if (enable == 1)
				next <= check_bus;
			else if(ExternalUpdated==1)
				next <= check_busex;
			else
				next <= idle;
			end

		check_bus: next <= fetch;
		check_busex: next <= fetchex;

		fetchex: begin 
			if(bus_ready) next <= write1;
			else 		  next <= fetchex;
			end

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
			else 
				next <= write3;
			end

		write3: 
			begin
			if (bus_ready == 1 && wait_counter == 10'd0) begin
				next <= write4;				
			end
			else if (bus_ready == 1 && wait_counter != 10'd0) begin
				next <= writex;
			end
			else begin
				next <= write3;
			end

			end

		writex:
			begin
			next <= write4;
			end


		write4:
			begin
			if (bus_ready == 0)
				next <= write3;
			else
				next <= write5;	
			end

		write5:
			begin
			if  (w_counter < 5'd14)
				next <= write5;	
			else 
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
			begin
			if (bus_ready == 1 && wait_counter == 10'd0) begin
				next <= read4;				
			end
			else if (bus_ready == 1 && wait_counter != 10'd0) begin
				next <= readx;
			end
			else begin
				next <= read3;
			end

			end

		readx:
			next <= read4;

		read4:
			begin
			if (bus_ready == 0)
				next <= read3;
			else
				next <= read5;	
			end

		read5:
			begin
			if  (r_counter < 5'd14)
				next <= read5;
			else if (slave_valid == 1)
				next <= read6;
			else
				next <= read5;
			end

		read6:
			begin
			if (r_counter < 5'd8)
				next <= read6;
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

		burst_wr3: begin
			if (bus_ready == 1 && wait_counter == 10'd0) begin
				next <= burst_wr4;				
			end
			else if (bus_ready == 1 && wait_counter != 10'd0) begin
				next <= burst_wrx;
			end
			else begin
				next <= burst_wr3;
			end

		end

		burst_wrx:begin
			next <= burst_wr4;
		end

		burst_wr4:
			begin
			if (bus_ready == 0)
				next <= burst_wr3;
			else
				next <= burst_wr5;	
			end

		burst_wr5: begin
			if  (w_counter < 5'd14)
				next <= burst_wr5;	
			else 
				next <= burst_wr6;
		end

		burst_wr6:begin
			if (burst_counter < burst_size) begin
				if (slave_ready == 1 ) 
					next <= burst_wr7;

				else
					next <= burst_wr6;
			end

			else 
				next <= idle;
		end

		burst_wr7: begin
			if (w_counter < 5'd8)
				next <= burst_wr7;

			else
				next <= burst_wr6; 
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
			begin
			if (bus_ready == 1 && wait_counter == 10'd0) begin
				next <= burst_rd4;				
			end
			else if (bus_ready == 1 && wait_counter != 10'd0) begin
				next <= burst_rdx;
			end
			else begin
				next <= burst_rd3;
			end

			end
		
		burst_rdx:
			next <= burst_rd4;

		burst_rd4:
			begin
			if (bus_ready == 0)
				next <= burst_rd3;
			else
				next <= burst_rd5;	
			end

		burst_rd5:
			begin
			if  (r_counter < 5'd14)
				next <= burst_rd5;
			else if (slave_valid == 1)
				next <= burst_rd6;
			else
				next <= burst_rd5;
			end

		burst_rd6:
			begin
			if (r_counter < 5'd8)
				next <= burst_rd6;
			else
				next <= burst_rd7;
			end

		burst_rd7: begin
			if (burst_counter < burst_size) begin
				if (slave_valid == 1)
					next <= burst_rd6;
				else	
					next <= burst_rd7;
			end

			else
				next <= idle;

		end

		endcase
	end
end



	

///////////////////////////////////////////////////////
always @(posedge clock)
	begin
	clk_counter <= clk_counter +1;
	present <= next;
	// write_en_slave <= ~read_en;
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
	addr_buffer1 <= 14'd0;
	// bus_req	<= 0;
	master_busy <= 0;
	w_counter <= 5'd0;
	r_counter <= 5'd0;
	burst_counter <= 10'd0;
	burst_size <= 10'd0;
	burst_mode <= 0;
	wait_counter <= 10'd0;
	addr_tx <= 0;
	data_tx <= 0;
	// valid <= 0;
	valid_s <= 0;
	if (enable==1) begin
		bus_req <= 1;
		valid <= 1;
	end	
	else if(ExternalUpdated==1) begin
		bus_req <= 1;
		valid   <= 1;
	end
	else begin
		bus_req <= 0;
		valid <= 0;
	end			
	
	end

check_bus:
	begin
	write_en_slave <= ~read_en;
	end

check_busex: write_en_slave <= 1;

fetchex    : begin
	bus_req <= 1;
	master_busy <= 1;
	data_buffer <= ExternalCounter;
	data_buffer_inc <= ExternalCounter;
	addr_buffer1 	<= 14'd1365;
	burst_mode_buffer <= 0;
	w_counter <= 5'd0;
	r_counter <= 5'd0;
	burst_size <= 10'd0;


end

//take inputs from the user
fetch:
	begin
		bus_req <= 1;
		master_busy <= 1;
		data_buffer <= data_in;
		data_buffer_inc <= data_in;
		addr_buffer1 <= addr_in;
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
	addr_buffer2 <= addr_buffer1;
	w_counter <= 5'd0;
	end


write2:
	begin
	//sending first 2 bits of the address
		w_counter <= w_counter + 5'd1;
		valid <= 0;
		addr_tx <= addr_buffer1[13];
		addr_buffer1 <= (addr_buffer1 << 1);
	end

write3:
	// 	begin
	// 	valid_s <= 1;
	// end	
	begin
	if (bus_ready == 1 && wait_counter == 10'd0) begin
		valid_s <= 1;
			
	end
	else if (bus_ready == 1 && wait_counter != 10'd0) begin
		valid <= 0;
		valid_s <= 1;
		// addr_buffer1 <= addr_buffer2;
		w_counter <= 5'd3;
		wait_counter <= 10'd0;
	end
	else begin
		valid <= 0;
		valid_s <= 0;
		w_counter <= 5'd0;
		wait_counter <= wait_counter + 10'd1;
	end

	end

write4:
	begin
	//sending first 6 bits of the address
	if (bus_ready == 0)
		begin
		wait_counter <= 10'd1;
		end
	else if  (w_counter < 5'd6)
		begin
		w_counter <= w_counter + 5'd1;
		valid <= 0;
		addr_tx <= addr_buffer1[13];
		addr_buffer1 <= (addr_buffer1 << 1);
		end
	
	//sending remaining bits of the address and data
	else if (w_counter < 5'd14)
		begin
		w_counter <= w_counter + 5'd1;
		addr_tx <= addr_buffer1[13];
		addr_buffer1 <= (addr_buffer1 << 1);
		data_tx <= data_buffer[7];
		data_buffer <= (data_buffer << 1);
		end
			
	else if (w_counter == 5'd14)
		begin
		valid_s <= 0;
		end
	end	

write5:
	begin
	//sending first 6 bits of the address
	if  (w_counter < 5'd6)
		begin
		w_counter <= w_counter + 5'd1;
		valid <= 0;
		addr_tx <= addr_buffer1[13];
		addr_buffer1 <= (addr_buffer1 << 1);
		end
	
	//sending remaining bits of the address and data
	else if (w_counter < 5'd14)
		begin
		w_counter <= w_counter + 5'd1;
		addr_tx <= addr_buffer1[13];
		addr_buffer1 <= (addr_buffer1 << 1);
		data_tx <= data_buffer[7];
		data_buffer <= (data_buffer << 1);
		end
			
	else if (w_counter == 5'd14)
		begin
		valid_s <= 0;
		bus_req <= 0;
		end
	end	
	

//read data 
// set data valid signal high
read1:
	begin
	valid_s <= 1;
	valid <= 0;
	addr_buffer2 <= addr_buffer1;
	w_counter <= 5'd0;
	end	
	
read2:
	begin
		valid <= 0;
		addr_tx <= addr_buffer1[13];
		addr_buffer1 <= (addr_buffer1 << 1);
		r_counter <= r_counter + 1;
	end

read3:
	begin
	if (bus_ready == 1 && wait_counter == 10'd0) begin
		valid_s <= 1;				
	end
	else if (bus_ready == 1 && wait_counter != 10'd0) begin
		valid <= 0;
		valid_s <= 1;
		// addr_buffer1 <= addr_buffer2;
		r_counter <= 5'd3;
		wait_counter <= 10'd0;
	end
	else begin
		valid <= 0;
		valid_s <= 0;
		r_counter <= 5'd0;
		wait_counter <= wait_counter + 10'd1;
	end

	end

read4:
	begin
	if (bus_ready == 0)
		wait_counter <= 10'd1;
	else if  (r_counter < 5'd14)	//sending the read address
		begin
		valid <= 0;
		addr_tx <= addr_buffer1[13];
		addr_buffer1 <= (addr_buffer1 << 1);
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

read5:
	begin
	if  (r_counter < 5'd14)	//sending the read address
		begin
		valid <= 0;
		addr_tx <= addr_buffer1[13];
		addr_buffer1 <= (addr_buffer1 << 1);
		r_counter <= r_counter + 1;
		end
	else if (slave_valid == 1) //wait until slave_valid signal
		begin
		valid_s <= 0;
		addr_tx <= 0;
		r_counter <=0;
		end
	else
		begin
		valid_s <= 0;
		addr_tx <= 0;
		end
	end

//getting inputs from the data_rx
read6:
	begin
	if (r_counter < 5'd8)
		begin
		data_buffer <= (data_buffer << 1);
		data_buffer[0] <= data_rx;
		// data_read <= data_buffer;
		r_counter <= r_counter + 1;
		end
		
	else
		data_read <= data_buffer;
		// bus_req	<= 0;
		
end

burst_wr1:begin
	valid <= 0;
	valid_s <= 1;
	addr_buffer2 <= addr_buffer1;
	burst_mode <= 1;
	w_counter <= 5'd0;
end

burst_wr2: begin
	w_counter <= w_counter + 5'd1;
	valid <= 0;
	addr_tx <= addr_buffer1[13];
	addr_buffer1 <= (addr_buffer1 << 1);

end

burst_wr3: begin
	if (bus_ready == 1 && wait_counter == 10'd0) begin
		valid_s <= 1;
			
	end
	else if (bus_ready == 1 && wait_counter != 10'd0) begin
		valid <= 0;
		valid_s <= 1;
		// addr_buffer1 <= addr_buffer2;
		w_counter <= 5'd3;
		wait_counter <= 10'd0;
	end
	else begin
		valid <= 0;
		valid_s <= 0;
		w_counter <= 5'd0;
		wait_counter <= wait_counter + 10'd1;
	end

end

burst_wr4:
	begin
	//sending first 6 bits of the address
	if (bus_ready == 0)
		begin
		wait_counter <= 10'd1;
		end
	else if  (w_counter < 5'd6)
		begin
		w_counter <= w_counter + 5'd1;
		valid <= 0;
		addr_tx <= addr_buffer1[13];
		addr_buffer1 <= (addr_buffer1 << 1);
		end
	
	//sending remaining bits of the address and data
	else if (w_counter < 5'd14)
		begin
		w_counter <= w_counter + 5'd1;
		addr_tx <= addr_buffer1[13];
		addr_buffer1 <= (addr_buffer1 << 1);
		data_tx <= data_buffer[7];
		data_buffer <= (data_buffer << 1);
		end
			
	else if (w_counter == 5'd14)
		begin
		valid_s <= 0;
		end
	end




burst_wr5: begin
	if  (w_counter < 5'd6)
		begin
		w_counter <= w_counter + 5'd1;
		valid <= 0;
		addr_tx <= addr_buffer1[13];
		addr_buffer1 <= (addr_buffer1 << 1);
	end
	

	else if (w_counter < 5'd11)
		begin
		w_counter <= w_counter + 5'd1;
		addr_tx <= addr_buffer1[13];
		addr_buffer1 <= (addr_buffer1 << 1);
		data_tx <= data_buffer[7];
		data_buffer <= (data_buffer << 1);
	end

	else if (w_counter < 5'd14)
		begin
		w_counter <= w_counter + 5'd1;
		addr_tx <= addr_buffer1[13];
		addr_buffer1 <= (addr_buffer1 << 1);
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

burst_wr6:begin
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

burst_wr7: begin
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
	addr_buffer2 <= addr_buffer1;
	valid <= 0;
	// next <= burst_rd2;
end

burst_rd2:
	begin
		valid <= 0;
		addr_tx <= addr_buffer1[13];
		addr_buffer1 <= (addr_buffer1 << 1);
		r_counter <= r_counter + 1;
	end

burst_rd3:
	begin
	if (bus_ready == 1 && wait_counter == 10'd0) begin
		valid_s <= 1;				
	end
	else if (bus_ready == 1 && wait_counter != 10'd0) begin
		valid <= 0;
		valid_s <= 1;
		// addr_buffer1 <= addr_buffer2;
		r_counter <= 5'd3;
		wait_counter <= 10'd0;
	end
	else begin
		valid <= 0;
		valid_s <= 0;
		r_counter <= 5'd0;
		wait_counter <= wait_counter + 10'd1;
	end

	end

burst_rd4:
	begin
	if (bus_ready == 0)
		wait_counter <= 10'd1;
	else if  (r_counter < 5'd14)	//sending the read address
		begin
		valid <= 0;
		addr_tx <= addr_buffer1[13];
		addr_buffer1 <= (addr_buffer1 << 1);
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
	
burst_rd5:
	begin
	if  (r_counter < 5'd11)	//sending the read address
		begin
		valid <= 0;
		addr_tx <= addr_buffer1[13];
		addr_buffer1 <= (addr_buffer1 << 1);
		r_counter <= r_counter + 1;
		end

	else if (r_counter < 5'd14)
		begin
		r_counter <= r_counter + 5'd1;
		addr_tx <= addr_buffer1[13];
		addr_buffer1 <= (addr_buffer1 << 1);
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
burst_rd6:
	begin
	if (r_counter < 5'd8)
		begin
		data_buffer <= (data_buffer << 1);
		data_buffer[0] <= data_rx;
		// data_read <= data_buffer;
		r_counter <= r_counter + 1;
	end
		
	else begin
		data_read <= data_buffer;
		burst_counter <= burst_counter + 1;
		// bus_req	<= 0;
	end
		
		
end

burst_rd7:
	r_counter <= 5'd0;





endcase


endmodule
 
 
 
 
 
//  burst_wr1:begin
// 	valid <= 0;
// 	valid_s <= 1;
// 	burst_mode <= 1;
// 	w_counter <= 5'd0;
// end

// burst_wr2: begin
// 	if  (w_counter < 5'd6)
// 		begin
// 		w_counter <= w_counter + 5'd1;
// 		valid <= 0;
// 		addr_tx <= addr_buffer1[13];
// 		addr_buffer1 <= (addr_buffer1 << 1);
// 	end
	

// 	else if (w_counter < 5'd11)
// 		begin
// 		w_counter <= w_counter + 5'd1;
// 		addr_tx <= addr_buffer1[13];
// 		addr_buffer1 <= (addr_buffer1 << 1);
// 		data_tx <= data_buffer[7];
// 		data_buffer <= (data_buffer << 1);
// 	end

// 	else if (w_counter < 5'd14)
// 		begin
// 		w_counter <= w_counter + 5'd1;
// 		addr_tx <= addr_buffer1[13];
// 		addr_buffer1 <= (addr_buffer1 << 1);
// 		data_tx <= data_buffer[7];
// 		data_buffer <= (data_buffer << 1);
// 		burst_mode <= burst_mode_buffer[2];
// 		burst_mode_buffer <= (burst_mode_buffer << 1);
// 	end	

// 	else if (w_counter == 5'd14)
// 		begin
// 		burst_counter <= burst_counter + 10'd1;
// 		valid_s <= 0;
// 		data_buffer_inc <= data_buffer_inc + 8'd1;
// 	end
// end

// burst_wr3: valid_s <= 1;

// burst_wr4: begin
// 	if  (w_counter < 5'd6)
// 		begin
// 		w_counter <= w_counter + 5'd1;
// 		valid <= 0;
// 		addr_tx <= addr_buffer1[13];
// 		addr_buffer1 <= (addr_buffer1 << 1);
// 	end
	

// 	else if (w_counter < 5'd11)
// 		begin
// 		w_counter <= w_counter + 5'd1;
// 		addr_tx <= addr_buffer1[13];
// 		addr_buffer1 <= (addr_buffer1 << 1);
// 		data_tx <= data_buffer[7];
// 		data_buffer <= (data_buffer << 1);
// 	end

// 	else if (w_counter < 5'd14)
// 		begin
// 		w_counter <= w_counter + 5'd1;
// 		addr_tx <= addr_buffer1[13];
// 		addr_buffer1 <= (addr_buffer1 << 1);
// 		data_tx <= data_buffer[7];
// 		data_buffer <= (data_buffer << 1);
// 		burst_mode <= burst_mode_buffer[2];
// 		burst_mode_buffer <= (burst_mode_buffer << 1);
// 	end	

// 	else if (w_counter == 5'd14)
// 		begin
// 		burst_counter <= burst_counter + 10'd1;
// 		valid_s <= 0;
// 		data_buffer_inc <= data_buffer_inc + 8'd1;
// 	end
// end

// burst_wr5:begin
// 	if (burst_counter < burst_size) begin
// 		if (slave_ready == 1 ) begin
// 			valid_s <= 1;
// 			burst_mode <= 1;
// 			data_buffer <= data_buffer_inc;
// 			w_counter <= 5'd0;
// 		end

// 		else
// 			valid_s <= 0;
// 	end

// 	else
// 		valid_s <= 0;
	
// end

// burst_wr6: begin
// 	if (w_counter < 5'd8) begin
// 		w_counter <= w_counter + 5'd1;
// 		data_tx <= data_buffer[7];
// 		data_buffer <= (data_buffer << 1);
// 	end

// 	else begin
// 		burst_counter <= burst_counter + 1;
// 		data_buffer_inc <= data_buffer_inc + 8'd1;
// 		valid_s <= 0;
// 	end

// end