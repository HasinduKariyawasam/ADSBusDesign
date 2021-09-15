module top_wrapper (


input CLOCK_50,
input  [17:0] SW,
inout [7:0] GPIO,
input [3:0] KEY,
output [8:0] LEDG,
output [17:0] LEDR,
output [6:0] HEX0,HEX1,HEX2,HEX3,HEX4,HEX5,HEX6,HEX7);


wire clk, reset, start, end_tx, tick, ext_data_out;
wire [4:0] state_in;

wire [4:0] controller_state, rx_present;
wire [5:0] m1_state, m2_state;
wire [7:0] m1_data_read, m2_data_read;
wire [3:0] s1_state,s2_state,s3_state;
wire [2:0] arbiter_state, state_tx;
wire [1:0] state_ctrl;
wire [7:0] ExternalCounter1, ExternalCounter2, ack_buf, received_data_read, to_uart, WriteDataReg;

wire inclk, ena,  ext_data_in,ack_in,ack_out;


top top1(   .clk(clk), 
            .reset(reset), 
            .start(start),
            .state_in(state_in),
            .rx_present(rx_present),
            .m1_state(m1_state),
            .m2_state(m2_state),
            .to_uart(to_uart),
            .s1_state(s1_state),
            .s2_state(s2_state),
            .ExternalCounter(ExternalCounter1),
            .ack_buf(ack_buf),
            .WriteDataReg(WriteDataReg),
            .arbiter_state(arbiter_state),
            .state_tx(state_tx),
            .state_ctrl(state_ctrl),
            .received_data_read(received_data_read),
            .end_tx(end_tx),
            .tick(tick),
            .ext_data_out(ext_data_out),
            .ext_data_in(ext_data_in),
            .ack_in(ack_in),
            .ack_out(ack_out)
            );

top top2(   .clk(clk), 
            .reset(reset), 
            .start(1'd0),
            .state_in(5'd0),
            // .rx_present(rx_present),
            // .m1_state(m1_state),
            // .m2_state(m2_state),
            // .to_uart(to_uart),
            // .s1_state(s1_state),
            // .s2_state(s2_state),
            .ExternalCounter(ExternalCounter2),
            // .ack_buf(ack_buf),
            // .WriteDataReg(WriteDataReg),
            // .arbiter_state(arbiter_state),
            // .state_tx(state_tx),
            // .state_ctrl(state_ctrl),
            // .received_data_read(received_data_read),
            // .end_tx(end_tx),
            // .tick(tick),
            .ext_data_out(ext_data_in),
            .ext_data_in(ext_data_out),
            .ack_in(ack_out),
            .ack_out(ack_in)
            );


//  assign GPIO[1] = ack_out;
//  assign ack_in  = GPIO[3];
//  assign LEDG[2]  = GPIO[3];
//  assign GPIO[5] = ext_data_out;
//  assign ext_data_in = GPIO[7];
//  assign LEDG[3] = GPIO[7];

clock_divider clock_divider(.inclk(inclk),.ena(ena),.clk(clk));

assign inclk = CLOCK_50;
assign reset = SW[17];
assign start = SW[15];
assign ena   = SW[16];
assign state_in = SW[4:0];

char7 c1(ExternalCounter1[3:0],HEX0);
char7 c2(ExternalCounter1[7:4],HEX1);


char7 c3(m2_state[3:0],HEX2);
char7 c4(rx_present[3:0],HEX3);
char7 c5(ExternalCounter2[3:0],HEX4);
char7 c6(ExternalCounter2[7:4],HEX5);
char7 c7(received_data_read[3:0],HEX6);
char7 c8(received_data_read[7:4],HEX7);


//assign LEDR[16] = present[4];

assign LEDG[8] = clk;
assign LEDG[7] = end_tx;

assign LEDG[0] = tick ;
assign LEDG[1] = ext_data_out;

assign LEDR[0] = state_tx[0];
assign LEDR[1] = state_tx[1];
assign LEDR[2] = state_tx[2];


endmodule