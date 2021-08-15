module address_reader (input clk, reset, en, address_in,
                       output reg [13:0] address,
                       output reg read_end);

    reg unsigned [3:0] counter;

    parameter idle = 1'b0;
    parameter read = 1'b1;

    reg state, nextstate;

    always @(posedge clk ) begin
        if (reset || state == idle)      counter <= 4'd0;
        else if (en)    counter <= counter + 4'd1;
    end

    always @(posedge clk) begin
        if (reset)      state <= idle;
        else   
            case (state)
                idle: begin
                    read_end <= 0;
                    if (~en)  state <= idle;
                    else begin
                        state <= read;
                        address <= {address_in,address[13:1]};
                    end       
                end
                read: begin
                    if (counter == 4'd14)  begin
                        read_end <= 1;
                        state <= idle;
                    end
                    else begin
                        address <= {address_in,address[13:1]};
                        state <= read;
                    end          

                    // if (~read_end) state <= read;
                end
            endcase
    end

endmodule //address_reader