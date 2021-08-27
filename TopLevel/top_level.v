module top_level (input clk, reset, 
                  input m1_enable, m1_read_en,
                  input [7:0] m1_data_in,
                  input [13:0] m1_addr_in);

    // wires from master to arbiter
    wire m1_request, m1_address, m1_data, m1_valid, m1_address_valid;
    // wire m2_request, m2_address, m2_data, m2_valid, m2_address_valid;

    // wires from arbiter to master
    wire m1_ready, m1_available, m1_data_in;
    // wire m2_ready, m2_available, m2_data_in;

    // wires from slave to arbiter
    wire s1_ready, s1_data_out; 
    wire s2_ready, s2_data_out; 
    // wire s3_ready, s3_data_out;

    // wires from arbiter to slave
    wire s1_address, s1_data, s1_valid;
    wire s2_address, s2_data, s2_valid;
    // wire s3_address, s3_data, s3_valid;

    // registers for the clock divider
    reg [24:0] counter;
    reg tick;

    // arbiter
    arbiter arbiter(.clk(tick),
                    .reset(reset),
                    .m1_request(m1_request), .m1_address(m1_address), .m1_data(m1_data), .m1_valid(m1_valid), .m1_address_valid(m1_address_valid),
                    .s1_data_in(s1_data_out), .s2_data_in(s2_data_out),
                    .s1_ready(s1_ready), .s2_ready(s2_ready),
                    .m1_data_out(m1_data_in),
                    .m1_ready(m1_ready), .m1_available(m1_available),
                    .s1_address(s1_address), .s1_data(s1_data), .s1_valid(s1_valid),
                    .s2_address(s2_address), .s2_data(s2_data), .s2_valid(s2_valid));

    // master 1
    master master1(.clk(tick),
                   .enable(m1_enable),
                   .read_en(m1_read_en),
                   .data_in(m1_data_in),
                   .addr_in(m1_addr_in),
                   .data_rx(m1_data_in),
                   .bus_ready(m1_available),
                   .bus_req(m1_request),
                   .addr_tx(m1_address),
                   .data_tx(m1_data),
                   .valid(m1_valid),
                   .valid_s(m1_address_valid));

    // slave 1
    slave slave1(.validIn(s1_valid),
                 .wren(),
                 .Address(s1_address),
                 .DataIn(s1_data),
                 .clk(tick),
                 .validOut(s1_ready),
                 .DataOut(s1_data_out));

    // slave 2
    slave slave2(.validIn(s2_valid),
                 .wren(),
                 .Address(s2_address),
                 .DataIn(s2_data),
                 .clk(tick),
                 .validOut(s2_ready),
                 .DataOut(s2_data_out));

    // Generating a clock with 1s period
    always @(posedge clk ) begin
        if (stop) begin
                counter <= 25'd0;
                tick <= 0;
        end  
        else if (counter == 25'd25000000)   begin
                counter <= 25'd0;
                tick <= ~tick;
        end   
        else    begin
                counter <= counter + 25'd1;  
        end
    end

endmodule //top_level