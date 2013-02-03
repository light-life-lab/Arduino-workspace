
  ////////////////////////////////////////////////////
  //                                                //
  //   Protocol for Data Transmission to iPhone     //
  //   For Sending Data via Line-in Port            //
  //   ver. B  (Pulse Width Binary Method)          //
  //                                                //
  //   By:   Eddie Bertot & Sam Drazin              //
  //         University of Miami                    //
  //         Music Engineering                      //
  //                                                //
  ////////////////////////////////////////////////////

#include <Wire.h>
#include "nunchuck_funcs.h"

// -----------------------------------------------------------------------
// Data Transmission Methods
// -----------------------------------------------------------------------

#define    sensor1Pin    0
#define    sensor2Pin    1
#define    sensor3Pin    2
#define    sensor4Pin    3
#define    sensor5Pin    4

#define    button1Pin    8
#define    button2Pin    9
#define    outputPin     10

#define    onePulseLength 	280
#define    zeroPulseLength	80
#define    pulseSpacing		400
#define    initLengthMS		6

#define    bitLength            8
#define    lowOutputValue       0
#define    highOutputValue      255//2^bitLength-1

// Parameters to alter the transmitted values
#define    numValuesToSend      3
#define    sendButtonValues     1


const boolean startBit[] = {1};
const int     sigLength = 84;

const int accelXLow = 62;
const int accelXHigh = 200;
const int accelYLow = 65;
const int accelYHigh = 173;
const int accelZLow = 40;
const int accelZHigh = 200;

const int joystickXLow = 20;
const int joystickXHigh = 230;
const int joystickYLow = 20;
const int joystickYHigh = 230;

//Initialize input variables and arrays
byte          accelX, accelY, accelZ, joystickX, joystickY, zButton, cButton;
int           binaryValue1[] = {0, 0, 0, 0, 0, 0, 0, 0};
int           binaryValue2[] = {0, 0, 0, 0, 0, 0, 0, 0};
int           binaryValue3[] = {0, 0, 0, 0, 0, 0, 0, 0};
int           binaryValue4[] = {0, 0, 0, 0, 0, 0, 0, 0};
int           binaryValue5[] = {0, 0, 0, 0, 0, 0, 0, 0};

double        binaryConversionTable[bitLength] = {128,64,32,16,8,4,2,1};

boolean button1, button2;
int sensor1, sensor2, sensor3, sensor4, sensor5;

void setup() {
  
  Serial.begin(19200);//(115200);
  pinMode(outputPin, OUTPUT);
  
  nunchuck_setpowerpins();
  nunchuck_init();
}

void loop() {
  // Read in values from the Wii Nunchuck  
  pollNunchuckData();
  //printNunchuckData();

  //Import button values from pollNunchuckData
  button1 = (boolean)zButton;
  button2 = (boolean)cButton;
  
  //Read the sensor value 0 - 1023 (for debugging: 170 => 10101010)
  //Map the value from 1 - 255 (defined as -> lowOutputValue and highOutputValue, respectively)
  
  if (numValuesToSend >= 1) {
    sensor1 = map((int)accelX, accelXLow, accelXHigh, lowOutputValue, highOutputValue);
  }
  if (numValuesToSend >= 2) {
    sensor2 = map((int)accelY, accelYLow, accelYHigh, lowOutputValue, highOutputValue);
  }
  if (numValuesToSend >= 3) {
    sensor3 = map((int)joystickY, joystickYLow, joystickYHigh, lowOutputValue, highOutputValue);
  }
  if (numValuesToSend >= 4) {
    sensor4 = map((int)joystickX, joystickXLow, joystickXHigh, lowOutputValue, highOutputValue);
  }
  if (numValuesToSend >= 5) {
    sensor5 = map((int)joystickY, joystickYLow, joystickYHigh, lowOutputValue, highOutputValue);
  }
  
  //Convert the values from decimal integers to binary arrays
  for(int i = 0; i < bitLength; i += 1) {

    //First value
    if (numValuesToSend >= 1) {
      if (sensor1 < binaryConversionTable[i]){
        binaryValue1[i] = 0;
      } 
      else {
        binaryValue1[i] = 1;
        sensor1 -= binaryConversionTable[i];  
      }
    }
    //Second value
    if (numValuesToSend >= 2) {
      if (sensor2 < binaryConversionTable[i]) {
          binaryValue2[i] = 0;
      } 
      else {
        binaryValue2[i] = 1;
        sensor2 -= binaryConversionTable[i];  
      }
    }
    //Third value
    if (numValuesToSend >= 3) {
      if (sensor3 < binaryConversionTable[i]) {
        binaryValue3[i] = 0;
      } 
      else {
        binaryValue3[i] = 1;
        sensor3 -= binaryConversionTable[i];  
      }
    }
    //Fourth value
    if (numValuesToSend >= 4) {
      if(sensor4 < binaryConversionTable[i]) {
        binaryValue4[i] = 0;
      }else {
        binaryValue4[i] = 1;
        sensor4 -= binaryConversionTable[i];
      }
    }
    //Fifth value
    if (numValuesToSend >= 5) {
      if(sensor5 < binaryConversionTable[i]) {
        binaryValue5[i] = 0;
      }else {
        binaryValue5[i] = 1;
        sensor5 -= binaryConversionTable[i];
      }
    }
  }
  //end conversion loop; ready for transmission                      
  
  if (numValuesToSend >= 1) {
    valueTransmission(binaryValue1);
  }
  if (numValuesToSend >= 2) {
    valueTransmission(binaryValue2);
  }
  if (numValuesToSend >= 3) {
    valueTransmission(binaryValue3);
  }
  if (numValuesToSend >= 4) {
    valueTransmission(binaryValue4);  
  }
  if (numValuesToSend >= 5) {
    valueTransmission(binaryValue5);
  }

  if (sendButtonValues) {
    buttonValueTransmission(button1);
    buttonValueTransmission(button2);
  }
  
  //Sets the delay (Zero pulse train length)
  delay(initLengthMS);
}

