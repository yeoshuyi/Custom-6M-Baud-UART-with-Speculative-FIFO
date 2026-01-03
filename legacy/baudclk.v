module baudClk
    #(
        parameter   counterBit = 10, //Require min 10 bit to store 651
                    counterLimit = 651 //1 tick = 651 clk cycles at 100MHz (i.e. 9600*16 baud rate oversampling)
    )
    (
        input clk,
        input reset,
        output tick
    );
    
    //Init registers
    reg [counterBit - 1:0] counter;
    wire [counterBit - 1:0] nextCounter;
    
    always @(posedge clk or posedge reset)
        begin
            counter <= reset ? 0 : nextCounter;
        end
    
    //If not yet counterLimit, keep adding 1 each clk cycle
    assign nextCounter = (counter == (counterLimit - 1)) ? 0 : counter + 1;
    
    //Output tick goes high when counter is at counterLimit
    assign tick = (counter == (counterLimit - 1)) ? 1'b1 : 1'b0;

endmodule
