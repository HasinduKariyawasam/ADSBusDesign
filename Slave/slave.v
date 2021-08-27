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
    output [1:0] state_out,
    output [1:0] next_state_out,
    output [ADN-1:0]   AddressReg_out,
    output [N-1:0]     WriteDataReg_out,
    output [N-1:0]     ReadDataReg_out,
    // output [N_BITS:0]  counterN_out,
    // output [ADN_BITS:0]counterADN_out,
    output reg  ready=0,validOut=0,
	output reg DataOut=0);


    reg [ N-1 : 0 ] BRAMmem [0 : MemN*1024-1];      //BRAM Block

    localparam ADN_BITS = $clog2(ADN);
    localparam N_BITS   = $clog2(N);
    localparam IDLE     = 2'd0;             //IDLE STATE
    localparam AD       = 2'd1;             //Address Decode State for Read Operations
    localparam ADWR      = 2'd2;            //Address Decode and Write Decode State for Write Operations
    localparam RD       = 2'd3;             //Read State for Read Operations





    reg [1:0]       state           = IDLE;
    reg [1:0]       next_state;
    reg [ADN-1:0]   AddressReg      = 0;
    reg [N-1:0]     WriteDataReg    = 0;
    reg [N-1:0]     ReadDataReg     = 0;
    reg [N_BITS:0]  counterN        = 0;
    reg [ADN_BITS:0]counterADN      = 0;


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
        case (state)
            IDLE : begin
                if      (validIn && wren)               next_state <= ADWR;
                else if (validIn && ~wren)              next_state <= AD ;
                else                                    next_state <= IDLE;                
            end
            AD: begin
                if ((counterADN == ADN) && ~wren)       next_state <= RD;  
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
        endcase 
    end

    ///////////////////////////////////////////////////////////////////////////////////
    //State Sequencer
    always @(posedge clk) begin
        state <= next_state;
    end
    
    ///////////////////////////////////////////////////////////////////////////////////
    //Output Logic
    always @(posedge clk) begin
        case(state)
            ///////////////////////////////////////////////////////
            IDLE: begin
                ready       <= 1;
                counterADN  <= 0;
                counterN    <= 0;
                AddressReg  <= 0;
                WriteDataReg <= 0;
                ReadDataReg  <= 0;
                DataOut      <= 0;

            end
            ///////////////////////////////////////////////////////
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
            ///////////////////////////////////////////////////////
            ADWR: begin
                if((counterADN < ADN - N) && validIn ) begin
                    AddressReg <= {AddressReg[ADN-2:0],Address};
                    counterADN <= counterADN + 1'b1;
                    ready      <= 0 ;
                    
                end
                else if((counterADN < ADN) && validIn) begin
                    AddressReg <= {AddressReg[ADN-2:0],Address};
                    WriteDataReg <= {WriteDataReg[N-2:0],DataIn};
                    counterN <= counterN + 1'b1;
                    counterADN <= counterADN + 1'b1;
                    ready      <= 0 ;
                end    
                else begin
                    if(counterN == N) begin
                        BRAMmem[AddressReg] <= WriteDataReg;
                        ready      <= 1 ;
                    end
                    else begin
                        AddressReg <= AddressReg;
                        WriteDataReg <= WriteDataReg;     
                        ready      <= 1 ;
                    end    
                end 
            end
            /////////////////////////////////////////////////////////
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
                        DataOut <=0;
                    end
                end               
            end
        endcase     
    end



    
endmodule