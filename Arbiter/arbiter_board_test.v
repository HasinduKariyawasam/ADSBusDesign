module arbiter_board_test (input clk, reset, stop,
                           input m1_request, m1_address, m1_data, m1_valid, m1_address_valid,
                                 m2_request, m2_address, m2_data, m2_valid, m2_address_valid, 
                                 s1_ready, s2_ready, s3_ready,
                           output m1_ready, m2_ready, m1_available, m2_available,
                                   s1_address, s1_data, s1_valid,
                                   s2_address, s2_data, s2_valid,
                                   s3_address, s3_data, s3_valid,
                           output [2:0] state,
                           output   m1_connect1, m1_connect2, m1_connect3,
                                    m2_connect1, m2_connect2, m2_connect3,
                           output clk_led, reset_led);

      reg [24:0] counter;
      reg tick;

      // Generating a clock with 1s period

      always @(posedge clk ) begin
            if (stop) begin
                  counter <= 25'd0;
                  tick <= 0;
            end  
            else if (counter == 25'd25000000)   begin
                  counter <= 25'd0;
                  tick <= ~tick;
            end   
            else    begin
                  counter <= counter + 25'd1;  
            // tick <= 0;
            end
      end

      arbiter arbiter(tick, reset,
                        m1_request, m1_address, m1_data, m1_valid, m1_address_valid,
                        m2_request, m2_address, m2_data, m2_valid, m2_address_valid,
                        s1_ready, s2_ready, s3_ready,
                        m1_ready, m2_ready, m1_available, m2_available,
                        s1_address, s1_data, s1_valid,
                        s2_address, s2_data, s2_valid,
                        s3_address, s3_data, s3_valid,
                        state,
                        m1_connect1, m1_connect2, m1_connect3,
                        m2_connect1, m2_connect2, m2_connect3);

      assign clk_led = tick;
      assign reset_led = reset;

endmodule //arbiter_board_test