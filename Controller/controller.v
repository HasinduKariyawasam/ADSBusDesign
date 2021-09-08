module controller ( input clk, reset,start,
                    input m1_request,m2_request,
                    input [4:0] state_in,
                    output reg m1_enable, m2_enable,
                    output reg [2:0] m1_burst_mode, m2_burst_mode,
                    output reg m1_read_en, m2_read_en,
                    output reg [7:0] data_in1, data_in2,
                    output reg [13:0] addr_in1, addr_in2,
                    output [4:0] state_out);
    
    reg [4:0] state = 5'd0;
    reg [4:0] next_state = 5'd0; 
    reg [3:0] counter = 4'd0;
    reg [7:0] mycounter = 8'd0;

    assign state_out = state;

    parameter   idle = 5'd0,
                state1a = 5'd1,
                state1b = 5'd2,
                state2a = 5'd3,
                state2b = 5'd4,
                state3a = 5'd5,
                state3b = 5'd6,
                state3c = 5'd17,
                state4a = 5'd7,
                state4b = 5'd8,
                state5a = 5'd9,
                state5b = 5'd10,
                state6a = 5'd11,
                state6b = 5'd12,
                state7a = 5'd13,
                state7b = 5'd14,
                state8a = 5'd15,
                state8b = 5'd16,
                state9a = 5'd18,
                state9b = 5'd19,
                state9c = 5'd20;


    always @(*) begin
        case (state)
            idle: begin
                if (start == 1 && state_in == 5'd1)     
                    next_state <= state1a;
                else if (start == 1 && state_in ==5'd2)
                    next_state <= state2a;
                else if (start == 1 && state_in ==5'd3)
                    next_state <= state3a;
                else if (start == 1 && state_in ==5'd4)
                    next_state <= state4a;
                else if (start == 1 && state_in ==5'd5)
                    next_state <= state5a;
                else if (start == 1 && state_in ==5'd6)
                    next_state <= state6a;
                else if (start == 1 && state_in ==5'd7)
                    next_state <= state7a;
                else if (start == 1 && state_in ==5'd8)
                    next_state <= state8a;
                else if (start == 1 && state_in ==5'd9)
                    next_state <= state9a;
                else 
                    next_state <= idle;
                
            end

            //master 1 write to slave 1
            state1a:begin
                if (counter <4'd2)
                    next_state <= state1a;
                else
                    next_state <=state1b;
                
            end

            state1b: begin
                if (m1_request == 0 && m2_request == 0)
                    next_state <= idle;
                else
                    next_state <=state1b;
                
            end

            //master 1 read from slave 1
            state2a:begin
               if (counter <4'd2)
                    next_state <= state2a;
                else
                    next_state <=state2b;
            end

            state2b: begin
               if (m1_request == 0 && m2_request == 0)
                    next_state <= idle;
                else
                    next_state <=state2b;
            end

            //master 1 write to slave 2
            state3a:begin
                if (counter <4'd2)
                    next_state <= state3a;
                else
                    next_state <=state3c;
            end

            state3c:begin
                if (counter <4'd10)
                    next_state <= state3c;
                else
                    next_state <=state3b;
            end

            state3b: begin
                if (m1_request == 0 && m2_request == 0)
                    next_state <= idle;
                else
                    next_state <=state3b;
            end

            //master 1 read from slave 2    
            state4a:begin
                if (counter <4'd2)
                    next_state <= state4a;
                else
                    next_state <=state4b;
            end

            state4b: begin
                if (m1_request == 0 && m2_request == 0)
                    next_state <= idle;
                else
                    next_state <=state4b;
            end

            //master 2 write to slave 3
            state5a:begin
                if (counter <4'd2)
                    next_state <= state5a;
                else
                    next_state <=state5b;
            end

            state5b: begin
                if (m1_request == 0 && m2_request == 0)
                    next_state <= idle;
                else
                    next_state <=state5b;
            end

            //master 2 read from slave 3    
            state6a:begin
                if (counter <4'd2)
                    next_state <= state6a;
                else
                    next_state <=state6b;
            end

            state6b: begin
                if (m1_request == 0 && m2_request == 0)
                    next_state <= idle;
                else
                    next_state <=state6b;
            end

            //master 1,2 write at same time
            state7a:begin
                if (counter <4'd2)
                    next_state <= state7a;
                else
                    next_state <=state7b;
            end

            state7b: begin
                if (m1_request == 0 && m2_request == 0)
                    next_state <= idle;
                else
                    next_state <=state7b;
            end

            //master 1,2 read at same time   
            state8a:begin
                if (counter <4'd2)
                    next_state <= state8a;
                else
                    next_state <=state8b;
            end

            state8b: begin
                if (m1_request == 0 && m2_request == 0)
                    next_state <= idle;
                else
                    next_state <=state8b;
            end

            //split transaction write
            state9a:begin
                if (counter <4'd2)
                    next_state <= state9a;
                else
                    next_state <=state9c;
            end

            state9c:begin
                if (counter <4'd10)
                    next_state <= state9c;
                else
                    next_state <=state9b;
            end

            state9b: begin
                if (m1_request == 0 && m2_request == 0)
                    next_state <= idle;
                else
                    next_state <=state9b;
            end
        endcase
        
    end

    always @(posedge clk) begin
        state <= next_state;
    end

    always @(posedge clk) begin
        case (state)
            idle: begin
                counter <= 4'd0;mycounter <=0;
                m1_enable <= 0; m2_enable <= 0;
                m1_read_en <= 0; m2_read_en <= 0;
                m1_burst_mode <= 3'd0;m2_burst_mode<=3'd0;
                data_in1 <= 8'd0; data_in2 <= 8'd0;
                addr_in1 <= 14'd0; addr_in2 <= 14'd0;
                m1_burst_mode <= 3'd0; m2_burst_mode <= 3'd0;
            end

            //master 1 write to slave 2 address = 1365 data = 170
            state1a:begin
                counter <= counter + 4'd1;
                m1_enable <= 1; m2_enable <= 1;
                m1_burst_mode <= 3'd2;m2_burst_mode<=3'd2;
                m1_read_en <= 0; m2_read_en <= 0;
                data_in1 <= 8'b10101010; data_in2 <= 8'd132; 
                addr_in1 <= 14'b01010101010101; addr_in2 <= 14'b00010101010101;
            end

            state1b: begin
                m1_enable <= 0;m2_enable <= 0;
            end

            //master 1 read from slave 2 address = 1365
            state2a:begin
                counter <= counter + 4'd1;
                m1_enable <= 1; m2_enable <= 1;
                // m1_burst_mode <= 3'd2;m2_burst_mode<=3'd2;
                m1_read_en <= 1; m2_read_en <= 0;
                data_in1 <= 8'd10; data_in2 <= 8'd170; 
                addr_in1 <= 14'b01010101010101; addr_in2 <= 14'b00010101010101;
            end

            state2b: begin
                m1_enable <= 0;m2_enable <= 0;
                // m1_enable <= 0;
            end

            //master 1 read from slave 2 and master 2 read to slave 1
            state3a:begin
                counter <= counter + 4'd1;
                m1_enable <= 1; m2_enable <= 0;
                // m1_burst_mode <= 3'd2;m2_burst_mode<=3'd2;
                m1_read_en <= 1; m2_read_en <= 0;
                data_in1 <= 8'd0; data_in2 <= 8'd0;
                addr_in1 <= 14'b01010101010101; addr_in2 <= 14'd0;
            end

            state3c:begin
                counter <= counter + 4'd1;
                if(counter < 4'd8) begin
                    m1_enable <= 0; m2_enable <= 0;
                    m1_read_en <= 0; m2_read_en <= 0;
                    data_in1 <= 8'd0; data_in2 <= 8'd0;
                    addr_in1 <= 14'd0; addr_in2 <= 14'd0;  
                end
                else begin
                    m1_enable <= 0; m2_enable <= 1;
                    // m1_burst_mode <= 3'd2;m2_burst_mode<=3'd2;
                    m1_read_en <= 0; m2_read_en <= 1;
                    data_in1 <= 8'd0; data_in2 <= 8'd0;
                    addr_in1 <= 14'd0; addr_in2 <= 14'b00010101010101; 
                end
                
            end

            state3b: begin
                m1_enable <= 0; m2_enable <= 0;
                // m2_enable <= 0;
            end

            //master 1 and master 2 read from slave 2   
            state4a:begin
                counter <= counter + 4'd1;
                m1_enable <= 1; m2_enable <= 1;
                m1_burst_mode <= 3'd2;m2_burst_mode<=3'd0;
                m1_read_en <= 1; m2_read_en <= 0;
                data_in1 <= 8'd0; data_in2 <= 8'd170; 
                addr_in1 <= 14'b01010101010101; addr_in2 <= 14'b00010101010101;
            end

            state4b: begin
                mycounter <= mycounter + 8'd1;
                m1_enable <= 0;
                if((mycounter%40)==0)    m2_enable <= 1;
                else  m2_enable <= 0;
            end

            //master 1 and master 2 write to slave 2
            state5a:begin
                counter <= counter + 4'd1;
                m1_enable <= 1; m2_enable <= 1;
                // m1_burst_mode <= 3'd2;m2_burst_mode<=3'd2;
                m1_read_en <= 0; m2_read_en <= 0;
                data_in2 <= 8'd101; data_in1 <= 8'd170;
                addr_in2 <= 14'b01010101010101; addr_in1 <= 14'b01010101010110;
            end

            state5b: begin
                m1_enable <= 0; m2_enable <= 0;
                // m2_enable <= 0;
            end

            //master 2 read from slave 2 and master 1 read from slave 1
            state6a:begin
                counter <= counter + 4'd1;
                m1_enable <= 1; m2_enable <= 1;
                // m1_burst_mode <= 3'd2;m2_burst_mode<=3'd2;
                m1_read_en <= 1; m2_read_en <= 1;
                data_in2 <= 8'd0; data_in1 <= 8'd0;
                addr_in2 <= 14'b00010101010101; addr_in1 <= 14'b01010101010101;
            end

            state6b: begin
                m2_enable <= 0;m1_enable <= 0;
            end

            //master 1 write to slave 1 and master 2 read from slave 1
            state7a:begin
                counter <= counter + 4'd1;
                m1_enable <= 1; m2_enable <= 1;
                // m1_burst_mode <= 3'd2;m2_burst_mode<=3'd2;
                m1_read_en <= 0; m2_read_en <= 1;
                data_in1 <= 8'd102; data_in2 <= 8'd0;
                addr_in1 <= 14'b01010101010101; addr_in2 <= 14'b01010101010101;
            end

            state7b: begin
                m1_enable <= 0; m2_enable <= 0;
            end

            //master 1 read and master 2 write slave 1  
            state8a:begin
                counter <= counter + 4'd1;
                m1_enable <= 1; m2_enable <= 1;
                // m1_burst_mode <= 3'd2;m2_burst_mode<=3'd2;
                m1_read_en <= 1; m2_read_en <= 0;
                data_in1 <= 8'd0; data_in2 <= 8'd124;
                addr_in1 <= 14'b01010101010101; addr_in2 <= 14'd5097;
            end

            state8b: begin
                m1_enable <= 0; m2_enable <= 0;
            end

            //master 1 write to slave 2 and master 2 write to slave 1
            state9a:begin
                counter <= counter + 4'd1;
                m1_enable <= 1; m2_enable <= 0;
                // m1_burst_mode <= 3'd2;m2_burst_mode<=3'd2;
                m1_read_en <= 1; m2_read_en <= 0;
                data_in1 <= 8'd78; data_in2 <= 8'd0;
                addr_in1 <= 14'd5097; addr_in2 <= 14'd0;
            end

            state9c:begin
                counter <= counter + 4'd1;
                if(counter < 4'd8) begin
                    m1_enable <= 0; m2_enable <= 0;
                    m1_read_en <= 0; m2_read_en <= 0;
                    data_in1 <= 8'd0; data_in2 <= 8'd0;
                    addr_in1 <= 14'd0; addr_in2 <= 14'd0;  
                end
                else begin
                    m1_enable <= 0; m2_enable <= 1;
                    m1_read_en <= 0; m2_read_en <= 0;
                    // m1_burst_mode <= 3'd2;m2_burst_mode<=3'd2;
                    data_in1 <= 8'd0; data_in2 <= 8'd62;
                    addr_in1 <= 14'd0; addr_in2 <= 14'd1001; 
                end
                
            end

            state9b: begin
                m2_enable <= 0;
            end
        endcase

    end  


endmodule