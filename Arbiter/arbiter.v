module arbiter(input clk, reset,
               input m1_address, m1_data, m1_valid, m1_address_valid, 
                     s1_ready, s2_ready, s3_ready,
               output m1_ready,
                      s1_address, s1_data, s1_valid,
                      s2_address, s2_data, s2_valid,
                      s3_address, s3_data, s3_valid);

    reg [1:0] address_buf;
    reg [2:0] state;
    reg connect1, connect2, connect3;
    wire compare;

    parameter [2:0] idle = 3'd0;
    parameter [2:0] msb1 = 3'd1;
    parameter [2:0] msb2 = 3'd2;
    parameter [2:0] connect = 3'd3;
    parameter [2:0] busy = 3'd4;

    always @(posedge clk) begin
        if (reset)  state <= idle;
        else
            case (state)
                idle: begin
                    if (m1_address_valid)   state <= msb1;
                    else            state <= idle;
                end 

                msb1: begin
                    address_buf <= {address_buf[0], m1_address};
                    state <= msb2;
                end

                msb2: begin
                    address_buf <= {address_buf[0], m1_address};
                    state <= connect;
                end
                
                connect: begin
                    if (connect1 || connect2 || connect3)
                        state <= busy;
                    else
                        state <= idle;
                end

                busy: begin
                    if (m1_address_valid)
                        state <= msb1;
                    else
                        state <= busy;
                end

                default:    state <= idle;
            endcase
    end

    always @(*) begin
        if (reset) begin
            connect1 = 0;
            connect2 = 0;
            connect3 = 0;
        end
        else if (compare)
            if (address_buf == 2'b00) begin
                connect1 = 1;
                connect2 = 0;
                connect3 = 0;
            end
            else if (address_buf == 2'b01) begin
                connect1 = 0;
                connect2 = 1;
                connect3 = 0;
            end
            else if (address_buf == 2'b10) begin
                connect1 = 0;
                connect2 = 0;
                connect3 = 1;
            end
            else begin
                connect1 = 0;
                connect2 = 0;
                connect3 = 0;
            end
        else begin
            connect1 = connect1;
            connect2 = connect2;
            connect3 = connect3;
        end
    end

    assign compare = (state == connect);

    assign s1_address = (connect1) ? m1_address : 0;
    assign s1_data = (connect1) ? m1_data : 0;
    assign s1_valid = (connect1 && (state != msb1 && state != msb2)) ? m1_valid : 0;

    assign s2_address = (connect2) ? m1_address : 0;
    assign s2_data = (connect2) ? m1_data : 0;
    assign s2_valid = (connect2 && (state != msb1 && state != msb2)) ? m1_valid : 0;

    assign s3_address = (connect3) ? m1_address : 0;
    assign s3_data = (connect3) ? m1_data : 0;
    assign s3_valid = (connect3 && (state != msb1 && state != msb2)) ? m1_valid : 0;

    assign m1_ready = (connect1) ? s1_ready : (connect2) ? s2_ready : (connect3) ? s3_ready: 0;

endmodule //arbiter