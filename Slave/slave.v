module slave #(
    parameter MemN = 2,   // Memory Block Size
    parameter N = 8,      // Memory Block Width
    parameter ADN = 12    // Address Length
) (
    // Input Ports
	input     validIn,wren,
	input     Address,DataIn,
	input     clk,
	

	// Output Ports
    output reg  ready=0,validOut=0,
	output reg DataOut=0);


    reg [ N-1 : 0 ] BRAMmem [0 : MemN*1024-1];

    localparam ADN_BITS = $clog2(ADN);
    localparam N_BITS   = $clog2(N);
    localparam IDLE     = 2'd0;
    localparam AD       = 2'd1;
    localparam WD       = 2'd2;
    localparam RD       = 2'd3;


    reg [1:0] state = IDLE;
    reg [1:0] next_state;
    reg [ADN-1:0] AddressReg;
    reg [N-1:0] WriteDataReg;
    reg [N-1:0] ReadDataReg;
    reg  [N_BITS:0] counterN = 0;
    reg  [ADN_BITS:0] counterADN = 0;


    always @(*) begin
        case (state)
            IDLE : begin
                if(validIn) next_state = AD;
                else        next_state = IDLE;                
            end
            AD: begin
                if((counterADN == ADN) && validIn && wren) next_state <= WD;   
                else if ((counterADN == ADN) &&  ~wren)    next_state <= RD;  
                else next_state <= AD;
            end
            WD: begin
                if(counterN == N)   next_state <= IDLE;
                else                next_state <= WD;
            end
            RD: begin
                if(counterN == N+1) next_state <= IDLE;
                else                next_state <= RD;
            end


        endcase
        
    end

    always @(posedge clk) begin
        state <= next_state;
    end


    //output decode
    
    



    always @(posedge clk) begin
        case(state)
            IDLE: begin
                ready <= 1;
                counterADN <= 0;
                counterN <= 0;

            end

            AD: begin
                
                if((counterADN < ADN) && validIn) begin
                    AddressReg <= {AddressReg[ADN-2:0],Address};
                    counterADN <= counterADN + 1'b1;
                    ready      <= 0 ;
                end    
                else begin
                    AddressReg <= AddressReg;
                    ready      <= 1 ;
                end   
            end

            WD: begin
                
                if((counterN < N) && validIn) begin
                    WriteDataReg <= {WriteDataReg[N-2:0],DataIn};
                    counterN <= counterN + 1'b1;
                    ready      <= 0 ;
                end   
                else begin
                    if(counterN == N) begin
                        BRAMmem[AddressReg] <= WriteDataReg;
                        ready      <= 1 ;
                    end
                    else    WriteDataReg <= WriteDataReg;                    
                end  
            end

            RD: begin

                if (counterN == 0) begin
                    ReadDataReg <= BRAMmem[AddressReg];
                    counterN <= counterN + 1'b1;
                    validOut <= 1;
                end
                else begin
                    if(counterN < N+1) begin
                        validOut <= 1;
                        DataOut <= ReadDataReg[N-1];
                        ReadDataReg <= ReadDataReg << 1; 
                        counterN <= counterN + 1'b1; 
                    end
                    else begin
                        validOut <= 0;
                    end


                end


                
            end

        endcase    
    
    end



    
endmodule