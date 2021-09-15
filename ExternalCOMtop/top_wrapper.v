module top_wrapper (


input CLOCK_50,
input  [17:0] SW,
input [3:0] KEY,
output [8:0] LEDG,
output [17:0] LEDR,
output [6:0] HEX0,HEX1,HEX2,HEX3,HEX4,HEX5,HEX6,HEX7);


wire clk, reset, start, end_tx;
wire [4:0] state_in;

wire [4:0] controller_state, rx_present;
wire [5:0] m1_state, m2_state;
wire [7:0] m1_data_read, m2_data_read;
wire [3:0] s1_state,s2_state,s3_state;
wire [2:0] arbiter_state, state_tx;
wire [1:0] state_ctrl;
wire [7:0] ExternalCounter, ack_buf,received_data_read,to_uart,WriteDataReg;

wire inclk, ena;

top top(.clk(clk), .reset(reset), .start(start),
            .state_in(state_in),
            .rx_present(rx_present),
            .m1_state(m1_state),.m2_state(m2_state),
            .to_uart(to_uart),
            .s1_state(s1_state),s2_state(s2_state),
            .ExternalCounter(ExternalCounter),
            .ack_buf(ack_buf),
            .WriteDataReg(WriteDataReg),
            .arbiter_state(arbiter_state),
            .state_tx(state_tx),.state_ctrl(state_ctrl),
            .received_data_read(received_data_read),
            .end_tx(end_tx));

clock_divider clock_divider(.inclk(inclk),.ena(ena),.clk(clk));

assign inclk = CLOCK_50;
assign reset = SW[17];
assign start = SW[15];
assign ena   = SW[16];
assign state_in = SW[4:0];

char7 c1(ExternalCounter[3:0],HEX0);
char7 c2(ExternalCounter[7:4],HEX1);


char7 c3(WriteDataReg[3:0],HEX2);
char7 c4(WriteDataReg[7:4],HEX3);
char7 c5(to_uart[3:0],HEX4);
char7 c6(to_uart[7:4],HEX5);
char7 c7(received_data_read[3:0],HEX6);
char7 c8(received_data_read[7:4],HEX7);


assign LEDR[16] = present[4];

assign LEDG[8] = clk;
assign LEDG[7] = end_tx;

assign LEDR[0] = state_tx[0];
assign LEDR[1] = state_tx[1];
assign LEDR[2] = state_tx[2];


endmodule