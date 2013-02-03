#include <FastSPI_LED.h>

//#define NUM_LEDS 150
#define NUM_LEDS 144
// Sometimes chipsets wire in a backwards sort of way
struct CRGB { unsigned char b; unsigned char r; unsigned char g; };
// struct CRGB { unsigned char r; unsigned char g; unsigned char b; };
struct CRGB *leds;

#define PIN 7

void setup()
{
  //TODO
  //set number of LEDS by type and quantity of module(s)
    FastSPI_LED.setLeds(NUM_LEDS);
    //FastSPI_LED.setChipset(CFastSPI_LED::SPI_SM16716);
    FastSPI_LED.setChipset(CFastSPI_LED::SPI_TM1809);
    //FastSPI_LED.setChipset(CFastSPI_LED::SPI_LPD6803);
    //FastSPI_LED.setChipset(CFastSPI_LED::SPI_HL1606);
    //FastSPI_LED.setChipset(CFastSPI_LED::SPI_595);
    //FastSPI_LED.setChipset(CFastSPI_LED::SPI_WS2801);
  
    FastSPI_LED.setPin(PIN);
    
    FastSPI_LED.init();
    FastSPI_LED.start();
  
    leds = (struct CRGB*)FastSPI_LED.getRGBData(); 
  //TODO
  //set map of LEDS by orientation or configuration of module(s)
  //4-dimensional array
  
  //[index][r][g][b]
  
  //target SD card
  
  //create buffer
  
  //load buffer with pattern indexes in SD card
  
  //read and send pattern data to controller
  
  //read and send palette data to controller
  
  //set pointer to starting frame in starting pattern
  
  //create FPS
  
  //create controller I/O
}

void loop() { 
  
  //read frame at current pointer
  
  //read target groups in frame and set to LED map
  
  //read current palette and assign colors by target groups to LED map
  
  //read FPS
  
  //set each LED color by LED map
    /*
    for(int i = 0 ; i < NUM_LEDS; i++ ) {
        memset(leds, 0, NUM_LEDS * 3);
        leds[i].r = rMap[i];
        leds[i].g = gMap[i];
        leds[i].b = bMap[i];
    }
    FastSPI_LED.show();
    delay(fps);
    */
    
    //send pointer data to controller
    
    //record output to SD card
    
  //end of frame
    //delay(fps);
  
  /*
  // one at a time
  for(int j = 0; j < 3; j++) { 
    for(int i = 0 ; i < NUM_LEDS; i++ ) {
      memset(leds, 0, NUM_LEDS * 3);
      switch(j) { 
        case 0: leds[i].r = 255; break;
        case 1: leds[i].g = 255; break;
        case 2: leds[i].b = 255; break;
      }
      FastSPI_LED.show();
      delay(10);
    }
  }

  // growing/receeding bars
  for(int j = 0; j < 3; j++) { 
    memset(leds, 0, NUM_LEDS * 3);
    for(int i = 0 ; i < NUM_LEDS; i++ ) {
      switch(j) { 
        case 0: leds[i].r = 255; break;
        case 1: leds[i].g = 255; break;
        case 2: leds[i].b = 255; break;
      }
      FastSPI_LED.show();
      delay(10);
    }
    for(int i = NUM_LEDS-1 ; i >= 0; i-- ) {
      switch(j) { 
        case 0: leds[i].r = 0; break;
        case 1: leds[i].g = 0; break;
        case 2: leds[i].b = 0; break;
      }
      FastSPI_LED.show();
      delay(1);
    }
  }
  
  // Fade in/fade out
  for(int j = 0; j < 3; j++ ) { 
    memset(leds, 0, NUM_LEDS * 3);
    for(int k = 0; k < 256; k++) { 
      for(int i = 0; i < NUM_LEDS; i++ ) {
        switch(j) { 
          case 0: leds[i].r = k; break;
          case 1: leds[i].g = k; break;
          case 2: leds[i].b = k; break;
        }
      }
      FastSPI_LED.show();
      delay(3);
    }
    for(int k = 255; k >= 0; k--) { 
      for(int i = 0; i < NUM_LEDS; i++ ) {
        switch(j) { 
          case 0: leds[i].r = k; break;
          case 1: leds[i].g = k; break;
          case 2: leds[i].b = k; break;
        }
      }
      FastSPI_LED.show();
      delay(3);
    }
  }
  */
}

