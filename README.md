# ULL High-Throughput FPGA-UART Bridge with Speculative BRAM FIFO

_Design Specifications_
FPGA Board:     Arty-S7
UART Baud Rate: 6,000,000Baud
UART Protocol:  8P1 (1bit Start, 1bit Stop)
Clock Rate:     Use 100MHz On-board CLK to synthesis 288MHz CLK with MMCM
Sampling Rate:  16x Oversample
FIFO Buffer:    BRAM with 4096Addr, 3 Pointer Speculative Write with Rollback, FWFT with CDC

_Low Latency Optimization_
1) Double-edge detection to cut down 2FF input buffer to 1.5ticks delay
2) ULL write-to-read FIFO using speculative write, FWFT and almostFull
  2a) Speculative write to send data to FIFO when last data bit is read, and immediately commit when stop bit is validated using combinational logic
  2b) FWFT to ensure data appears on read side of FIFO when commit is asserted
  2c) almostFull flag to allow for burst read/writes
3) Synthesised 288MHZ Clk to reduce tick cycle
4) Calculated parity bits concurently with each data bit read using XOR, to mitigate parity bit check delay
5) PBLOCK and usage of pipeline techniques to hit timing constraints
6) Lookahead registers to reduce logical negative slack in clocked blocks

_Error Mitigation_
1) Parity check flag is appended to output data from UART RX
2) Stop bit detection either asserts commit or rollback to speculatively written FIFO
3) 2FF buffer on all CDC / Async inputs, between RX pin and UART RX, and between FIFO clock domains
4) 288MHz Clk specifically chosen to mitigate framing error at 6Mbaud
5) 4096addr deep FIFO to allow for >7ms accumulation at max throughput (6M Baud)

_Current Implementation Timings_
Worst Negative Slack:   +0.045ns
Worst Hold Slack:       +0.130ns

_Updates_
Currently only implemented receiver HDL and met implementation time constraints, have not tested on Arty-S7
