//Design Specifications:
//Utilise BRAM, 9 bit width, 4096 address
//Utilise FWFT
//3 Pointer system with speculative write and commit from custom UART
//Lookahead for low latency reads
//Clock domain crossing between read/write
//Almost full flag when first 2 of wrPtr and rdPtr equal

module fifo
(
    //Common to Read/Write
    input wire reset,

    //Write
    input wire writeClk,
    input wire [8:0] dataIn,
    input wire writeEn,
    input wire commitWrite,
    input wire rollbackWrite,
//    output wire full,
//    output wire notFull,
    output wire almostFull,
    
    //Read
    input wire readClk,
    input wire readEn,
    output reg [8:0] dataOut,
    output wire empty,
    output wire notEmpty
);

    (* RAM_STYLE = "block" *) reg [8:0] mem [4095:0];
    reg [12:0] wrPtr;   //Speculative Write Pointer
    reg [12:0] comPtr;  //Committed Write Pointer
    reg [12:0] rdPtr;   //Read Pointer
    
    reg [12:0] wrPtrNext;
    reg [12:0] wrPtrGrayNext;
    
    reg [12:0] wrPtrGray;
    reg [12:0] comPtrGray;
    (* ASYNC_REG = "TRUE" *) reg [12:0] comPtrGraySync [1:0];
    wire [12:0] rdPtrGray;
    (* ASYNC_REG = "TRUE" *) reg [12:0] rdPtrGraySync [1:0];
    
    //reg writeEnPipe;
    
    reg [12:0] wrPtrPlus;
    reg [12:0] wrPtrGrayPlus;
    reg [12:0] comPtrPlus;
    reg [12:0] comPtrGrayPlus;
    
    always @(posedge writeClk) 
    begin
        //writeEnPipe <= writeEn;
        
        wrPtrPlus <= wrPtrNext + 1;
        wrPtrGrayPlus <= ((wrPtrNext + 1) >> 1) ^ (wrPtrNext + 1);
        comPtrPlus <= comPtr + 1;
        comPtrGrayPlus <= ((comPtr + 1) >> 1) ^ (comPtr + 1);
        
        if (reset) 
        begin
            wrPtr <= 0;
            wrPtrGray <= 0;
            wrPtrGrayNext <= 13'h0001;
            wrPtrNext <= 1;
            comPtr <= 0;
            comPtrGray <= 0;
        end else
        begin
            if (writeEn && ~almostFull && ~rollbackWrite) 
            begin
                mem[wrPtr[11:0]] <= dataIn;
                
                wrPtr <= wrPtrNext;
                wrPtrGray <= wrPtrGrayNext;
                
                wrPtrNext <= wrPtrPlus;
                wrPtrGrayNext <= wrPtrGrayPlus;
            end
            
            if (commitWrite) begin
                comPtr <= wrPtr;
                comPtrGray <= wrPtrGray;
            end else if (rollbackWrite)
            begin
                wrPtr <= comPtr;
                wrPtrGray <= comPtrGray;
                wrPtrNext <= comPtrPlus;
                wrPtrGrayNext <= comPtrGrayPlus;
            end
        end
    end
    
    always @(posedge readClk)
    begin
        if (reset)
        begin 
            rdPtr <= 0;
            dataOut <= 9'd0;
        end else if (notEmpty)
        begin
            if (readEn)
            begin
                rdPtr <= rdPtr + 1;
            end
            dataOut <= mem[rdPtr[11:0]];    
        end
    end
    
    assign rdPtrGray = (rdPtr >> 1) ^ rdPtr;
    
    always @ (posedge readClk)
    begin
        {comPtrGraySync[1], comPtrGraySync[0]} <= {comPtrGraySync[0], comPtrGray};
    end
    
    always @ (posedge writeClk)
    begin
        {rdPtrGraySync[1], rdPtrGraySync[0]} <= {rdPtrGraySync[0], rdPtrGray};
    end
    
    //ptr[12] is the lap bit
//    assign full = (wrPtrGray == {~rdPtrGraySync[1][12:11], rdPtrGraySync[1][10:0]});
//    assign notFull = ~full;
    
    assign empty = (comPtrGraySync[1] == rdPtrGray);
    assign notEmpty = ~empty;
    
    assign almostFull = (wrPtrGray[12] != rdPtrGraySync[1][12]) &&
                        (wrPtrGray[11] != rdPtrGraySync[1][11]);                     
    
    //assign dataOut = mem[rdPtr[11:0]];

endmodule