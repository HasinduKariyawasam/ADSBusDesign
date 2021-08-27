module top_level (input clk, reset, 
                  input m1_enable, m1_read_en,
                  input m2_enable, m2_read_en,
                  input [7:0] data_in1, data_in2,
                  input [13:0] addr_in1, addr_in2);

    // wires from master to arbiter
    wire m1_request, m1_address, m1_data, m1_valid, m1_address_valid, m1_write_en;
    wire m2_request, m2_address, m2_data, m2_valid, m2_address_valid, m2_write_en;

    // wires from arbiter to master
    wire m1_ready, m1_available, m1_data_in, m1_valid_in;
    wire m2_ready, m2_available, m2_data_in, m2_valid_in;

    // wires from slave to arbiter
    wire s1_ready, s1_data_out, s1_valid_out; 
    wire s2_ready, s2_data_out, s2_valid_out; 
    wire s3_ready, s3_data_out, s3_valid_out;

    // wires from arbiter to slave
    wire s1_address, s1_data, s1_valid, s1_write_en;
    wire s2_address, s2_data, s2_valid, s2_write_en;
    wire s3_address, s3_data, s3_valid, s3_write_en;

    // registers for the clock divider
    reg [24:0] counter;
    reg tick;

    // arbiter
    arbiter arbiter(.clk(clk),
                    .reset(reset),
                    .m1_request(m1_request), .m1_address(m1_address), .m1_data(m1_data), 
                    .m1_valid(m1_valid), .m1_address_valid(m1_address_valid), .m1_write_en(m1_write_en),
                    .m2_request(m2_request), .m2_address(m2_address), .m2_data(m2_data), 
                    .m2_valid(m2_valid), .m2_address_valid(m2_address_valid), .m2_write_en(m2_write_en),
                    .s1_data_in(s1_data_out), .s2_data_in(s2_data_out), .s3_data_in(s3_data_out),
                    .s1_ready(s1_ready), .s2_ready(s2_ready), .s3_ready(s3_ready),
                    .s1_valid_out(s1_valid_out), .s2_valid_out(s2_valid_out), .s3_valid_out(s3_valid_out),
                    .m1_data_out(m1_data_in), .m2_data_out(m2_data_in),
                    .m1_ready(m1_ready), .m1_available(m1_available),
                    .m2_ready(m2_ready), .m2_available(m2_available),
                    .m1_valid_in(m1_valid_in), .m2_valid_in(m2_valid_in),
                    .s1_address(s1_address), .s1_data(s1_data), 
                    .s1_valid(s1_valid), .s1_write_en(s1_write_en),
                    .s2_address(s2_address), .s2_data(s2_data), 
                    .s2_valid(s2_valid), .s2_write_en(s2_write_en),
                    .s3_address(s3_address), .s3_data(s3_data), 
                    .s3_valid(s3_valid), .s3_write_en(s3_write_en));

    // master 1
    master master1(.clock(clk),
                   .enable(m1_enable),
                   .read_en(m1_read_en),
                   .data_in(data_in1),
                   .addr_in(addr_in1),
                   .data_rx(m1_data_in),
                   .bus_ready(m1_available),
                   .slave_valid(m1_valid_in),
                   .bus_req(m1_request),
                   .addr_tx(m1_address),
                   .data_tx(m1_data),
                   .valid(m1_address_valid),
                   .valid_s(m1_valid),
                   .write_en_slave(m1_write_en));

    // master 2
    master master2(.clock(clk),
                    .enable(m2_enable),
                    .read_en(m2_read_en),
                    .data_in(data_in2),
                    .addr_in(addr_in2),
                    .data_rx(m2_data_in),
                    .bus_ready(m2_available),
                    .slave_valid(m2_valid_in),
                    .bus_req(m2_request),
                    .addr_tx(m2_address),
                    .data_tx(m2_data),
                    .valid(m2_address_valid),
                    .valid_s(m2_valid),
                    .write_en_slave(m2_write_en));

    // slave 1
    slave #(.MemN(2), .N(8), .ADN(12)) slave1(.validIn(s1_valid),
                                                .wren(s1_write_en),
                                                .Address(s1_address),
                                                .DataIn(s1_data),
                                                .clk(clk),
                                                .validOut(s1_valid_out),
                                                .DataOut(s1_data_out));

    // slave 2
    slave #(.MemN(2), .N(8), .ADN(12)) slave2(.validIn(s2_valid),
                                                .wren(s2_write_en),
                                                .Address(s2_address),
                                                .DataIn(s2_data),
                                                .clk(clk),
                                                .validOut(s2_valid_out),
                                                .DataOut(s2_data_out));

    // slave 3
    slave #(.MemN(2), .N(8), .ADN(12)) slave3(.validIn(s3_valid),
                                                .wren(s3_write_en),
                                                .Address(s3_address),
                                                .DataIn(s3_data),
                                                .clk(clk),
                                                .validOut(s3_valid_out),
                                                .DataOut(s3_data_out));

    // Generating a clock with 1s period
//     always @(posedge clk ) begin
//         if (stop) begin
//                 counter <= 25'd0;
//                 tick <= 0;
//         end  
//         else if (counter == 25'd25000000)   begin
//                 counter <= 25'd0;
//                 tick <= ~tick;
//         end   
//         else    begin
//                 counter <= counter + 25'd1;  
//         end
//     end

endmodule //top_level