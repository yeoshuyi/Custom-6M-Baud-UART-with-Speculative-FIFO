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
        .DIVCLK_DIVIDE(5),      //100MHz/5 = 20MHz
        .CLKFBOUT_MULT_F(43.2), //20MHz*43.2 = 864MHz 
        .CLKOUT0_DIVIDE_F(3.0), //864MHz/3 = 288MHz
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