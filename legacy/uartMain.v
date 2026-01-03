`timescale 1ns / 1ps

module uartMain
    #(
        parameter   dataBits = 8,
                    stopTicks = 16,
                    counterBit = 10,
                    counterLimit = 651,
                    addrBits = 4
    )
    (
        input clk,
        input reset,
        input readEn,
        input writeEn,
        input rx,
        input [dataBits - 1:0] dataIn,
        output [dataBits - 1:0] dataOut,
        output rxfifoF,
        output rxfifoE,
        output tx
    );
    
    wire tick, txReady, dataReady, txfifoF, txfifoE;
    wire [dataBits - 1:0] fifototx, rxtofifo;
    
    baudClk
        #(
            .counterBit(counterBit),
            .counterLimit(counterLimit)
        )
        BAUDCLK
        (
            .clk(clk),
            .reset(reset),
            .tick(tick)
        );
    
    uartRx
        #(
            .dataBits(dataBits),
            .stopTicks(stopTicks)
        )
        UARTRX
        (
            .clk(clk),
            .reset(reset),
            .tick(tick),
            .rx(rx),
            .dataReady(dataReady),
            .dataOut(rxtofifo)
        );
    
    uartTx
        #(
            .dataBits(dataBits),
            .stopTicks(stopTicks)
        )
        UARTTX
        (
            .clk(clk),
            .reset(reset),
            .tick(tick),
            .tx(tx),
            .txReady(txReady),
            .dataIn(fifototx),
            .fifoNE(~txfifoE)
        );
    
    fifo
        #(
            .dataBits(dataBits),
            .addrBits(addrBits)
        )
        FIFORX
        (
            .clk(clk),
            .reset(reset),
            .writeEn(dataReady),
            .readEn(readEn),
            .dataIn(rxtofifo),
            .dataOut(dataOut),
            .fifoE(rxfifoE),
            .fifoF(rxfifoF)
        );
        
    fifo
        #(
            .dataBits(dataBits),
            .addrBits(addrBits)
        )
        FIFOTX
        (
            .clk(clk),
            .reset(reset),
            .writeEn(writeEn),
            .readEn(txReady),
            .dataIn(dataIn),
            .dataOut(fifototx),
            .fifoE(txfifoE)
        );
endmodule

