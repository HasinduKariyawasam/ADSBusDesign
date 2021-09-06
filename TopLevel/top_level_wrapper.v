module top_level_wrapper (


input CLOCK_50,
input  [17:0] SW,
input [3:0] KEY,
output [8:0] LEDG,
output [17:0] LEDR,
output [6:0] HEX0,HEX1,HEX2,HEX3,HEX4,HEX5,HEX6,HEX7);


wire clk, reset, start;
wire [4:0] state_in;

wire [4:0] controller_state;
wire [4:0] m1_state, m2_state;
wire [7:0] m1_data_read, m2_data_read;
wire [3:0] s1_state,s2_state,s3_state;
wire [2:0] arbiter_state;

wire inclk, ena;

top_level top_level(.clk(clk), .reset(reset), .start(start),
                        .state_in(state_in),
                        .controller_state(controller_state),
                        .m1_state(m1_state),.m2_state(m2_state),
                        .m1_data_read(m1_data_read),.m2_data_read(m2_data_read),
                        .s1_state(s1_state),.s2_state(s2_state),.s3_state(s3_state),
                        .arbiter_state(arbiter_state));

clock_divider clock_divider(.inclk(inclk),.ena(ena),.clk(clk));

assign inclk = CLOCK_50;
assign reset = SW[17];
assign start = SW[15];
assign ena   = SW[16];
assign state_in = SW[4:0];

char7 c1(controller_state[3:0],HEX0);
assign LEDR[6] = controller_state[4];

char7 c2(m1_state[3:0],HEX1);
assign LEDR[7] = m1_state[4];

char7 c3(m2_state[3:0],HEX2);
assign LEDR[8] = m2_state[4];

char7 c4(arbiter_state,HEX3);

char7 c5(m1_data_read[3:0],HEX4);
char7 c6(m1_data_read[7:4],HEX5);

char7 c7(m2_data_read[3:0],HEX6);
char7 c8(m2_data_read[7:4],HEX7);

assign  LEDG[3:0] = s1_state;
assign  LEDG[7:4] = s2_state;
assign  LEDR[3:0] = s3_state;

assign LEDG[8] = clk;


endmodule