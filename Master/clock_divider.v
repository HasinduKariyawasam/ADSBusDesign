module clock_divider(inclk,ena,clk);

 parameter maxcount=32'd10000000;

 input inclk;
 input ena;
 output reg clk=1;

 reg [31:0] count=32'd0;

 always @ (posedge inclk )
	begin
		if (ena)
		begin
			if (count==maxcount)
			begin
			clk=~clk;
			count=32'd0;
			end
			else
			begin
			count=count+1;
			end
		end
		else
		begin
		clk=0;
		end
	end

 endmodule