module uartTX
(
    input wire tick,
    input wire CLK288MHZ,
    input wire reset,
    input wire [8:0] dataIn,
    input wire fifoNE,
    output reg readEn,
    output wire uart_txd_in
);
    
    reg [1:0] state, nextState;
    reg [3:0] numTick, nextNumTick;
    reg [3:0] numBits, nextNumBits;
    reg [0:0] parityCount, nextParityCount;
    reg nextReadEn;
    reg tx, nextTx;

    localparam [1:0]    idle = 2'b00,
                        start = 2'b01,
                        txd = 2'b10,
                        stop = 2'b11;
                        
    always @ (posedge CLK288MHZ)
    begin
        if(reset)
        begin
            state <= idle;
            numTick <= 0;
            numBits <= 0;
            tx <= 1'b1;
            parityCount <= 0;
            readEn <= 0;
        end else
        begin
            state <= nextState;
            numTick <= nextNumTick;
            numBits <= nextNumBits;
            tx <= nextTx;
            parityCount <= nextParityCount;
            readEn <= nextReadEn;
        end
    end
    
    always @*
    begin
        nextState = state;
        nextNumTick = numTick;
        nextNumBits = numBits;
        nextTx = tx;
        nextParityCount = parityCount;
        nextReadEn = readEn;
        
        case(state)
        
            idle:
            begin
                nextTx = 1'b1;
                
                if(fifoNE)
                begin
                    nextState = start;
                    nextNumTick = 0;
                end
            end
            
            start:
            begin
                nextTx = 1'b0;
                if(tick)
                begin
                    if(numTick == 15)
                    begin
                        nextState = txd;
                        nextNumTick = 0;
                        nextNumBits = 0;
                    end else
                    begin
                        nextNumTick = numTick + 1;
                        nextTx = dataIn[0];
                        nextParityCount = dataIn[0];
                    end
                end    
            end
            
            txd:
            begin
                if(tick)
                begin
                    if(numTick == 15)
                    begin
                        if(numBits == 7)
                        begin
                            nextState = stop;
                            nextNumTick = 0;
                            nextNumBits = 0;
                            nextTx = parityCount;
                            nextReadEn = 1'b1;
                        end else
                        begin
                            nextNumBits = numBits + 1;
                            nextParityCount = dataIn[numBits + 1] ^ parityCount;
                            nextTx = dataIn[numBits + 1];
                        end
                    end else
                    begin
                        nextNumTick = numTick + 1;
                    end
                end
            end
            
            stop:
            begin
                if(tick)
                nextReadEn = 0;
                begin
                    if(numTick > 15) nextTx = 1'b1;
                    if(numTick == 31)
                    begin
                        if(fifoNE) nextState = start;
                        else nextState = idle;
                        nextNumTick = 0;
                    end else
                    begin
                        nextNumTick = numTick + 1;
                    end
                end
            end
            
        endcase
    end
    
    assign uart_txd_in = tx;

endmodule

