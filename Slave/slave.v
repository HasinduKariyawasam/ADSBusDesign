module slave #(
    parameter MemN = 2,   // Memory Block Size
    parameter N = 8,      // Memory Block Width
    parameter ADN = 12,  // Address Length
    parameter BN = 3    //Burst bit length
) (
    // Input Ports
	input     validIn,wren, reset,
	input     Address,DataIn,BurstEn,
	input     clk,
	

	// Output Ports
    output [2:0] state_out,
    // output [1:0] next_state_out,
    // output [ADN-1:0]   AddressReg_out,
    // output [N-1:0]     WriteDataReg_out,
    // output [N-1:0]     ReadDataReg_out,
    // output [N_BITS:0]  counterN_out,
    // output [ADN_BITS:0]counterADN_out,
    output reg  ready=0,validOut=0,
	output reg DataOut=0);


    reg [ N-1 : 0 ] BRAMmem [0 : MemN*1024-1];      //BRAM Block

    localparam ADN_BITS = $clog2(ADN);
    localparam N_BITS   = $clog2(N);
    localparam IDLE     = 3'd0;             //IDLE STATE
    localparam AD       = 3'd1;             //Address Decode State for Read Operations
    localparam ADWR     = 3'd2;            //Address Decode and Write Decode State for Write Operations
    localparam RD       = 3'd3;             //Read State for Read Operations
    localparam BADWR    = 3'd4;
    localparam BWR      = 3'd5;
    localparam BAD      = 3'd6;
    localparam BRD      = 3'd7;





    reg [2:0]       state           = IDLE;             //state register
    reg [2:0]       next_state;                         //next state variable
    reg [ADN-1:0]   AddressReg      = 0;                //register to hold Address
    reg [N-1:0]     WriteDataReg    = 0;                //register to hold Write Data
    reg [BN-1:0]    BurstLenReg     = 0;                //register to hold Burst Len   
    reg [N-1:0]     ReadDataReg     = 0;                //register to hold Read Data
    reg [N_BITS:0]  counterN        = 0;                //counter to count data decode
    reg [ADN_BITS:0]counterADN      = 0;                //counter to count address decode
    reg [1:0]       counterBN       = 0;                //counter to count burst decode
    reg [9:0]       counterBurst    = 0;                //counter to track burst length


    assign state_out = state;
    assign next_state_out = next_state;
    assign AddressReg_out = AddressReg;
    assign WriteDataReg_out = WriteDataReg;
    assign ReadDataReg_out = ReadDataReg;
    assign counterN_out = counterN;
    assign counterADN_out = counterADN;

    ////////////////////////////////////////////////////////////////////////////////
    //Next State Decode Logic
    always @(*) begin
        if (reset) begin
            next_state <= IDLE;
        end
        else    begin
            case (state)
                IDLE : begin
                    if(~BurstEn) begin
                        if      (validIn && wren)               next_state <= ADWR;
                        else if (validIn && ~wren)              next_state <= AD ;
                        else                                    next_state <= IDLE;          
                    end
                    else    begin
                        if      (validIn && wren)               next_state <= BADWR;
                        else if (validIn && ~wren)              next_state <= BAD ;
                        else                                    next_state <= IDLE ;
                    end            
                end
                AD: begin
                    if ((counterADN == ADN))                next_state <= RD;  
                    else                                    next_state <= AD;
                end
                ADWR: begin
                    if(counterN == N)                       next_state <= IDLE;
                    else                                    next_state <= ADWR;
                end
                RD: begin
                    if(counterN == N+1)                     next_state <= IDLE;
                    else                                    next_state <= RD;
                end
                BADWR: begin
                    if(counterN == N)                       next_state <= BWR;
                    else                                    next_state <= BADWR;
                end
                BWR : begin
                    if(counterBurst[BurstLenReg + 2])       next_state <= IDLE;
                    else                                    next_state <= BWR;                    
                end 
                BAD : begin
                    if ((counterADN == ADN))                next_state <= BRD;  
                    else                                    next_state <= BAD;                    
                end 
                BRD : begin
                    if(counterBurst[BurstLenReg + 2])       next_state <= IDLE;
                    else                                    next_state <= BRD;      
                end       
            endcase
        end 
    end

    ///////////////////////////////////////////////////////////////////////////////////
    //State Register
    always @(posedge clk) begin
        state <= next_state;
    end
    
    ///////////////////////////////////////////////////////////////////////////////////
    //Output Logic
    always @(posedge clk) begin
        case(state)
            ///////////////////////////////////////////////////////
            IDLE: begin
                ready        <= 1;
                counterADN   <= 0;
                counterN     <= 0;
                counterBN    <= 0;
                counterBurst <= 0;
                AddressReg   <= 0;
                WriteDataReg <= 0;
                ReadDataReg  <= 0;
                BurstLenReg  <= 0;
                DataOut      <= 0;
                validOut     <= 0;

            end
            ///////////////////////////////////////////////////////
            AD: begin
                
                if((counterADN < ADN) && validIn) begin
                    AddressReg <= {AddressReg[ADN-2:0],Address};
                    counterADN <= counterADN + 1'b1;
                    ready      <= 1 ;
                end    
                else begin
                    AddressReg <= AddressReg;
                    ready      <= 0 ;
                end   
            end


            ///////////////////////////////////////////////////////
            ADWR: begin
                if((counterADN < ADN - N) && validIn ) begin
                    AddressReg <= {AddressReg[ADN-2:0],Address};
                    counterADN <= counterADN + 1'b1;
                    ready      <= 1 ;
                    
                end
                else if((counterADN < ADN) && validIn) begin
                    AddressReg      <= {AddressReg[ADN-2:0],Address};
                    WriteDataReg    <= {WriteDataReg[N-2:0],DataIn};
                    counterN        <= counterN + 1'b1;
                    counterADN      <= counterADN + 1'b1;
                    ready           <= 1 ;
                end    
                else begin
                    if(counterN == N) begin
                        BRAMmem[AddressReg] <= WriteDataReg;
                        ready      <= 1 ;
                    end
                    else begin
                        AddressReg      <= AddressReg;
                        WriteDataReg    <= WriteDataReg;     
                        ready           <= 1 ;
                    end    
                end 
            end


            /////////////////////////////////////////////////////////
            RD: begin

                if (counterN == 0) begin
                    ReadDataReg <= BRAMmem[AddressReg];
                    counterN    <= counterN + 1'b1;
                    validOut    <= 1;
                end
                else begin
                    if(counterN < N+1) begin
                        validOut    <= 1;
                        DataOut     <= ReadDataReg[N-1];
                        ReadDataReg <= ReadDataReg << 1; 
                        counterN    <= counterN + 1'b1; 
                    end
                    else begin
                        validOut <= 0;
                        DataOut  <=0;
                    end
                end               
            end

            ///////////////////////////////////////////////////////
            BADWR: begin
                if((counterADN < ADN - N) && validIn ) begin
                    AddressReg <= {AddressReg[ADN-2:0],Address};
                    counterADN <= counterADN + 1'b1;
                    ready      <= 1 ;
                    
                end
                else if((counterADN < ADN - BN ) && validIn) begin
                    AddressReg      <= {AddressReg[ADN-2:0],Address};
                    WriteDataReg    <= {WriteDataReg[N-2:0],DataIn};
                    counterN        <= counterN + 1'b1;
                    counterADN      <= counterADN + 1'b1;
                    ready           <= 1 ;
                end
                else if((counterADN < ADN) && validIn) begin
                    AddressReg      <= {AddressReg[ADN-2:0],Address};
                    WriteDataReg    <= {WriteDataReg[N-2:0],DataIn};
                    BurstLenReg     <= {BurstLenReg[BN-2:0],BurstEn};
                    counterN        <= counterN + 1'b1;
                    counterADN      <= counterADN + 1'b1;
                    ready           <= 0 ;
                end     
                else begin
                    if(counterN == N) begin
                        counterBurst <= counterBurst + 1'b1;
                        BRAMmem[AddressReg] <= WriteDataReg;
                        AddressReg <= AddressReg + 1'b1;
                        counterN   <= 0;
                        ready      <= 0 ;
                    end
                    else begin
                        AddressReg   <= AddressReg;
                        WriteDataReg <= WriteDataReg;     
                        ready        <= 1 ;
                    end    
                end 
            end

            /////////////////////////////////////////////////////////
            BWR: begin

                if (counterN < 3) begin
                    counterN     <= counterN + 1'b1;
                    WriteDataReg <= 0;
                    ready        <= 1;
                end
                else begin
                    if((counterN < N+3) && validIn) begin
                        ready <= 0;
                        WriteDataReg <= {WriteDataReg[N-2:0],DataIn};
                        counterN <= counterN + 1'b1; 
                    end
                    else if(counterN == N+3)begin
                        counterBurst <= counterBurst + 1'b1;
                        BRAMmem[AddressReg] <= WriteDataReg;
                        AddressReg <= AddressReg + 1'b1;
                        counterN   <= 0;
                        ready      <= 0 ;
                    end
                    else begin
                        ready   <= 1;
                        WriteDataReg <= WriteDataReg; 
                    end
                end               
            end


            ///////////////////////////////////////////////////////
            BAD: begin
                
                if((counterADN < ADN-BN) && validIn) begin
                    AddressReg <= {AddressReg[ADN-2:0],Address};
                    counterADN <= counterADN + 1'b1;
                    ready      <= 1 ;
                end
                else if((counterADN < ADN) && validIn) begin
                    AddressReg      <= {AddressReg[ADN-2:0],Address};
                    BurstLenReg     <= {BurstLenReg[BN-2:0],BurstEn};
                    counterADN      <= counterADN + 1'b1;
                    ready           <= 1 ;
                end    
                else begin
                    AddressReg <= AddressReg;
                    ready      <= 0 ;
                end   
            end


            /////////////////////////////////////////////////////////
            BRD: begin

                if(~counterBurst[BurstLenReg+2]) begin
                    if ((counterN == 0)) begin
                        ReadDataReg <= BRAMmem[AddressReg];
                        AddressReg  <= AddressReg + 1'b1;
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
                        else if(counterN == N+1) begin
                            validOut <= 0;
                            DataOut  <= 0;
                            ReadDataReg <= 0;
                            counterBurst <= counterBurst + 1'b1;
                            counterN     <= 0;
                        end
                        else begin
                            validOut <= 0;
                            DataOut <=0;
                        end
                    end 
                    
                end
                else begin
                    validOut <= 0;
                    DataOut <=0;
                end
                              
            end



            
        endcase     
    end



    
endmodule