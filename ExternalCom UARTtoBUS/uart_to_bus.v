module uart_to_bus (
    input clk, //clk50,       // bus clock and 50MHz clock
    input reset,            // reset signal
    input data_rx,          // UART rx

    input bus_ready,		// signal indicating the availability of the bus
    
    output reg ack_out = 1,         // external acknowledgement signal out
    
    output reg bus_req = 0,
    output reg addr_tx = 0,		// address for the output data 
    output reg data_tx = 0,		// output data
    output reg valid = 0,	    // signal that indicates validity of the data from master
    output reg valid_s = 0,		// valid signal for slave
    output reg write_en_slave = 0, 	// signal to select data read(=1)/write(=0) for slave
    output reg [7:0] data_read = 8'd0  //output the initial received value from U
    );
    
    reg [4:0] present = 5'd0;
    reg [4:0] next = 5'd0;
    reg [4:0] ack_present = 5'd0;
    reg [4:0] ack_next = 5'd0;
    reg [4:0] w_counter = 5'd0;
    reg [4:0] r_counter = 5'd0;

    reg [7:0] data_buffer = 8'd0;		// reg to keep input data
    reg [13:0] addr_buffer1 = 14'd0;	// reg to keep the sending input address
    reg [13:0] addr_buffer2 = 14'b01000000000000;    // reg to keep the pre-setup address 
    reg [9:0] wait_counter = 10'd0;

    reg [7:0] ack_pattern = 8'b11001100;    // initial pattern
    reg [7:0] ack_buffer = 8'b11001100;     // reg to keep sending ack
    reg [4:0] ack_counter = 5'd0;
    reg send_ack = 0;


    parameter
    idle = 5'd0,
    read1 = 5'd1,
    check_bus = 5'd2,
    write1 = 5'd3,
    write2 = 5'd4,
    write3 = 5'd5,
    writex = 5'd6,
    write4 = 5'd7,
    write5 = 5'd8,
    ack1 = 5'd9,
    ack2 = 5'd10;

///////////////////////////////////////////////////////////////
    always @ (*) begin
        if (reset)  next<= idle;
        else begin
            case (present)
                idle: begin
                    if (data_rx == 0) begin
                        next <= read1;
                    end 
                    else begin
                        next <= idle;
                    end 
                end

                read1:begin
                    if (r_counter < 5'd8)begin
                        next <= read1;
                    end
                    
                    else begin
                        next <= check_bus;
                    end
                end

                check_bus: begin
                    if (bus_ready) begin
                        next <= write1;
                    end  
                    else begin
                        next <= check_bus;
                    end            
                end

                write1: begin
                    next <= write2;
                end

                write2: begin
                    if  (w_counter < 5'd2) begin
                        next <= write2;	
                    end
                    else 
                        next <= write3;
                end

                write3: begin
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

                writex:begin
                    next <= write4;
                end

                write4: begin
                    if (bus_ready == 0) begin
                        next <= write3;
                    end
                        
                    else begin
                        next <= write5;
                    end
                            
                end

                write5: begin
                    if  (w_counter < 5'd14)
                        next <= write5;	
                    else 
                        next <= idle;
                end
            endcase
        end
    end
    
/////////////////////////////////////////////////////
    always @(posedge clk) begin
        present <= next;
        ack_present <= ack_next;
	end

////////////////////////////////////////////////////
    always @ (posedge clk) begin
        case (present)
            idle: begin
                data_buffer <= 8'd0;	
                addr_buffer1 <= addr_buffer2;
                w_counter <= 5'd0;
                r_counter <= 5'd0;
                wait_counter <= 10'd0;
                addr_tx <= 0;
                data_tx <= 0;
                send_ack <= 0;
                bus_req <= 0;
                valid <= 0;
                valid_s <= 0;
            end

            read1:begin
                if (r_counter < 5'd8)begin
                    data_buffer <= (data_buffer << 1);
                    data_buffer[0] <= data_rx;
                    r_counter <= r_counter + 1;
                end
                
                else begin
                    data_read <= data_buffer;
                    send_ack <= 1;
                    bus_req <= 1;
                    valid <= 1;
                    write_en_slave <= 1;
                end
            end

            check_bus: begin
                if (bus_ready) begin
                    valid <= 0;
                    send_ack <= 0;
                end  
                else begin
                    valid <= 1;
                    send_ack <= 0;
                end            
            end

            write1: begin
                valid <= 0;
                valid_s <= 1;
                w_counter <= 5'd0;
            end

            write2: begin
                w_counter <= w_counter + 5'd1;
                valid <= 0;
                addr_tx <= addr_buffer1[13];
                addr_buffer1 <= (addr_buffer1 << 1);
            end

            write3: begin
                if (bus_ready == 1 && wait_counter == 10'd0) begin
                    valid_s <= 1;			
                end

                else if (bus_ready == 1 && wait_counter != 10'd0) begin
                    valid <= 0;
                    valid_s <= 1;
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

            write4: begin
                if (bus_ready == 0) begin
                    wait_counter <= 10'd1;
                end
                    
                else begin
                    w_counter <= w_counter + 5'd1;
                    valid <= 0;
                    addr_tx <= addr_buffer1[13];
                    addr_buffer1 <= (addr_buffer1 << 1);
                end
                        
            end

            write5: begin
                if  (w_counter < 5'd6)begin
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
        endcase
    end

///////////////////////////////////////////////////////////////
    always @ (*) begin
        if (reset)  ack_next<= idle;
        else begin
            case (ack_present)
                idle: begin
                    if (send_ack == 1) begin
                        ack_next <= ack1;
                    end 
                    else begin
                        ack_next <= idle;
                    end 
                end

                ack1: begin
                    ack_next <= ack2;
                end

                ack2:begin
                    if (ack_counter < 5'd8)begin
                        ack_next <= ack2;
                    end
                    
                    else begin
                        ack_next <= idle;
                    end
                end 
            endcase
        end
    end

    always @ (posedge clk) begin
        case (ack_present)
            idle: begin
                ack_out <= 1;
                ack_counter <= 5'd0;
                ack_buffer <= ack_pattern;
            end

            ack1: begin
                ack_out <= 0;
            end

            ack2:begin
                ack_counter <= ack_counter + 5'd1;
                ack_out <= ack_buffer[7];
                ack_buffer <= (ack_buffer << 1);
            end 
        endcase
        
    end

endmodule