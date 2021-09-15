module bus_to_uart #(
    parameter MemN = 2,   // Memory Block Size
    parameter N = 8,      // Memory Block Width
    parameter DelayN = 0, // Read delay in clock cycles
    parameter ADN = 12,    // Address Length
    parameter BN = 3    //Burst bit length
) (
    // Input Ports
	input     validIn,wren, reset,
	input     Address,DataIn, BurstEn,
	input     clk,BusAvailable,
    input     uart_busy,end_tx,
    
	

	// Output Ports
    output [3:0] state_out,
    output reg [N-1:0]     WriteDataReg    = 0,
    output reg [N-1:0]  to_uart = 0,
    output reg          tx_external = 0,
    // output [2:0] next_state_out,
    // output [ADN-1:0]   AddressReg_out,
    // output [N-1:0]     WriteDataReg_out,
    // output [N-1:0]     ReadDataReg_out,
    // output [N_BITS:0]  counterN_out,
    // output [ADN_BITS:0]counterADN_out,
    output reg  ready=0,validOut=0, hold=0,
	output reg DataOut=0);


    reg [ N-1 : 0 ] BRAMmem [0 : MemN*1024-1];      //BRAM Block

    localparam ADN_BITS = $clog2(ADN);
    localparam N_BITS   = $clog2(N);
    localparam IDLE     = 4'd0;             //IDLE STATE
    localparam AD       = 4'd1;             //Address Decode State for Read Operations
    localparam ADWR     = 4'd2;            //Address Decode and Write Decode State for Write Operations
    localparam RDWait   = 4'd3;             //Read wait State for Read Operations
    localparam RD       = 4'd4;             //Read State for read operations
    localparam BADWR    = 4'd5;
    localparam BWR      = 4'd6;
    localparam BAD      = 4'd7;
    localparam BRDWait  = 4'd8;
    localparam BRD      = 4'd9;
    localparam TX_UART  = 4'd10;




    reg [3:0]       state           = IDLE;
    reg [3:0]       next_state;
    reg [ADN-1:0]   AddressReg      = 0;
    reg [BN-1:0]    BurstLenReg     = 0;                //register to hold Burst Len   
    reg [N-1:0]     ReadDataReg     = 0;
    reg [N_BITS:0]  counterN        = 0;     
    reg [ADN_BITS:0]counterADN      = 0;
    reg [10:0]      counterDelay    = 0;
    reg [1:0]       counterBN       = 0;                //counter to count burst decode
    reg [9:0]       counterBurst    = 0;                //counter to track burst length
    reg             ext_tx          = 0;                //transmitted the data to uart module


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
        else begin
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
                    if ((counterADN == ADN) && ~wren)       next_state <= RDWait;  
                    else                                    next_state <= AD;
                end
                ADWR: begin
                    if(counterN == N)                       next_state <= TX_UART;
                    else                                    next_state <= ADWR;
                end
                TX_UART: begin
                    if(ext_tx)                              next_state <= IDLE;
                    else                                    next_state <= TX_UART;
                end
                RDWait: begin
                    if((counterDelay < DelayN) || ~BusAvailable) next_state <= RDWait;
                    else                                         next_state <= RD;
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
                    if ((counterADN == ADN))                next_state <= BRDWait;  
                    else                                    next_state <= BAD;                    
                end 
                BRDWait: begin
                    if((counterDelay < DelayN) || ~BusAvailable) next_state <= BRDWait;
                    else                                         next_state <= BRD;
                end
                BRD : begin
                    if(counterBurst[BurstLenReg + 2])       next_state <= IDLE;
                    else if( (counterDelay < DelayN) && ((counterBurst%4)==0) )  next_state <= BRDWait;
                    else                                    next_state <= BRD;      
                end 
            endcase 
        end
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
                // ready        <= 1;
                counterADN   <= 0;
                counterN     <= 0;
                counterDelay <= 0;
                counterBurst <= 0;
                AddressReg   <= 0;
                WriteDataReg <= 0;
                ReadDataReg  <= 0;
                DataOut      <= 0;
                hold         <= 0;
                ext_tx       <= 0;
                tx_external  <= 0;
                if (end_tx)         ready <= 1;
                else                ready <= 0;

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
                    ready      <= 0 ;
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
                        ready      <= 0 ;
                    end
                    else begin
                        AddressReg <= AddressReg;
                        WriteDataReg <= WriteDataReg;     
                        ready      <= 0 ;
                    end    
                end 
            end

            ///////////////////////////////////////////////////////
            TX_UART: begin
                if (~uart_busy) begin
                    tx_external <= 1;
                    to_uart     <= WriteDataReg;
                    ext_tx      <= 1;
                    ready       <= 1;
                end
                else    begin
                    tx_external <= 0;
                    ext_tx      <= 0;
                    ready       <= 0;
                end
            end

            ///////////////////////////////////////////////////////
            RDWait: begin
                
                if((counterDelay < DelayN)) begin
                    counterDelay <= counterDelay + 1'b1;
                    ready        <= 0 ;
                    hold         <= 1 ;
                end    
                else begin
                    ready      <= 1 ;
                    hold       <= 0 ;
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


            ///////////////////////////////////////////////////////
            BRDWait: begin
                
                if((counterDelay < DelayN)) begin
                    counterDelay <= counterDelay + 1'b1;
                    ready        <= 0 ;
                    hold         <= 1 ;
                end    
                else begin
                    ready      <= 1 ;
                    hold       <= 0 ;
                end   
            end


            /////////////////////////////////////////////////////////
            BRD: begin
                if(counterDelay==0 && (counterBurst%4==0)) validOut <= 0;

                else if(~counterBurst[BurstLenReg+2]) begin
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
                            counterDelay <=0;
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