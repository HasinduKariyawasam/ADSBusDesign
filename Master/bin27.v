module bin27 
  (
   input       clk,
   input [7:0] ctrlsig_in,
   output      segmentA,
   output      segmentB,
   output      segmentC,
   output      segmentD,
   output      segmentE,
   output      segmentF,
   output      segmentG
   );
 
  reg [6:0] encode = 7'h00;
   
  always @(posedge clk)
    begin
      case (ctrlsig_in[3:0])
        4'b0000 : encode <= 7'h3F;
        4'b0001 : encode <= 7'h06;
        4'b0010 : encode <= 7'h5B;
        4'b0011 : encode <= 7'h4F;
        4'b0100 : encode <= 7'h66;          
        4'b0101 : encode <= 7'h6D;
        4'b0110 : encode <= 7'h7D;
        4'b0111 : encode <= 7'h07;
        4'b1000 : encode <= 7'hFF;
        4'b1001 : encode <= 7'h6F;
        4'b1010 : encode <= 7'h77;
        4'b1011 : encode <= 7'h7C;
        4'b1100 : encode <= 7'h39;
        4'b1101 : encode <= 7'h5E;
        4'b1110 : encode <= 7'h79;
        4'b1111 : encode <= 7'h71;
      endcase
    end
 
  assign segmentA = ~encode[0];
  assign segmentB = ~encode[1];
  assign segmentC = ~encode[2];
  assign segmentD = ~encode[3];
  assign segmentE = ~encode[4];
  assign segmentF = ~encode[5];
  assign segmentG = ~encode[6];
 
endmodule
