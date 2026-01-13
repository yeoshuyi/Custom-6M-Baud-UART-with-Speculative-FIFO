`timescale 1ns / 1ps

module tbFifo();

    reg CLK288MHZ;
    reg [8:0] rxDataFifo;
    reg rxWriteEn;
    reg rxCommitWrite;
    reg rxRollbackWrite;
    reg CLK100MHZ;
    reg reset;
    
    wire [8:0] rxData;

    fifo uut
    (
        .reset(reset),
        .writeClk(CLK288MHZ),
        .dataIn(rxDataFifo),
        .writeEn(rxWriteEn),
        .commitWrite(rxCommitWrite),
        .rollbackWrite(rxRollbackWrite),
        .readClk(CLK100MHZ),
        .readEn(1'b1),
        .dataOut(rxData)
    );
    
    initial 
    begin
        CLK100MHZ = 0;
        forever # (5) CLK100MHZ = ~CLK100MHZ;
    end
    
    initial 
    begin
        CLK288MHZ = 0;
        forever # (1.736) CLK288MHZ = ~CLK288MHZ;
    end
    
    initial
    begin
        reset = 0;
        #10;
        reset = 1;
        #10;
        reset = 0;
        #10;
        
        rxWriteEn = 0;
        rxCommitWrite = 0;
        rxRollbackWrite = 0;
        rxDataFifo = 9'b100011000;
        
        #100;
        rxWriteEn = 1;
        #2;
        rxWriteEn = 0;
        
        rxDataFifo = 9'b101100100;
        #98;
        rxCommitWrite = 1;
        #2;
        rxCommitWrite = 0;
        
        #99;
        rxWriteEn = 1;
        #2;
        rxWriteEn = 0;
        
        #99;
        rxCommitWrite = 1;
        #2;
        rxCommitWrite = 0;
        
        
    end

endmodule
