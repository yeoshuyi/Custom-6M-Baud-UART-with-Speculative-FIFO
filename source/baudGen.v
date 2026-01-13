module baudGen
(
    input wire reset,
    input wire baudReset,
    input wire CLK288MHZ,
    output reg tick
);

reg [1:0] counter;
reg [1:0] nextCounter;
reg [0:0] nextTick;

always @ (posedge CLK288MHZ or posedge baudReset)
    begin
        if (reset || baudReset)
        begin
            tick <= 1'b0;
            counter <= 2'd0;
        end else
        begin
            tick <= nextTick;
            counter <= nextCounter;
        end
    end

always @*
    begin
        if (counter == 2'd2)
        begin
            nextCounter = 2'd0;
        end else
        begin
            nextCounter = counter + 2'd1;
        end
        if (counter == 2'd0)
        begin
            nextTick = 1'b1;
        end else
        begin
            nextTick = 1'b0;
        end
    end

endmodule