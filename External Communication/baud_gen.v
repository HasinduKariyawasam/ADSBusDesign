module baud_gen (input clk, reset,
                output tick);

    /*
       ###########################################
       Counter thresholds for different baud rates
       ###########################################
       9600 bps     :   5208***
       14400 bps    :   3472
       19200 bps    :   2604
       38400 bps    :   1302
       57600 bps    :   868
       115200 bps   :   434
       ###########################################
    */

    // assign tick = clk;
    reg [12:0] counter = 13'd0;
    reg tick_reg;

    assign tick = tick_reg;

    always @(posedge clk ) begin
        if (reset) begin
            tick_reg <= 0;
            counter <= 13'd0;
        end
        else if (counter == 13'd4) begin
            tick_reg <= 1;
            counter <= 13'd0;
        end
        else begin
            tick_reg <= 0;
            counter <= counter + 13'd1;
        end
    end

endmodule //baud_gen