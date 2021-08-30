`timescale 1ns/1ps

module slave_tb();

    reg clk = 0;
    localparam CLK_PERIOD = 10;
    initial begin
      forever begin
        #(CLK_PERIOD/2);
        clk <= ~clk;
      end
    end

    parameter N = 8;
    reg         validIn=0;
    reg         wren=0;
    reg         Address=0;
    reg         DataIn=0;
    reg         BusAvailable=0;
    wire         ready;
    wire         validOut;
    wire         DataOut;

    slave  slave (.*);


    initial begin
      @(posedge clk);
      validIn = 0; wren = 0; Address = 0; DataIn = 0;BusAvailable=0;

      #(CLK_PERIOD*3);

      @(posedge clk);
      validIn = 1;wren = 1;BusAvailable=1;

      @(posedge clk);
      Address = 0;
      @(posedge clk);
      Address = 0;
      @(posedge clk);
      Address = 1;
      @(posedge clk);
      Address = 0;
      @(posedge clk);
      Address = 0;
      DataIn = 1;
      @(posedge clk);
      Address = 1;
      DataIn = 1;
      @(posedge clk);
      DataIn = 1;
      Address = 1;
      @(posedge clk);
      DataIn = 0;
      Address = 0;
      @(posedge clk);
      DataIn = 0;
      Address = 1;
      @(posedge clk);
      DataIn = 1;
      Address = 0;
      @(posedge clk);
      DataIn = 0;
      Address = 0;
      @(posedge clk);
      DataIn = 1;
      Address = 1;

      @(posedge clk);
      Address = 0;
      DataIn = 0;
      validIn = 0;
      wren = 0;


      @(posedge ready);
      DataIn = 0;
      validIn = 0;
      wren = 0;

      #(CLK_PERIOD*3);
      

      @(posedge clk);
      validIn = 0;
      DataIn = 0;
      wren = 0;


      #(CLK_PERIOD*3);

      @(posedge clk);
      validIn = 1;wren = 0;

      @(posedge clk);
      Address = 0;
      @(posedge clk);
      Address = 0;
      @(posedge clk);
      Address = 1;
      @(posedge clk);
      Address = 0;
      @(posedge clk);
      Address = 0;
      @(posedge clk);
      Address = 1;
      @(posedge clk);
      Address = 1;
      @(posedge clk);
      Address = 0;
      @(posedge clk);
      Address = 1;
      @(posedge clk);
      Address = 0;
      @(posedge clk);
      BusAvailable = 0;
      Address = 0;
      @(posedge clk);
      Address = 1;

      @(posedge clk);
      Address = 0;
      validIn = 0;
      #(CLK_PERIOD*3);
      @(posedge clk);
      BusAvailable = 0;

      @(posedge ready);
      #(CLK_PERIOD*3);
      BusAvailable = 1;






      #(CLK_PERIOD*10);
      $stop;

    end
endmodule