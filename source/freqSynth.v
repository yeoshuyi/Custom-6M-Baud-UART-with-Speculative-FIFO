module freqSynth
(
    input wire CLK100MHZ,
    input wire reset,
    output wire CLK288MHZ,
    output wire stable
);

    wire unbuffedCLK288MHZ;
    wire fbLoop; //For MMCM
    
    
    MMCME2_ADV
    #(
        .BANDWIDTH("OPTIMIZED"),
        .DIVCLK_DIVIDE(5),    
        .CLKFBOUT_MULT_F(36.0), 
        .CLKOUT0_DIVIDE_F(2.5),
        .CLKFBOUT_PHASE(0.0),
        .CLKIN1_PERIOD(10.0),
        .CLKOUT0_DUTY_CYCLE(0.5),
        .CLKOUT0_PHASE(0.0),
        .STARTUP_WAIT("FALSE")
        
    )
    freqSynthMMCM
    (
        .CLKIN1(CLK100MHZ),
        .CLKOUT0(unbuffedCLK288MHZ),
        .CLKFBOUT(fbLoop),
        .CLKFBIN(fbLoop),
        .PWRDWN(1'b0),
        .RST(reset),
        .LOCKED(stable)
    );
    
    BUFG freqSynthBUFG
    (
        .I(unbuffedCLK288MHZ),
        .O(CLK288MHZ)
    );

endmodule