module top_wrapper (


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
wire [7:0] ExternalCounter;

wire inclk, ena;

top top(.clk(clk), .reset(reset), .start(start),
            .state_in(state_in),
            .ExternalCounter(ExternalCounter));

clock_divider clock_divider(.inclk(inclk),.ena(ena),.clk(clk));

assign inclk = CLOCK_50;
assign reset = SW[17];
assign start = SW[15];
assign ena   = SW[16];
assign state_in = SW[4:0];

char7 c1(ExternalCounter[3:0],HEX0);


char7 c2(ExternalCounter[7:4],HEX1);

assign LEDG[8] = clk;


endmodule