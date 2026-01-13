module uartRX
(
    input wire uart_rxd_out,
    input wire tick,
    input wire CLK288MHZ,
    input wire reset,
    output reg baudReset,
    output [8:0] dataOut,
    output reg writeEn,
    output reg commitWrite,
    output reg rollbackWrite
);

    reg [1:0] state, nextState;
    reg [3:0] numTick, nextNumTick;
    reg [3:0] numBits, nextNumBits;
    reg [8:0] data, nextData;
    reg [0:0] parityCount, nextParityCount;
    reg nextBaudReset;
    reg nextWriteEn;
    reg nextCommitWrite;
    reg nextRollbackWrite;
    reg rx, rxSync;
    
    localparam [1:0] idle  = 2'b00,
                     start = 2'b01,
                     rcv   = 2'b10,
                     stop  = 2'b11;
    
    always @ (negedge CLK288MHZ)
    begin
        if (~reset)
        begin
            rxSync <= uart_rxd_out;
        end else
        begin
            rxSync <= 1'b1;
        end
        
    end
    
    always @ (posedge CLK288MHZ)
    begin
        if (reset)
        begin
            state <= idle;
            numTick <= 0;
            numBits <= 0;
            data <= 9'b100000000;
            baudReset <= 0;
            parityCount <= 0;
    
            rx <= 1'b1;
        end else
        begin  
            state <= nextState;
            numTick <= nextNumTick;
            numBits <= nextNumBits;
            data <= nextData;
            baudReset <= nextBaudReset;
            parityCount <= nextParityCount;
            writeEn <= nextWriteEn;
            commitWrite <= nextCommitWrite;
            rollbackWrite <= nextRollbackWrite;
            
            rx <= rxSync;
        end
    end
     
     always @*
    begin
        nextState = state;
        nextNumTick = numTick;
        nextNumBits = numBits;
        nextData = data;
        nextParityCount = parityCount;
        nextBaudReset = 1'b0;
        nextWriteEn = 1'b0;
        nextRollbackWrite = 1'b0;
        nextCommitWrite = 1'b0;
        
        case(state)
        
            idle:
            begin
                if (~rx)
                begin
                    nextState = start;
                    nextNumTick = 0;
                    nextBaudReset = 1;
                end
            end
                
            start:
            begin
                if (tick)
                begin
                    if (numTick == 6)
                    begin
                        nextNumTick = 0;
                        nextState = rcv;
                        nextNumBits = 0;
                        nextParityCount = 0;
                    end else
                    begin
                        nextNumTick = numTick + 1;
                    end
                end
            end
             
            rcv:
            begin
                if (tick)
                begin
                    if (numTick == 15)
                    begin
                        nextNumTick = 0;                                
                        if (numBits == 8) 
                        begin
                            nextData[8] = parityCount ^ rx;
                            nextNumBits = 0;
                            nextState = stop;
                            nextWriteEn = 1'b1; //Speculative write upon reading last bit
                        end else
                        begin
                            nextData[7:0] = {rx, data[7:1]};
                            nextData[8] = data[8];
                            nextParityCount = parityCount ^ rx;
                            nextNumBits = numBits + 1;
                        end
                    end else 
                    begin
                        nextNumTick = numTick + 1;
                    end
                end
            end
                
                stop:
                begin
                    if (tick)
                    begin
                        if (numTick == 15) 
                        begin
                            nextState = idle;
                            nextNumTick = 0;
                            
                            nextCommitWrite = rx ? 1'b1 : 1'b0;
                            nextRollbackWrite = ~nextCommitWrite;
                        end else
                        begin
                            nextNumTick = numTick + 1;
                        end
                end
            end
        endcase
    end
        
    assign dataOut = data;
        
endmodule