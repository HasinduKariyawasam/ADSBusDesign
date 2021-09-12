module uart_tx_toplevel (input clk, reset,
                         input validIn, wren, Address, DataIn, BurstEn,
                               BusAvailable, ack,
                         output [3:0] state_out,
                         output ready, validOut, hold, DataOut, ext_data_out);

    wire tx_external, uart_busy;
    wire [7:0] to_uart;

    bus_to_uart #(.MemN(2), .N(8), .DelayN(20), .ADN(12)) bus_to_uart(.validIn(validIn), .wren(wren),
                                                                      .reset(reset), .Address(Address), .DataIn(DataIn),
                                                                      .BurstEn(BurstEn), .clk(clk), .BusAvailable(BusAvailable),
                                                                      .uart_busy(uart_busy),
                                                                      .state_out(state_out), .to_uart(to_uart),
                                                                      .tx_external(tx_external),
                                                                      .ready(ready), .validOut(validOut), .hold(hold),
                                                                      .DataOut(DataOut));

    uart_tx uart_tx(.clk(clk), .reset(reset), .data_in(to_uart),
                    .tx_external(tx_external), .ack(ack), 
                    .data_out(ext_data_out), .uart_busy(uart_busy));

endmodule //uart_tx_toplevel