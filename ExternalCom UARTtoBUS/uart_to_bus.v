module uart_to_bus (
    input clk, tick,       // bus clock and 50MHz clock
    input reset,            // reset signal
    input data_rx,          // UART rx

    input bus_ready,		// signal indicating the availability of the bus
    
    output reg ack_out = 1,         // external acknowledgement signal out
    
    output reg bus_req = 0,
    output reg addr_tx = 0,		// address for the output data 
    output reg data_tx = 0,		// output data
    output reg valid = 0,	    // signal that indicates validity of the data from master
    output reg valid_s = 0,		// valid signal for slave
    output reg write_en_slave = 1, 	// signal to select data read(=1)/write(=0) for slave
    output reg burst_mode = 0,
    output reg [4:0] present = 5'd0,
    output reg [4:0] rx_present = 5'd0,
    output reg [7:0] data_read = 8'd0  //output the initial received value from U
    );
    
    // reg [4:0] present = 5'd0;
    reg [4:0] next = 5'd0;
    
    reg [4:0] rx_next = 5'd0;
    reg [4:0] ack_present = 5'd0;
    reg [4:0] ack_next = 5'd0;
    reg [4:0] w_counter = 5'd0;
    reg [4:0] r_counter = 5'd0;
    reg rx_success = 0;
    reg bus_tx_done = 0;

    reg [7:0] data_buffer1 = 8'd0;		// reg to keep input data
     reg [7:0] data_buffer2 = 8'd0;		// reg to send received data
    reg [13:0] addr_buffer1 = 14'd0;	// reg to keep the sending input address
    reg [13:0] addr_buffer2 = 14'b01000000000000;    // reg to keep the pre-setup address 
    reg [9:0] wait_counter = 10'd0;

    reg [7:0] ack_pattern = 8'b11001100;    // initial pattern
    reg [7:0] ack_buffer = 8'b11001100;     // reg to keep sending ack
    reg [4:0] ack_counter = 5'd0;
    reg send_ack = 0;


    parameter
    idle        = 5'd0,
    read1       = 5'd1,
    bus_tx      = 5'd2,
    check_bus1  = 5'd3,
    check_bus2  = 5'd4,
    write1      = 5'd5,
    write2      = 5'd6,
    write3      = 5'd7,
    writex      = 5'd8,
    write4      = 5'd9,
    write5      = 5'd10,
    ack1        = 5'd11,
    ack2        = 5'd12;

    always @(posedge clk) begin
        present <= next;
	end

    always @(posedge tick) begin
        rx_present <= rx_next;
        ack_present <= ack_next;
	end

//setting states for external data receiving
    always @ (*) begin
        if (reset)  rx_next<= idle;
        else begin
            case (rx_present)
                idle: begin
                    if (data_rx == 0) begin
                        rx_next <= read1;
                    end 
                    else begin
                        rx_next <= idle;
                    end 
                end

                read1:begin
                    if (r_counter < 5'd9)       rx_next <= read1;
                    else if (rx_success == 1)   rx_next <= bus_tx;
                    else                        rx_next <= idle;
                end

                bus_tx: begin
                    if (bus_tx_done == 1 ) begin
                        rx_next <= idle;
                    end
                    else begin
                        rx_next <= bus_tx;
                    end
                end
            endcase
        end
    end

//states for external data receiving
    always @ (posedge tick) begin
        case (rx_present)
            idle: begin
                data_buffer1 <= 8'd0;	
                r_counter <= 5'd0;
                rx_success <= 0;
                send_ack <= 0;

            end

            read1:begin
                if (r_counter < 5'd8)begin
                    data_buffer1 <= (data_buffer1 << 1);
                    data_buffer1[0] <= data_rx;
                    r_counter <= r_counter + 1;
                end
                
                else if (r_counter == 5'd8) begin
                    if (data_rx == 1) begin
                        rx_success <= 1;
                        r_counter <= r_counter + 1;
                    end       
                    else begin
                        rx_success <= 0;
                        r_counter <= r_counter + 1;
                    end                    
                end

                else if (rx_success == 1) begin
                    data_read <= data_buffer1;
                    
                    send_ack <= 1;
                    r_counter <=0;
                end

                else    data_read <= 8'd0;

            end

            bus_tx: begin
                if (r_counter <5'd2) begin
                    r_counter <= r_counter + 1;
                end
                else begin
                    send_ack <= 0;
                end
            end

        endcase
    end

//setting states for internal data tx to bus
    always @ (*) begin
        if (reset)  next<= idle;
        else begin
            case (present)

                idle: begin
                    if (send_ack == 1) begin
                        next <= check_bus1;
                    end 
                    else begin
                        next <= idle;
                    end 
                end

                check_bus1: begin
                    next <= check_bus2;
                end

                check_bus2: begin
                    if (bus_ready) begin
                        next <= write1;
                    end  
                    else begin
                         next <= check_bus2;
                    end
                end

                write1: begin
                    next <= write2;
                end

                write2:begin
                    if  (w_counter < 5'd2)
                        next <= write2;	
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


                write4:begin
                    if (bus_ready == 0)
                        next <= write3;
                    else
                        next <= write5;	
                end

                write5:begin
                    if  (w_counter < 5'd14)
                        next <= write5;	
                    else 
                        next <= idle;
                end
            endcase
        end
    end





//states for internal data tx
    always @(posedge clk) begin
        case(present)

            idle: begin 
                addr_buffer1 <= addr_buffer2;
                w_counter <= 5'd0;
                wait_counter <= 10'd0;
                addr_tx <= 0;
                data_tx <= 0;
                valid_s <= 0;
                
                if (send_ack == 1) begin
                    bus_req <= 1;
                    valid <= 1;
                end	
                else begin
                    bus_req <= 0;
                    valid <= 0;
                end

                if (rx_present == bus_tx) begin
                    bus_tx_done <= 1;
                end
                else begin
                    bus_tx_done <= 0;
                end	
            end


            check_bus2: begin
                if (bus_ready) begin
                    valid <= 0;
                    data_buffer2 <= data_buffer1;
                end  
                else begin
                    valid <= 1;
                end            
            end
            
            write1:begin
                valid <= 0;
                valid_s <= 1;
                w_counter <= 5'd0;
            end

            write2:begin
            //sending first 2 bits of the address
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

            write4:begin
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
                    data_tx <= data_buffer2[7];
                    data_buffer2 <= (data_buffer2 << 1);
                    end
                        
                else if (w_counter == 5'd14)
                    begin
                    valid_s <= 0;
                    end
            end	

            write5:begin
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
                    data_tx <= data_buffer2[7];
                    data_buffer2 <= (data_buffer2 << 1);
                    end
                        
                else if (w_counter == 5'd14)
                    begin
                    valid_s <= 0;
                    bus_req <= 0;
                    bus_tx_done <= 1;
                    end
            end
        endcase
    end


//setting states for the ack
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

// states for the ack
    always @ (posedge tick) begin
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
                if (ack_counter < 5'd8) begin
                    ack_counter <= ack_counter + 5'd1;
                    ack_out <= ack_buffer[7];
                    ack_buffer <= (ack_buffer << 1);
                end
                else ack_out <= 1;
                
            end 
        endcase
        
    end

endmodule