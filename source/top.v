`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Yeo Shu Yi 
// 
// Create Date: 01/03/2026 02:22:56 PM
// Design Name: ULL High Throughput 6Mbaud UART Interface with Speculative FWFT BRAM FIFO
// Module Name: top
// Project Name: UART Interface
// Target Devices: Arty-s7 25
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top(
    input reset,
    input CLK100MHZ,
    input uart_rxd_out,
    output [8:0] rxData
    );
    
    wire CLK288MHZ;
    wire baudReset;
    wire rxCommitWrite;
    wire rxWriteEn;
    wire rxRollbackWrite;
    wire rxTick;
    wire [8:0] rxDataFifo;
    wire stable288;
    wire systemReset = reset || !stable288;
    
    freqSynth freqSynthModule
    (
        .CLK100MHZ(CLK100MHZ),
        .reset(reset),
        .CLK288MHZ(CLK288MHZ),
        .stable(stable288)
    );
    
    baudGen rxBaudGen
    (
        .reset(systemReset),
        .baudReset(baudReset),
        .CLK288MHZ(CLK288MHZ),
        .tick(rxTick)
    );
    
    uartRX uartRXModule
    (
        .uart_rxd_out(uart_rxd_out),
        .tick(rxTick),
        .CLK288MHZ(CLK288MHZ),
        .reset(systemReset),
        .baudReset(baudReset),
        .dataOut(rxDataFifo),
        .writeEn(rxWriteEn),
        .commitWrite(rxCommitWrite),
        .rollbackWrite(rxRollbackWrite)
    );
    
    fifo fifoRX
    (
        .writeClk(CLK288MHZ),
        .dataIn(rxDataFifo),
        .writeEn(rxWriteEn),
        .commitWrite(rxCommitWrite),
        .rollbackWrite(rxRollbackWrite),
        .readClk(CLK100MHZ),
        .readEn(1'b1),
        .dataOut(rxData),
        .reset(reset)
    );
    
//    baudGen txBaudGen
//    (
//        .reset(systemReset),
//        .baudReset(1'b0),
//        .CLK288MHZ(CLK288MHZ),
//        .tick(txTick)
//    );
    
endmodule
