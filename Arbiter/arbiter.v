module arbiter(input clk, reset,
               input m1_request, m1_address, m1_data, m1_valid, m1_address_valid, 
                     m1_write_en, m1_burst,
                     m2_request, m2_address, m2_data, m2_valid, m2_address_valid, 
                     m2_write_en, m2_burst,
                     s1_data_in, s2_data_in, s3_data_in,
                     s1_ready, s2_ready, s3_ready,
                     s1_valid_out, s2_valid_out, s3_valid_out,
                     s1_hold, s2_hold, s3_hold,
               output m1_data_out, m2_data_out,
                      m1_ready, m2_ready, m1_available, m2_available,
                      m1_valid_in, m2_valid_in,
                      s1_address, s1_data, s1_valid, s1_write_en, s1_burst, bus_ready_s1,
                      s2_address, s2_data, s2_valid, s2_write_en, s2_burst, bus_ready_s2,
                      s3_address, s3_data, s3_valid, s3_write_en, s3_burst, bus_ready_s3,
               output reg [2:0] state,
               output reg m1_connect1, m1_connect2, m1_connect3,
               output reg m2_connect1, m2_connect2, m2_connect3);

    reg [1:0] m1_address_buf = 2'd0;
    reg [1:0] m2_address_buf = 2'd0;
    reg [1:0] connected_master = 2'd0;
    reg m1_hold = 0; 
    reg m2_hold = 0;
    wire [1:0] connected_slave;
    wire [3:0] connect_state;
    wire compare;
    wire slave_ready1, slave_ready2;
    wire slave_hold;

    /*
    Following registers were set as output for testing purposes. 
    */
    // reg [2:0] state;
    // reg m1_connect1, m1_connect2, m1_connect3;
    // reg m2_connect1, m2_connect2, m2_connect3;

    // parameters indicating the states of the arbiter

    parameter [2:0] idle = 3'd0;            // Bus is idle
    parameter [2:0] wait_address = 3'd1;    // Not used
    parameter [2:0] msb1 = 3'd2;            // Reading the first address bit
    parameter [2:0] msb2 = 3'd3;            // Reading the second address bit
    parameter [2:0] connect = 3'd4;         // Connecting the master to slave 
    parameter [2:0] busy_m1 = 3'd5;         // Master 1 is using the bus
    parameter [2:0] busy_m2 = 3'd6;         // Master 2 is using the bus

    // State machine

    always @(posedge clk) begin
        if (reset) begin
            connected_master <= 2'd0;
            state <= idle;
            m1_hold <= 0;
            m2_hold <= 0; 
        end  
        else
            case (state)
                idle: begin
                    m1_hold <= 0;
                    m2_hold <= 0;
                    if (m1_request && connected_master == 2'd0 && m1_address_valid) begin
                        connected_master <= 2'd1;
                        state <= wait_address;
                    end
                    else if (~m1_request && m2_request && connected_master == 2'd0 && m2_address_valid) begin
                        connected_master <= 2'd2;
                        state <= wait_address;
                    end
                    else begin
                        connected_master <= 2'd0;
                        state <= idle;
                    end  
                end 

                wait_address: begin
                    if ((m1_valid == 1'b1) || (m2_valid == 1'b1)) begin
                        state <= msb1;
                    end
                    else begin
                        state <= wait_address;
                    end
                end

                msb1: begin
                    if (connected_master == 2'd1 && m1_valid == 1'b1) begin
                        m1_address_buf <= {m1_address_buf[0], m1_address};
                        state <= msb2;
                    end 
                    else if (connected_master == 2'd2 && m2_valid == 1'b1) begin
                        m2_address_buf <= {m2_address_buf[0], m2_address};
                        state <= msb2;
                    end
                    else    state <= msb1;
                end

                msb2: begin
                    if (connected_master == 2'd1) begin
                        m1_address_buf <= {m1_address_buf[0], m1_address};
                        state <= connect;
                    end
                    else if (connected_master == 2'd2) begin
                        m2_address_buf <= {m2_address_buf[0], m2_address};
                        state <= connect; 
                    end
                    else    state <= idle;
                end
                
                connect: begin
                    if ((m1_connect1 || m1_connect2 || m1_connect3)) begin
                        state <= busy_m1;
                        if(connected_master == 2'd2) begin
                                connected_master <= 2'd1;
                                m2_hold          <= 1;
                        end
                        else    connected_master <= 2'd1; 
                    end
                    else if ((m2_connect1 || m2_connect2 || m2_connect3)) begin
                        state <= busy_m2;
                        if(connected_master == 2'd1) begin
                                connected_master <= 2'd2;
                                m1_hold          <= 1;
                        end
                        else    connected_master <= 2'd2;
                    end 
                    else        state            <= idle;
                end

                busy_m1: begin
                    if (~m1_request && m2_hold) begin
                        connected_master <= 2'd2;
                        m1_hold          <= 0;   
                        m2_hold        <= 0; //To support burst splits
                        state            <= connect;

                    end
                    else if (~m1_request) begin
                        m1_hold <= 0;   
                        state <= idle;
                    end
                    else if ((slave_hold) && (m2_request)) begin
                        if(m1_hold && m1_address_buf==m2_address_buf)     state <= busy_m1;
                        else if (m2_hold) begin
                            state <= connect;
                            connected_master <= 2'd2;
                            m1_hold <= 1;
                        end
                        else begin
                            state <= wait_address;   
                            connected_master <= 2'd2;
                            m1_hold <= 1;
                        end
                        
                    end  
                    else    state <= busy_m1;
                end

                busy_m2: begin
            
                    if (~m2_request && m1_hold) begin
                        connected_master <= 2'd1;
                        state <= connect;
                        m2_hold <= 0;
                        m1_hold        <= 0; //To support burst splits
                    end
                    else if (~m2_request) begin
                        state <= idle;
                        m2_hold <= 0;
                    end 
                    else if ((slave_hold) && (m1_request)) begin
                        if(m2_hold && m1_address_buf==m2_address_buf) state <= busy_m2;
                        else if (m1_hold) begin
                            state <= connect;
                            connected_master <= 2'd1;
                            m2_hold <= 1;
                        end
                        else begin
                            state <= wait_address;
                            connected_master <= 2'd1;
                            m2_hold <= 1;   
                        end
                        
                    end       
                    else    state <= busy_m2;
                end

                default:    state <= idle;
            endcase
    end

    // Master to slave connection logic
    always @(*) begin
        if (reset || (state == idle)) begin
            m1_connect1 = 1'b0;
            m1_connect2 = 1'b0;
            m1_connect3 = 1'b0;
            m2_connect1 = 1'b0;
            m2_connect2 = 1'b0;
            m2_connect3 = 1'b0;
        end
        else if (compare)  begin
            case (connect_state)
                4'd3:   begin
                    m1_connect1 = 1'b1;
                    m1_connect2 = 1'b0;
                    m1_connect3 = 1'b0;
                    m2_connect1 = 1'b0;
                    m2_connect2 = 1'b0;
                    m2_connect3 = 1'b0;
                end

                4'd4:   begin
                    m1_connect1 = 1'b0;
                    m1_connect2 = 1'b1;
                    m1_connect3 = 1'b0;
                    m2_connect1 = 1'b0;
                    m2_connect2 = 1'b0;
                    m2_connect3 = 1'b0;
                end

                4'd5:   begin
                    m1_connect1 = 1'b0;
                    m1_connect2 = 1'b0;
                    m1_connect3 = 1'b1;
                    m2_connect1 = 1'b0;
                    m2_connect2 = 1'b0;
                    m2_connect3 = 1'b0;
                end

                4'd6:   begin
                    m1_connect1 = 1'b0;
                    m1_connect2 = 1'b0;
                    m1_connect3 = 1'b0;
                    m2_connect1 = 1'b1;
                    m2_connect2 = 1'b0;
                    m2_connect3 = 1'b0;
                end

                4'd7:   begin
                    m1_connect1 = 1'b0;
                    m1_connect2 = 1'b0;
                    m1_connect3 = 1'b0;
                    m2_connect1 = 1'b0;
                    m2_connect2 = 1'b1;
                    m2_connect3 = 1'b0;
                end

                4'd8:   begin
                    m1_connect1 = 1'b0;
                    m1_connect2 = 1'b0;
                    m1_connect3 = 1'b0;
                    m2_connect1 = 1'b0;
                    m2_connect2 = 1'b0;
                    m2_connect3 = 1'b1;
                end

                default:    begin
                    m1_connect1 = 1'b0;
                    m1_connect2 = 1'b0;
                    m1_connect3 = 1'b0;
                    m2_connect1 = 1'b0;
                    m2_connect2 = 1'b0;
                    m2_connect3 = 1'b0;
                end
            endcase 
        end
        else    begin
            m1_connect1 = m1_connect1;
            m1_connect2 = m1_connect2;
            m1_connect3 = m1_connect3;
            m2_connect1 = m2_connect1;
            m2_connect2 = m2_connect2;
            m2_connect3 = m2_connect3;
        end
    end

    // Assignments

    assign compare = (state == connect);

    assign connect_state = (connected_master == 2'd1 && slave_ready1 == 1) ? 4'd3 + m1_address_buf : 
                           (connected_master == 2'd1 && slave_ready1 == 0 && m2_hold == 1) ? 4'd6 + m2_address_buf :
                           (connected_master == 2'd1 && slave_ready1 == 0 && m2_hold == 0 ) ? 4'd3 + m1_address_buf :
                           (connected_master == 2'd2 && slave_ready2 == 1) ? 4'd6 + m2_address_buf : 
                           (connected_master == 2'd2 && slave_ready2 == 0 && m1_hold == 1) ? 4'd3 + m1_address_buf : 
                           (connected_master == 2'd2 && slave_ready2 == 0 && m1_hold == 0 ) ? 4'd6 + m2_address_buf : 4'd0;

    assign slave_ready1 = (m1_address_buf == 2'd0) ? s1_ready : (m1_address_buf == 2'd1) ? s2_ready : (m1_address_buf == 2'd2) ? s3_ready : 0;
    assign slave_ready2 = (m2_address_buf == 2'd0) ? s1_ready : (m2_address_buf == 2'd1) ? s2_ready : (m2_address_buf == 2'd2) ? s3_ready : 0;
    assign connected_slave = (m1_connect1 || m2_connect1) ? 2'd1 : (m1_connect2 || m2_connect2) ? 2'd2 : (m1_connect3 || m2_connect3) ? 2'd3 : 2'd0;
    assign slave_hold = (connected_slave == 2'd1) ? s1_hold : (connected_slave == 2'd2) ? s2_hold : (connected_slave == 2'd3) ? s3_hold : 0;

    assign m1_available = (connected_master != 2'd2);
    assign m2_available = (connected_master != 2'd1);
    // assign m1_available = ~(~m1_request && m2_request && connected_master == 2'd0);
    // assign m2_available = ~(m1_request && connected_master == 2'd0);

    assign s1_address = (m1_connect1) ? m1_address : (m2_connect1) ? m2_address : 1'b0;
    assign s1_data = (m1_connect1) ? m1_data : (m2_connect1) ? m2_data : 1'b0;
    assign s1_valid = (m1_connect1 && (state != msb1 && state != msb2)) ? m1_valid : (m2_connect1 && (state != msb1 && state != msb2)) ? m2_valid : 1'b0;
    assign s1_write_en = (m1_connect1) ? m1_write_en : (m2_connect1) ? m2_write_en : 1'b0;
    assign bus_ready_s1 = ~(m1_connect2 || m1_connect3 || m2_connect2 || m2_connect3);
    assign s1_burst = (m1_connect1) ? m1_burst : (m2_connect1) ? m2_burst : 1'b0;
    
    assign s2_address = (m1_connect2) ? m1_address : (m2_connect2) ? m2_address : 1'b0;
    assign s2_data = (m1_connect2) ? m1_data : (m2_connect2) ? m2_data : 1'b0;
    assign s2_valid = (m1_connect2 && (state != msb1 && state != msb2)) ? m1_valid : (m2_connect2 && (state != msb1 && state != msb2)) ? m2_valid : 1'b0;
    assign s2_write_en = (m1_connect2) ? m1_write_en : (m2_connect2) ? m2_write_en : 1'b0;
    assign bus_ready_s2 = ~(m1_connect1 || m1_connect3 || m2_connect1 || m2_connect3);
    assign s2_burst = (m1_connect2) ? m1_burst : (m2_connect2) ? m2_burst : 1'b0;

    assign s3_address = (m1_connect3) ? m1_address : (m2_connect3) ? m2_address : 1'b0;
    assign s3_data = (m1_connect3) ? m1_data : (m2_connect3) ? m2_data : 1'b0;
    assign s3_valid = (m1_connect3 && (state != msb1 && state != msb2)) ? m1_valid : (m2_connect3 && (state != msb1 && state != msb2)) ? m2_valid : 1'b0;
    assign s3_write_en = (m1_connect3) ? m1_write_en : (m2_connect3) ? m2_write_en : 1'b0;
    assign bus_ready_s3 = ~(m1_connect1 || m1_connect2 || m2_connect1 || m2_connect2);
    assign s3_burst = (m1_connect3) ? m1_burst : (m2_connect3) ? m2_burst : 1'b0;

    assign m1_ready = (m1_connect1) ? s1_ready : (m1_connect2) ? s2_ready : (m1_connect3) ? s3_ready: 1'b0;
    assign m2_ready = (m2_connect1) ? s1_ready : (m2_connect2) ? s2_ready : (m2_connect3) ? s3_ready: 1'b0;

    assign m1_data_out = (m1_connect1) ? s1_data_in : (m1_connect2) ? s2_data_in : (m1_connect3) ? s3_data_in: 1'b0;
    assign m2_data_out = (m2_connect1) ? s1_data_in : (m2_connect2) ? s2_data_in : (m2_connect3) ? s3_data_in: 1'b0;

    assign m1_valid_in = (m1_connect1) ? s1_valid_out : (m1_connect2) ? s2_valid_out : (m1_connect3) ? s3_valid_out: 1'b0;
    assign m2_valid_in = (m2_connect1) ? s1_valid_out : (m2_connect2) ? s2_valid_out : (m2_connect3) ? s3_valid_out: 1'b0;

endmodule //arbiter