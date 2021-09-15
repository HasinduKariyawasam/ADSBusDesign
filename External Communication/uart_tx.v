module uart_tx (input clk, reset,
                input [7:0] data_in,
                input tx_external,
                      ack,
                output reg [2:0] state_tx  = 3'd0,
                output reg [1:0]state_ctrl = 2'd0,
                output reg [7:0] ack_buf   = 8'd0,
                output reg end_tx          = 0,
                output tick,
                output reg data_out = 1,
                output reg uart_busy 
                );

    //wire tick;
    reg [2:0] retx_counter      = 3'd0;
    reg [3:0] counter           = 4'd0;
    reg [3:0] ack_counter       = 4'd0;
    reg [7:0] data_tx           = 8'd0;
    reg [7:0] tx_buf            = 8'd0;
    // reg [7:0] ack_buf           = 8'd0;
    reg [19:0] ack_wait_counter = 20'd0;
    reg counter_en              = 0;
    // reg end_tx                  = 0;
    reg start_tx                = 0;

    //states of the controller
    localparam idle     = 2'd0;
    localparam busy     = 2'd1;
    localparam delay    = 2'd2;

    //states of the transmitter
    localparam wait_tx      = 3'd0;
    localparam start_bit    = 3'd1;
    localparam data_bits    = 3'd2;
    localparam end_bit      = 3'd3;
    localparam wait_ack     = 3'd4;
    localparam read_ack     = 3'd5; 

    //reg state_ctrl      = idle;
    // reg [2:0] state_tx  = wait_tx;

    //UART clock generator (baudrate = 19200 bps)
    baud_gen baud_gen(.clk(clk), .tick(tick));

    //controller
    always @(posedge clk) begin
        if (reset)  state_ctrl <= idle;
        else
            case (state_ctrl) 
                ///////////////////////////////////////////////////////////////
                idle: begin
                    if (tx_external) begin
                        data_tx     <= data_in;
                        uart_busy   <= 1;
                        start_tx    <= 1;
                        state_ctrl  <= busy;
                    end
                    else begin
                        data_tx     <= 8'd0;
                        uart_busy   <= 0;
                        start_tx    <= 0;
                        state_ctrl  <= idle;
                    end
                end
                //////////////////////////////////////////////////////////////
                busy: begin
                    if (end_tx) begin
                        uart_busy   <= 1;
                        start_tx    <= 0;
                        state_ctrl  <= delay;
                    end
                    else begin
                        if (state_tx == wait_tx) begin
                            start_tx    <= 1;
                            uart_busy   <= 1;
                            state_ctrl  <= busy;   
                        end
                        else begin
                            start_tx    <= 0;
                            uart_busy   <= 1;
                            state_ctrl  <= busy;
                        end   
                    end
                end
                //////////////////////////////////////////////////////////////
                delay: begin
                    if (~end_tx) begin
                        uart_busy   <= 0;
                        state_ctrl  <= idle;
                    end
                end
            endcase
    end

    //transmitter
    always @(posedge tick) begin
        if (reset) begin
            data_out    <= 1;
            state_tx <= wait_tx;
        end  
        else
            case(state_tx)
                ////////////////////////////////////////////////////////////
                wait_tx: begin
                    if (start_tx) begin
                        data_out    <= 1;
                        tx_buf      <= data_tx;
                        end_tx      <= 0;
                        state_tx    <= start_bit;
                    end
                    else begin
                        data_out    <= 1;
                        tx_buf      <= 0;
                        end_tx      <= 0;
                        state_tx    <= wait_tx;
                    end
                end
                //////////////////////////////////////////////////////////
                start_bit: begin
                    data_out    <= 0;
                    state_tx    <= data_bits;
                end
                //////////////////////////////////////////////////////////
                data_bits: begin
                    if (counter < 4'd8) begin
                        counter     <= counter + 4'd1;
                        data_out    <= tx_buf[7];
                        tx_buf      <= (tx_buf << 1);
                        state_tx    <= data_bits;
                    end
                    else begin
                        counter     <= 4'd0;
                        data_out    <= 1;
                        state_tx    <= end_bit;
                    end
                end
                ////////////////////////////////////////////////////////
                end_bit: begin
                    data_out    <= 1;
                    state_tx    <= wait_ack;
                end
                ///////////////////////////////////////////////////////
                wait_ack: begin
                    if (ack_wait_counter < 20'd300) begin
                        if (ack) begin
                            counter_en  <= 1;
                            state_tx    <= wait_ack;
                        end
                        else begin
                            counter_en  <= 0;
                            // ack_buf     <= {ack_buf[6:0], ack};
                            state_tx    <= read_ack;
                        end
                    end
                    else begin
                        if (retx_counter < 3'd5) begin
                            counter_en      <= 0;
                            data_out        <= 1;
                            tx_buf          <= data_tx;
                            retx_counter    <= retx_counter + 3'd1;
                            state_tx        <= start_bit;
                        end
                        else begin
                            retx_counter    <= 3'd0;
                            end_tx          <= 1;
                            state_tx        <= wait_tx;
                        end
                    end
                end
                /////////////////////////////////////////////////////
                read_ack: begin
                    if (ack_counter < 4'd8) begin
                        ack_counter     <= ack_counter + 4'd1;
                        ack_buf         <= {ack_buf[6:0], ack};
                        state_tx        <= read_ack;
                    end
                    else begin
                        if (ack_buf == 8'd204) begin
                            end_tx      <= 1;
                            ack_counter <= 4'd0;
                            state_tx    <= wait_tx;
                        end
                        else begin
                            ack_counter <= 4'd0;
                            if (retx_counter < 3'd5) begin
                                retx_counter    <= retx_counter + 3'd1;
                                state_tx        <= start_bit;
                            end
                            else begin 
                                retx_counter    <= 3'd0;
                                end_tx          <= 1;
                                state_tx        <= wait_tx;
                            end
                        end
                    end
                end
            endcase
    end

    //wait counter for acknowledgement (10 ms timeout)
    //Why not tick ? why clk?
    always @(posedge clk) begin
        if (reset)  ack_wait_counter    <= 20'd0;
        else begin
            if (counter_en) begin
                ack_wait_counter    <= ack_wait_counter + 20'd1;
            end
            else begin
                ack_wait_counter    <= 20'd0;
            end
        end
    end

endmodule //uart_tx