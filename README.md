# ULL High-Throughput FPGA-UART Bridge with 0 Latency Speculative-Write BRAM FIFO with Async Clock Domains

## Design Specifications
1) FPGA Board:     Arty-S7
2) UART Baud Rate: 6,000,000Baud (Hardware verified)
3) UART Protocol:  8O1 (1bit Start, 1bit Odd Parity, 1bit Stop)
4) Clock Rate:     288MHz (Via MMCM synthesis) and 100MHz native
5) Sampling Rate:  16x Oversample
6) FIFO Buffer:    BRAM with 4096 depth, 3 Pointer Speculative Write with Rollback, FWFT with CDC
7) Transmitter / Receiver:       Moore FSM

## Hardware Testing
 - An ESP32 is used to output 8O1 at 6M Baud, which is received by the FPGA via JA1. 
 - The FIFO output is sent directly back to the UART transmitter.
 
![alt text](https://github.com/yeoshuyi/Custom-6M-Baud-UART-with-Speculative-FIFO/blob/main/MAP002.BMP "Oscilloscope Reading")
The FPGA transmits ~80ns after the stop-bit is first asserted (immediately when stop-bit is sampled at half-bit) <br/>
![alt text](https://github.com/yeoshuyi/Custom-6M-Baud-UART-with-Speculative-FIFO/blob/main/TestSetup.jpg "Test Setup")
The UART TX/RX buffers assigned to JA1 on the FPGA is directly shorted to the UART TX/RX pins on the ESP32. A simple program is used to ping the FPGA. Output is monitored directly on the oscilloscope.
```C++
void setup() {
  // Laptop Monitor
  Serial.begin(115200); 
  Serial1.begin(BAUD_RATE, SERIAL_8O1, RX_PIN, TX_PIN);
  
  delay(2000);
}

void loop() {
  uint8_t testByte = 0xAB;

  Serial1.write(testByte);
  delay(50b);
}
```
 
 > Currently facing intermittent issues where the same data is re-transmitted. This is likely due to slow update of FIFO not empty flag due to CDC and gray encoding.<br/>

## Current Testbench Timings
### Outdated Timings! Several revisions made after hardware implementation, but I don't plan to rewrite this section.<br/>
 - Worst Negative Slack:   +0.273ns
 - Worst Hold Slack:       +0.114ns
 - End-of-frame to Data:   -58.33ns* <br/>
*Data appears at FIFO before frame even ends using speculative write and middle-of-bit measurement

### Overhead Latency Contributions
 - RX CDC 2-FF Sync:       1.936ns (0.5-1.5 tick at 255MHz Domain)
 - Receiver Moore FSM:     3.473ns (1 tick at 255MHz Domain)
 - FIFO Ptr CDC 2-FF Sync: 20.150ns (1-2 tick at 100MHz Domain) <br/>
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
### Outdated! Several revisions made after hardware implementation, but I don't plan to rewrite this section.<br/>
![alt text](https://github.com/yeoshuyi/Custom-6M-Baud-UART-with-Speculative-FIFO/blob/main/OverallLatency.png "Overall Latency")
> Byte transmission starts at 11,000ns and ends at 12,833ns. Data is ready at the FIFO read by 12,775ns (Immediately after stop bit verification).</br>

![alt text](https://github.com/yeoshuyi/Custom-6M-Baud-UART-with-Speculative-FIFO/blob/main/FFLatency.png "2-FF Async Latency")
> 2-FF Stage to reject metastability contributes to a 1.936ns delay in RX reading. This can potentially reach up to 5.210ns if RX transmission starts right after a negative edge at the 288MHz clock. </br>

![alt text](https://github.com/yeoshuyi/Custom-6M-Baud-UART-with-Speculative-FIFO/blob/main/TimingReport.png "Timing Report")
> WNS and WHS within tolerance, achieved through pipelining and PBLOCK constraints.</br>

![alt text](https://github.com/yeoshuyi/Custom-6M-Baud-UART-with-Speculative-FIFO/blob/main/PowerReport.png "Power Report")

## In-Depth Explanation

### CLK Generation
The onboard 100MHz Crystal is insufficient to oversample the serial UART communication at 6M baud. Thus, a onboard MMCM(PLL) is used to synthesise a 288MHz CLK. Natively, the 288MHz CLK oversamples by x48. A simple counter is used to generate a tick every 3 288MHz clock cycles for 16x oversampling, while sequential logic can still flow at 288MHz. The tick counter is reset upon detection of start bit using a baud reset signal from the receiver, to ensure phase synchronisation with the 2-FF synchronised UART signal.

### UART Receiver
The receiver is modelled as a Moore FSM, which introduces 1 clock cycle of delay for buffering. At the input, the asynchronous UART signal is put through 2-FF synchronisation to eliminate metainstability. This 2-FF system utilizes the IOB and triggers at double edge to reduce latency down to around 0.5 clock cycles. The total overhead latency through the UART receiver is thus around 1.5 clock cycles, as measured in the pictorial above. </br>

Upon detection of start bit, the FSM waits 8 ticks before sampling data at 16 tick intervals, shifting data into the register. Parity calculation is performed with each sample using combinational circuit to remove the clock cycle delay traditionally required at the end of frame to check parity. If Even Parity passes, the FSM outputs a 0 in the 9th bit position in the data register. </br>

Upon detection of the last data bit, the FSM speculatively writes the data onto custom FIFO before checking for stop bit. This removes the clock cycle delay traditionally required to write to BRAM FIFOs after stop bit check. Upon detection of stop bit, the FSM immediately sends a commit or rollback signal to the FIFO.

### Speculative FIFO
The FIFO is designed to use a BRAM of 4096 address depth to provide sufficient space for accumulation should read operation be interrupted. At 6M baud rate, this provides around 7.5ms of accumulation at maximum throughput before hitting full. A 3 pointer design (speculative write, committed write, read) is used to enable speculative writing and rollback to remove input latency. When write enable is first detected, input data is shifted into BRAM, but committed write pointer does not increase until a commit signal is detected. Lookahead using a shadow register bypasses the FIFO to provide first-word-fall-through effect. The combination of speculative write and first-word-fall-through allows the data to be read immediately as soon as committed is asserted. </br>

However, latency still exists due to the crossing of clock domains. The committed write pointer is converted to gray code and passed through a 2-FF synchroniser into the 100MHz clock domain at the read side of the FIFO. This introduces a 2 clock cycle delay to the system, which could potentially be mitigated by having the read side at 288MHz as well.

### UART Transmitter
Nothing special here, similar to how the UART Receiver works. An 8-bit register is used to copy the FIFO read data and assert read enable immediately upon detecting FIFO not empty. By copying the data and triggering read enable early, 
