/* 
 *  Chromatic AquaTube v. 1.0.0
 *  Written by Will Powers
 */
#include <ArduinoBLE.h>

uint8_t initialColor[3] = { 0, 128, 255 };

BLEService deviceService("19B10010-E8F2-537E-4F6C-D104768A1214");

// Define the characteristic UUIDs
BLECharacteristic colorWheelCharacteristic("19B10011-E8F2-537E-4F6C-D104768A1214", BLEWrite, 3, false);
BLECharacteristic colorCommandCharacteristic("19B10012-E8F2-537E-4F6C-D104768A1214", BLEWrite, 1, false);

int redPin = D3;    // Red LED 
int greenPin = D5;    // Green LED
int bluePin = D6;    // Blue LED

// Event listeners
void onColorWheelWrite(BLEDevice central, BLECharacteristic characteristic) {
  // Handle the event when characteristic is written
  uint8_t* combinedValue = (uint8_t*)characteristic.value();
  setColor(combinedValue);
}

void onColorCommandWrite(BLEDevice central, BLECharacteristic characteristic) {
  // Handle the event when characteristic is written
  uint8_t* value = (uint8_t*)characteristic.value();

  switch (value[0]) {
    case 0:
      setColor(0, 0, 0);
    break;
    case 5:
      setColor(0, 128, 255);
    break;
  }
}

void setColor(uint8_t red, uint8_t green, uint8_t blue) {
  analogWrite(redPin, red);
  analogWrite(greenPin, green);
  analogWrite(bluePin, blue);
}

void setColor(uint8_t rgb[]) {
  analogWrite(redPin, rgb[0]);
  analogWrite(greenPin, rgb[1]);
  analogWrite(bluePin, rgb[2]);
}

void setup()  {
   // sets the pins as output
   pinMode(redPin, OUTPUT);
   pinMode(greenPin, OUTPUT);
   pinMode(bluePin, OUTPUT);

   setColor(initialColor);
   
   if (!BLE.begin()) {
      // Serial.println("* Starting Bluetooth® Low Energy module failed!");
      while (1);
   }

   // 20 characters max
   BLE.setLocalName("AquaTube (Playroom)");

   // Set the event listeners for characteristics
   colorWheelCharacteristic.setEventHandler(BLEWritten, onColorWheelWrite);
   colorCommandCharacteristic.setEventHandler(BLEWritten, onColorCommandWrite);

   BLE.setAdvertisedService(deviceService);
   
   // Add characteristics to the service
   deviceService.addCharacteristic(colorWheelCharacteristic);
   deviceService.addCharacteristic(colorCommandCharacteristic);

   // 20 characters max
   BLE.setDeviceName("AquaTube (Playroom)");
   BLE.addService(deviceService);
   BLE.advertise(); // Start advertising the service
}

void loop()  {
  BLE.poll();  
}