//-----------------------------------------------------
// The button value transmission
void buttonValueTransmission(boolean value) {
  // 1 bit words (no looping, but sends 2 bits for validation)
  //The exit conditions set the width of the pulses    
  if (value) {
      for(int j = 0;j < onePulseLength; j += 1)     {digitalWrite(outputPin,HIGH);}
  } else {
      for(int j = 0; j < zeroPulseLength; j += 1)   {digitalWrite(outputPin,HIGH);}
  }
  
  //Exit condition sets the spacing between pulses
  for(int k = 0; k < pulseSpacing; k += 1) {
    digitalWrite(outputPin,LOW);
  }
}

//------------------------------------------------------
// The sensor value transmission
void valueTransmission(int value[]) {

  for (int i = 0; i < bitLength; i += 1) {
    //The exit conditions set the width of the pulses    
    if (value[i] == 1) {
      for(int j = 0; j < onePulseLength; j += 1)    {digitalWrite(outputPin, HIGH);}
    } 
    else  {
      for(int j = 0; j < zeroPulseLength; j += 1)   {digitalWrite(outputPin, HIGH);}
    }

    //Exit condition sets the spacing between pulses
    for(int j = 0; j < pulseSpacing; j += 1)    {digitalWrite(outputPin, LOW);}
  }
}


// -----------------------------------------------------------------------
// Wii Nunchuck Methods
// -----------------------------------------------------------------------

void pollNunchuckData()
{
  nunchuck_get_data();
  accelX  = nunchuck_accelx(); // ranges from approx 70 - 182
  accelY  = nunchuck_accely(); // ranges from approx 65 - 173
  accelZ  = nunchuck_accelz(); // ranges from approx 65 - 173
  
  zButton = nunchuck_zbutton();  // either 0 or 1
  cButton = nunchuck_cbutton();  // "
      
  joystickX = nunchuck_joyx();    // ranges from approx 20 - 230
  joystickY = nunchuck_joyy();    // 
}



void printNunchuckData()
{
  Serial.print("accelX: "); Serial.print((byte)accelX,DEC);
  Serial.print("\taccelY: "); Serial.print((byte)accelY,DEC);
  Serial.print("\taccelZ: "); Serial.print((byte)accelZ,DEC);
  Serial.print("\tzButton: "); Serial.print((byte)zButton,DEC);
  Serial.print("\tcButton: "); Serial.print((byte)cButton,DEC);
  Serial.print("\tjoystickX: "); Serial.print((byte)joystickX,DEC);
  Serial.print("\tjoystickY: "); Serial.println((byte)joystickY,DEC);
}

