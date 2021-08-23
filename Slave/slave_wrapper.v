module slave_wrapper (


input CLOCK_50,
input  [17:0] SW,
input [3:0] KEY,
output [8:0] LEDG,
output [17:0] LEDR,
output [6:0] HEX0,HEX1,HEX2,HEX3,HEX4,HEX5,HEX6,HEX7);




    parameter MemN = 2;   // Memory Block Size
    parameter N = 8;    // Memory Block Width
    parameter ADN = 12;    // Address Length


    wire [1:0] state_out;
    wire [1:0] next_state_out;
    wire [ADN-1:0]   AddressReg_out;
    wire [N-1:0]     WriteDataReg_out;
    wire [N-1:0]     ReadDataReg_out;
    wire [3:0]  counterN_out;
    wire [4:0]counterADN_out;


    slave dut (
        .validIn(SW[0]),
        .wren(SW[1]),
        .Address(SW[2]),
        .DataIn(SW[3]),
        .clk(KEY[0]),

        .state_out(state_out),
        .next_state_out(next_state_out),
        .AddressReg_out(AddressReg_out),
        .WriteDataReg_out(WriteDataReg_out),
        .ReadDataReg_out(ReadDataReg_out),
        .counterN_out(counterN_out),
        .counterADN_out(counterADN_out),

        .ready(LEDG[0]),
        .validOut(LEDG[1]),
        .DataOut(LEDG[2])
    );



    assign LEDR[0] = SW[0];
    assign LEDR[1] = SW[1];
    assign LEDR[2] = SW[2];
    assign LEDR[3] = SW[3];
    assign LEDR[17] = KEY[0];

    assign LEDG[6] = state_out[0];
    assign LEDG[7] = state_out[1];

    assign LEDG[4] = next_state_out[0];
    assign LEDG[5] = next_state_out[1];


    char7 C1(AddressReg_out[3:0],HEX0);
    char7 C2(AddressReg_out[7:4],HEX1);
    char7 C3(AddressReg_out[11:8],HEX2);
    char7 C4(counterN_out[3:0],HEX3);


    char7 C11(WriteDataReg_out[3:0],HEX4);
    char7 C22(WriteDataReg_out[7:4],HEX5);

    char7 C31(counterADN_out[3:0],HEX6);
    // char7 C41(counterADN_out[7:4],HEX7);







    
endmodule