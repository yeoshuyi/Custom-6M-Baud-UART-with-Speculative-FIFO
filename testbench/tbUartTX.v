`timescale 1ns/1ps

module tbUartTx();

    wire tick;
    reg [1:0] tick_count = 0;
    reg CLK288MHZ;
    reg reset;
    reg [7:0] dataIn;
    reg fifoNE;
    
    wire readEn;
    wire uart_txd_in;
    
    uartTX uut
    (
        .tick(tick),
        .CLK288MHZ(CLK288MHZ),
        .reset(reset),
        .dataIn(dataIn),
        .fifoNE(fifoNE),
        .readEn(readEn),
        .uart_txd_in(uart_txd_in)
    );
    
    initial
    begin
        CLK288MHZ = 0;
        forever # (1.73) CLK288MHZ = ~CLK288MHZ;
    end

    always @(posedge CLK288MHZ or posedge reset) begin
        if (reset) begin
            tick_count <= 0;
        end else begin
            if (tick_count == 2)
                tick_count <= 0;
            else
                tick_count <= tick_count + 1;
        end
    end
    assign tick = (tick_count == 2);
    
    initial
    begin
        fifoNE = 0;
        reset = 1;
        #1000;
        dataIn = 8'b10101100;
        fifoNE = 1'b1;
        reset = 0;
        #4000;
        
        $finish;
    end

endmodule