`timescale 1ns /1ps

module tbTop();

    reg tbReset;
    reg tbCLK100MHZ;
    reg tb_uart_rxd_out;
    
    wire [8:0] tbRxData;
    
    
    top uut
    (
        .reset(tbReset),
        .CLK100MHZ(tbCLK100MHZ),
        .uart_rxd_out(tb_uart_rxd_out),
        .rxData(tbRxData)
    );
    
    task sendData;
        input [8:0] data;
        input stop;
        
        integer i;
        begin
            tb_uart_rxd_out = 0;
            #166.67;
            
            for(i = 0; i < 9; i = i + 1)
            begin
                tb_uart_rxd_out = data[i];
                #166.67;
            end
            
            tb_uart_rxd_out = stop;
            #166.67;
        end
    endtask
    
    initial 
    begin
        tbCLK100MHZ = 0;
        forever # (5) tbCLK100MHZ = ~tbCLK100MHZ;
    end
    
    initial 
    begin
        
        tb_uart_rxd_out = 1;
        tbReset = 1;
        #2000;
        tbReset = 0;
        #9000;
        
        sendData(9'b100000001,1);
        sendData(9'b100000010,1);
        sendData(9'b100000011,1);
        sendData(9'b100000100,0);
        #2000;
        
        $finish;
    end
    
endmodule