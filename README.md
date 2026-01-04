# ULL High-Throughput FPGA-UART Bridge with Speculative BRAM FIFO

## Design Specifications
1) FPGA Board:     Arty-S7
2) UART Baud Rate: 6,000,000Baud
3) UART Protocol:  8P1 (1bit Start, 1bit Stop)
4) Clock Rate:     Use 100MHz On-board CLK to synthesis 288MHz CLK with MMCM
5) Sampling Rate:  16x Oversample
6) FIFO Buffer:    BRAM with 4096Addr, 3 Pointer Speculative Write with Rollback, FWFT with CDC
7) Receiver:       Moore FSM

## Current Testbench Timings
 - Worst Negative Slack:   +0.273ns
 - Worst Hold Slack:       +0.114ns
 - End-of-frame to Data:   -58.33ns*
*Data appears at FIFO before frame even ends using speculative write and middle-of-bit measurement

### Overhead Latency Contributions
 - RX CDC 2-FF Sync:       1.936ns (0.5 tick at 255MHz Domain)
 - Receiver Moore FSM:     3.473ns (1 tick at 255MHz Domain)
 - FIFO Ptr CDC 2-FF Sync: 20.150ns (2 tick at 100MHz Domain)
Further optimization will prove difficult due to 2-FF limitations. <br/>
Possible optimization by switching to Meanly FSM.

## Low Latency Optimization
1) Double-edge detection to cut down 2FF input buffer to 1.5ticks delay
2) FIFO uses speculative write, FWFT and lookahead for 0 latency writes (Data ready as soon as commit)
  - Speculative write to send data to FIFO when last data bit is read, and immediately commit when stop bit is validated using combinational logic
  - FWFT using shadow registers to ensure data appears on read side of FIFO when commit is asserted
  - almostFull flag to allow for burst read/writes
3) Synthesised 288MHZ Clk to reduce tick cycle
4) Calculated parity bits concurently with each data bit read using XOR, to mitigate parity bit check delay
5) PBLOCK and usage of pipeline techniques to hit timing constraints
6) Lookahead registers to reduce logical negative slack in clocked blocks

## Error Mitigation
1) Parity check flag is appended to output data from UART RX
2) Stop bit detection either asserts commit or rollback to speculatively written FIFO
3) 2FF buffer on all CDC / Async inputs, between RX pin and UART RX, and between FIFO clock domains
4) 288MHz Clk specifically chosen to mitigate framing error at 6Mbaud
5) 4096addr deep FIFO to allow for >7ms accumulation at max throughput (6M Baud)

## Pictorials
To be added

## Updates
> Timing constraints and logic verified on testbench, have not tested on hardware
