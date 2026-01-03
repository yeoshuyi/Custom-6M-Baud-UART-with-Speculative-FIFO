module uartTx
    #(
        parameter   dataBits = 8, //No. of data bits within 1 packet
                    stopTicks = 16 //No. of stop bits in ticks
    )
    (
        input clk,
        input reset,
        input tick,
        input [dataBits - 1:0] dataIn,
        input fifoNE, //FIFO memory not empty
        output tx, //To tx line
        output reg txReady //Transmit done
    );

    //Init registers (Same stuff as uartRx)
    reg [1:0] state, nextState;
    reg [3:0] numTick, nextNumTick;
    reg [2:0] numBits, nextNumBits;
    reg [dataBits - 1:0] data, nextData;
    reg txBit, nextTxBit;
    
    //States
    localparam [1:0]    idle = 2'b00,
                        start = 2'b01,
                        trx = 2'b10,
                        stop = 2'b11;
    
    //Next state register assignment
    always @(posedge clk or posedge reset) begin
        if(reset) begin
        //Init Condition
            state <= idle;
            numTick <= 0;
            numBits <= 0;
            data <= 0;
            txBit <= 1'b1; //Active low
        end
        else begin
        //Assign all regs to next state (non-blocking)
            state <= nextState;
            numTick <= nextNumTick;
            numBits <= nextNumBits;
            data <= nextData;
            txBit <= nextTxBit;
        end
     end
    
    //Main Program
    always @* begin
        //By default before each case, no change to next state
        nextState = state;
        nextNumTick = numTick;
        nextNumBits = numBits;
        nextData = data;
        nextTxBit = txBit;
        txReady = 1'b0;
        
        //Each case
        case(state)
        
            //When idle, detect FIFO not empty to transit to start, else output 1 (inactive)
            idle: begin
                nextTxBit = 1'b1; //Pull to high when rest
                if(fifoNE) begin
                    nextState = start;
                    nextNumTick = 0;
                    nextData = dataIn; //Set to data from FIFO
                end
            end
            
            //When start, output low for 1 bit (16 ticks), then go to trx
            start: begin
                nextTxBit = 1'b0; //Active low start bit
                
                if(tick) begin
                    if(numTick < 15) begin
                        nextNumTick = numTick + 1;
                    end
                    else begin
                        nextNumTick = 0;
                        nextState = trx;
                        nextNumBits = 0;
                    end
                end
            end
            
            //When trx, start to output dataIn in series to tx
            trx: begin
                nextTxBit = data[0]; //Transmit LSB of data
                if(tick) begin
                    if(numTick < 15) begin
                        nextNumTick = numTick + 1;
                    end
                    else begin
                        nextNumTick = 0;
                        nextData = data >> 1;
                        if(numBits < dataBits - 1) begin
                            nextNumBits = numBits + 1;
                        end
                        else begin
                            nextNumBits = 0;
                            nextState = stop;
                        end
                    end
                end
            end
            
            //When stop, wait 1 stop bit before returning to idle
            stop: begin
                nextTxBit = 1'b1; //Stop bit
                
                if(tick) begin
                    if(numTick < stopTicks - 1) begin
                        nextNumTick = numTick + 1;
                    end
                    else begin
                        nextState = idle;
                        nextNumTick = 0;
                        txReady = 1'b1;
                    end
                end
            end
            
        endcase
    end
    
    assign tx = txBit;
    
endmodule