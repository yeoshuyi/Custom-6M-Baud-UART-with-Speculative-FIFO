module fifo
    #(
        parameter   dataBits = 8, //No. of bits per word
                    addrBits = 4 //No. of bits for address (16 address total)
    )
    (
        input clk,
        input reset,
        input writeEn,
        input readEn,
        input [dataBits - 1:0] dataIn,
        output [dataBits -1:0] dataOut,
        output fifoNE,
        output fifoE,
        output fifoF  
    );
    
    //Memory
    reg [dataBits - 1:0] mem [2**addrBits - 1:0]; //Array of 8x16
    reg [addrBits - 1:0] wrAdd, nextWrAdd;
    reg [addrBits - 1:0] rdAdd, nextRdAdd;
    reg fullFIFO, emptyFIFO, fullBuff, emptyBuff;
    
    //Write if not full
    always @(posedge clk) if(writeEn & ~fullFIFO) mem[wrAdd] <= dataIn;
    
    //Data
    assign dataOut = mem[rdAdd];
    
    //Next state assignments
    always @(posedge clk or posedge reset) begin
        
        if(reset) begin
            wrAdd <= 0;
            rdAdd <= 0;
            fullFIFO <= 1'b0;
            emptyFIFO <= 1'b1;
        end
        else begin
            wrAdd <= nextWrAdd;
            rdAdd <= nextRdAdd;
            fullFIFO <= fullBuff;
            emptyFIFO <= emptyBuff;
        end
    end
    
    always @* begin
        
        //Default without case
        nextWrAdd = wrAdd;
        nextRdAdd = rdAdd;
        fullBuff = fullFIFO;
        emptyBuff = emptyFIFO;
        
        case({writeEn, readEn})
        
            2'b00: begin end
            
            2'b01: begin
                if(~emptyFIFO) begin
                    nextRdAdd = rdAdd + 1;
                    fullBuff = 1'b0;
                    
                    if(nextRdAdd == wrAdd) emptyBuff = 1'b1; //Lock out if empty
                end
            end
            
            2'b10: begin
                if(~fullFIFO) begin
                    nextWrAdd = wrAdd + 1;
                    emptyBuff = 1'b0;
                    if(nextWrAdd == rdAdd) fullBuff = 1'b1; //Lock out if full
                end
            end
            
            2'b11: begin
                nextRdAdd = rdAdd + 1;
                nextWrAdd = wrAdd + 1;
            end
        endcase
    end
    
    //Output flags
    assign fifoE = emptyFIFO;
    assign fifoF = fullFIFO;
    assign fifoNE = ~emptyFIFO;
    
endmodule