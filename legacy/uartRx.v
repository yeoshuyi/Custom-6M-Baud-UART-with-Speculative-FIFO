module uartRx
    #(
        parameter   dataBits = 8, //No. of data bits enclosed in a packet
                    stopTicks = 16 //Stop bit in ticks (16 per bit)
    )
    (
        input tick,
        input rx,
        input reset,
        input clk,
        output reg dataReady,
        output [dataBits - 1:0] dataOut
    );
    
    //Init Registers
    reg [1:0] state, nextState; //Current rx state (idle, start, rcv, stop)
    reg [3:0] numTick, nextNumTick; //4 bit to represent 16 ticks per read cycle
    reg [2:0] numBits, nextNumBits; //3 bit to represent number of data bits rcved per packet
    reg [dataBits - 1:0] data, nextData; //8 bits to represent data from rx
    
    //States
    localparam [1:0]    idle = 2'b00,
                        start = 2'b01,
                        rcv = 2'b10,
                        stop = 2'b11;
                        
    //Next state register assignment
    always @(posedge clk or posedge reset)
        if(reset) begin
        //Init Condition
            state <= idle;
            numTick <= 0;
            numBits <= 0;
            data <= 0;
        end
        else begin
        //Assign all regs to next state (non-blocking)
            state <= nextState;
            numTick <= nextNumTick;
            numBits <= nextNumBits;
            data <= nextData;
        end
    
    //Main Program
    always @* begin
    
        //By default before each case, no change to next state
        nextState = state;
        nextNumTick = numTick;
        nextNumBits = numBits;
        nextData = data;
        dataReady = 1'b0;
    
        //Each case
        case(state)
        
            //During idle, check for LOW rx, then move to start state
            idle: begin
                if(~rx) begin
                   nextState = start;
                   nextNumTick = 0;
                end
            end
            
            //During start, wait 8 ticks before starting to sample data
            //8 ticks puts it at the middle of the first data bit
            start: begin
                if(tick) begin
                    if(numTick < 7) begin
                        nextNumTick = numTick + 1;
                    end
                    else begin
                        nextState = rcv;
                        nextNumTick = 0;
                        nextNumBits = 0;
                    end
                end
            end
            
            //During rcv, read data every 16 ticks, for 8 bits
            rcv: begin
                if(tick) begin
                    if(numTick < 15) begin
                        nextNumTick = numTick + 1; //Wait 16 ticks
                    end
                    else begin
                        nextNumTick = 0;
                        nextData = {rx, data[7:1]}; //takes data less bit 0, and appends rx to bit 7, effectively making shift register
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
            
            //During stop, wait 1 stopbit (16 ticks) and return to idle
            stop: begin
                if(tick) begin
                    if(numTick < (stopTicks - 1)) begin
                        nextNumTick = numTick + 1; //Wait 16 tick
                    end
                    else begin
                        nextNumTick = 0;
                        nextState = idle;
                        dataReady = 1'b1;
                    end
                end
            end
            
        endcase
    end
    
    assign dataOut = data;
    
endmodule

