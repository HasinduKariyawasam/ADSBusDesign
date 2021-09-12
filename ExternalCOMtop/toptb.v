`timescale 1ns/1ps
module toptb ();

    reg clk, reset,start;
    reg [4:0] state_in;

    localparam DEL_PERIOD = 1000;
    localparam BURSTN = 16;

    always begin
        clk = 1; #10; clk = 0; #10;
    end

    top dut(.clk(clk),.reset(reset),.start(start),
                    .state_in(state_in));

    initial begin
        reset = 0; 
        start = 0;   
        state_in = 5'd0; #40;
        
   
        //master 1 write to slave 2 address = 1365 data = 170
         start = 1; #40; start = 0;
        #(DEL_PERIOD*BURSTN);
        $stop;
        
        // //master 1 read from slave 2 address = 1365 adn master 2 write
        // state_in = 5'd2; start = 1; #40; start = 0;
        // #(DEL_PERIOD*2*BURSTN);
        // $stop;

        // //master 1 read from slave 2 and master 2 write to slave 1
        // state_in = 5'd3; start = 1; #40; start = 0;
        // #(DEL_PERIOD*2*BURSTN);
        // $stop;


        //master 1 and master 2 read from slave 2   
        // state_in = 5'd4; start = 1; #40; start = 0;
        #(DEL_PERIOD*4*BURSTN);
        $stop;

        //master 1 and master 2 write to slave 2
        // state_in = 5'd5; start = 1; #40; start = 0;
        #(DEL_PERIOD*2*BURSTN);
        $stop;

        //master 2 read from slave 2 and master 1 read from slave 1
        // state_in = 5'd6; start = 1; #40; start = 0;
        #(DEL_PERIOD*3*BURSTN);
        $stop;

        //master 1 write to slave 1 and master 2 read from slave 1
        // state_in = 5'd7; start = 1; #40; start = 0;
        #(DEL_PERIOD*2*BURSTN);
        $stop;

        //master 1 read and master 2 write slave 1  
        // state_in = 5'd8; start = 1; #40; start = 0;
        #(DEL_PERIOD*2*BURSTN);
        $stop;

        //master 1 write to slave 2 and master 2 write to slave 1
        // state_in = 5'd9; start = 1; #40; start = 0;
        #(DEL_PERIOD*2*BURSTN);
        $stop;




        

        #3000;

        $stop;
    end

endmodule //top_level_testbench