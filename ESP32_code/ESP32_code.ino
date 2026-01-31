#define RX_PIN 2
#define TX_PIN 1
#define BAUD_RATE 6000000

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
