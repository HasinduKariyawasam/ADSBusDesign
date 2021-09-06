module top_level (input clk, reset, start,
                  input [4:0] state_in,
                  output [4:0] controller_state,
                  output [4:0] m1_state, m2_state,
                  output [7:0] m1_data_read, m2_data_read,
                  output [3:0] s1_state,s2_state,s3_state,
                  output [2:0] arbiter_state);

    // wires from master to arbiter
    wire m1_request, m1_address, m1_data, m1_valid,
         m1_address_valid, m1_write_en, m1_burst;
    wire m2_request, m2_address, m2_data, m2_valid,
         m2_address_valid, m2_write_en, m2_burst;

    // wires from arbiter to master
    wire m1_ready, m1_available, m1_data_in, m1_valid_in;
    wire m2_ready, m2_available, m2_data_in, m2_valid_in;

    // wires from slave to arbiter
    wire s1_ready, s1_data_out, s1_valid_out, s1_hold; 
    wire s2_ready, s2_data_out, s2_valid_out, s2_hold; 
    wire s3_ready, s3_data_out, s3_valid_out, s3_hold;

    // wires from arbiter to slave
    wire s1_address, s1_data, s1_valid, s1_write_en, s1_burst, bus_ready_s1;
    wire s2_address, s2_data, s2_valid, s2_write_en, s2_burst, bus_ready_s2;
    wire s3_address, s3_data, s3_valid, s3_write_en, s3_burst, bus_ready_s3;

    // wires from controller to masters
    wire m1_enable, m1_read_en;
    wire m2_enable, m2_read_en;
    wire [7:0] data_in1, data_in2;
    wire [13:0] addr_in1, addr_in2;
    wire [2:0] burst_mode_in1,burst_mode_in2;

    // registers for the clock divider
    reg [24:0] counter;
    reg tick;

    // arbiter
    arbiter arbiter(.clk(clk),
                    .reset(reset),
                    .m1_request(m1_request), .m1_address(m1_address), .m1_data(m1_data), 
                    .m1_valid(m1_valid), .m1_address_valid(m1_address_valid),
                    .m1_write_en(m1_write_en), .m1_burst(m1_burst),
                    .m2_request(m2_request), .m2_address(m2_address), .m2_data(m2_data), 
                    .m2_valid(m2_valid), .m2_address_valid(m2_address_valid), 
                    .m2_write_en(m2_write_en), .m2_burst(m2_burst),
                    .s1_data_in(s1_data_out), .s2_data_in(s2_data_out), .s3_data_in(s3_data_out),
                    .s1_ready(s1_ready), .s2_ready(s2_ready), .s3_ready(s3_ready),
                    .s1_valid_out(s1_valid_out), .s2_valid_out(s2_valid_out), .s3_valid_out(s3_valid_out),
                    .s1_hold(s1_hold), .s2_hold(s2_hold), .s3_hold(s3_hold),
                    .m1_data_out(m1_data_in), .m2_data_out(m2_data_in),
                    .m1_ready(m1_ready), .m1_available(m1_available),
                    .m2_ready(m2_ready), .m2_available(m2_available),
                    .m1_valid_in(m1_valid_in), .m2_valid_in(m2_valid_in),
                    .s1_address(s1_address), .s1_data(s1_data), .s1_burst(s1_burst),
                    .s1_valid(s1_valid), .s1_write_en(s1_write_en), .bus_ready_s1(bus_ready_s1),
                    .s2_address(s2_address), .s2_data(s2_data), .s2_burst(s2_burst),
                    .s2_valid(s2_valid), .s2_write_en(s2_write_en), .bus_ready_s2(bus_ready_s2),
                    .s3_address(s3_address), .s3_data(s3_data), .s3_burst(s3_burst),
                    .s3_valid(s3_valid), .s3_write_en(s3_write_en), .bus_ready_s3(bus_ready_s3),
                    .state(arbiter_state));

    // master 1
    master master1(.clock(clk),
                   .reset(reset),
                   .enable(m1_enable),
                   .read_en(m1_read_en),
                   .data_in(data_in1),
                   .addr_in(addr_in1),
                   .burst_mode_in(burst_mode_in1),
                   .data_rx(m1_data_in),
                   .slave_ready(m1_ready),
                   .bus_ready(m1_available),
                   .slave_valid(m1_valid_in),
                   .bus_req(m1_request),
                   .addr_tx(m1_address),
                   .data_tx(m1_data),
                   .valid(m1_address_valid),
                   .valid_s(m1_valid),
                   .write_en_slave(m1_write_en),
                   .burst_mode(m1_burst),
                   .present(m1_state),
                   .data_read(m1_data_read));

    // master 2
    master master2(.clock(clk),
                    .reset(reset),
                    .enable(m2_enable),
                    .read_en(m2_read_en),
                    .data_in(data_in2),
                    .addr_in(addr_in2),
                    .burst_mode_in(burst_mode_in2),
                    .data_rx(m2_data_in),
                    .slave_ready(m2_ready),
                    .bus_ready(m2_available),
                    .slave_valid(m2_valid_in),
                    .bus_req(m2_request),
                    .addr_tx(m2_address),
                    .data_tx(m2_data),
                    .valid(m2_address_valid),
                    .valid_s(m2_valid),
                    .write_en_slave(m2_write_en),
                    .burst_mode(m2_burst),
                    .present(m2_state),
                    .data_read(m2_data_read));

    // slave 1
    slave #(.MemN(2), .N(8), .DelayN(20), .ADN(12)) slave1(.validIn(s1_valid),
                                                .wren(s1_write_en),
                                                .reset(reset),
                                                .Address(s1_address),
                                                .DataIn(s1_data),
                                                .BurstEn(s1_burst),
                                                .clk(clk),
                                                .BusAvailable(bus_ready_s1),
                                                .ready(s1_ready),
                                                .validOut(s1_valid_out),
                                                .hold(s1_hold),
                                                .DataOut(s1_data_out),
                                                .state_out(s1_state));

    // slave 2
    slave #(.MemN(2), .N(8), .DelayN(20), .ADN(12)) slave2(.validIn(s2_valid),
                                                .reset(reset),
                                                .wren(s2_write_en),
                                                .Address(s2_address),
                                                .DataIn(s2_data),
                                                .BurstEn(s2_burst),
                                                .clk(clk),
                                                .BusAvailable(bus_ready_s2),
                                                .ready(s2_ready),
                                                .validOut(s2_valid_out),
                                                .hold(s2_hold),
                                                .DataOut(s2_data_out),
                                                .state_out(s2_state));

    // slave 3
    slave #(.MemN(2), .N(8), .DelayN(0), .ADN(12)) slave3(.validIn(s3_valid),
                                                .reset(reset),
                                                .wren(s3_write_en),
                                                .Address(s3_address),
                                                .DataIn(s3_data),
                                                .BurstEn(s3_burst),
                                                .clk(clk),
                                                .BusAvailable(bus_ready_s3),
                                                .ready(s3_ready),
                                                .validOut(s3_valid_out),
                                                .hold(s3_hold),
                                                .DataOut(s3_data_out),
                                                .state_out(s3_state));

    // controller
    controller controller(  .clk(clk),.reset(reset),.start(start),
                            .m1_request(m1_request),.m2_request(m2_request),
                            .state_in(state_in),
                            .m1_enable(m1_enable),.m2_enable(m2_enable),
                            .m1_burst_mode(burst_mode_in1), .m2_burst_mode(burst_mode_in2),
                            .m1_read_en(m1_read_en),.m2_read_en(m2_read_en),
                            .data_in1(data_in1),.data_in2(data_in2),
                            .addr_in1(addr_in1),.addr_in2(addr_in2),
                            .state_out(controller_state));


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