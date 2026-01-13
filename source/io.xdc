set_property -dict { PACKAGE_PIN R2    IOSTANDARD SSTL135 } [get_ports { CLK100MHZ }]; #IO_L12P_T1_MRCC_34 Sch=ddr3_clk[200] 
create_clock -add -name sys_clk_pin -period 10.000 -waveform {0 5.000}  [get_ports { CLK100MHZ }]; 

set_clock_groups -asynchronous \
    -group [get_clocks -include_generated_clocks unbuffedCLK288MHZ] \
    -group [get_clocks -include_generated_clocks sys_clk_pin]

set_property -dict { PACKAGE_PIN R12   IOSTANDARD LVCMOS33 } [get_ports { uart_rxd_out }]; #IO_25_14 Sch=uart_rxd_out 
set_property IOB TRUE [get_cells -hierarchical *rxSync_reg*];

set_max_delay -from [get_cells -hierarchical *wrPtrGray_reg*] \
              -to [get_cells -hierarchical *comPtrGraySync_reg[0]*] 3.47 -datapath_only
              
set_property MAX_FANOUT 5 [get_cells -hierarchical *writeEn_reg*]

create_pblock pblock_UART_FIFO
add_cells_to_pblock [get_pblocks pblock_UART_FIFO] [get_cells -hierarchical fifoRX]
add_cells_to_pblock [get_pblocks pblock_UART_FIFO] [get_cells -hierarchical uartRXModule]
resize_pblock [get_pblocks pblock_UART_FIFO] -add {SLICE_X10Y10:SLICE_X20Y30}

              
#set_property -dict { PACKAGE_PIN V12   IOSTANDARD LVCMOS33 } [get_ports { uart_txd_in }]; #IO_L24N_T3_A00_D16_14 Sch=uart_txd_in 

set_property -dict { PACKAGE_PIN G15   IOSTANDARD LVCMOS33 } [get_ports { reset }]; #IO_L18N_T2_A23_15 Sch=btn[0] 