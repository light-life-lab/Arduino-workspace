#include "SampleAudioUnit.h"
#include "AudioBasics.h"
#include <string.h>
#import "WiiNunchuckAppDelegate.h"

// true
// false
#define kShouldAverageBits			0

bool DEBUG							= false;
bool PRINT_FLOATING_POINT_VALUES	= false;		
bool PRINT_BINARY_VALUES			= false;		
bool PRINT_VALUES					= false;

SampleAudioUnit::SampleAudioUnit()
{
    // Initialize any members
	applicationDelegate = nil;
	
	dataWord = (char*)malloc(kPacketLength*sizeof(char));
/*
	accelXBuffer = (int*)malloc(kPacketLength*sizeof(int));
	accelYBuffer = (char*)malloc(kPacketLength*sizeof(char));
	accelZBuffer = (char*)malloc(kPacketLength*sizeof(char));
	joystickXBuffer = (char*)malloc(kPacketLength*sizeof(char));
	joystickYBuffer = (char*)malloc(kPacketLength*sizeof(char));
*/	
	for (int i = 0; i < kPacketLength; i += 1)
	{
		dataWord[i] = '0';
/*
		accelXBuffer[i] = 0;
		accelYBuffer[i] = '0';
		accelZBuffer[i] = '0';
		joystickXBuffer[i] = '0';
		joystickYBuffer[i] = '0';
*/
	}
/*	
	zButtonBuffer = (char*)malloc(kBitLength*sizeof(char));
	cButtonBuffer = (char*)malloc(kBitLength*sizeof(char));
	
	for (int i = 0; i < kBitLength; i += 1)
	{
		zButtonBuffer[i] = '0';
		cButtonBuffer[i] = '0';
	}
*/
	currentBit				= '0';
	
	packetCount				= 0;
	value1count				= 0;
	value2count				= 0;
	value3count				= 0;
	value4count				= 0;
	value5count				= 0;

	value1					= 0;
	value2					= 0;
	value3					= 0;
	value4					= 0;
	value5					= 0;
	
	value1Buffer			= new double[kMovingAverageLength];
	value2Buffer			= new double[kMovingAverageLength];
	value3Buffer			= new double[kMovingAverageLength];
	value4Buffer			= new bool[kMovingAverageLength];
	value5Buffer			= new bool[kMovingAverageLength];
	
	frameCount				= 0;
	zeroTrainLength			= 0;
	oneTrainLength			= 0;
	wordsReceived			= 0;
	singleBitsReceived		= 0;
	wordCount				= 0;
	numBitsRead				= 0;
	
	readingBits				= false;
	
	printf("kInitSequenceLength: %d\n", kInitSequenceLength);
	printf("kPulseLengthThreshold: %d\n", kPulseLengthThreshold);
}

SampleAudioUnit::~SampleAudioUnit()
{
	delete [] value1Buffer;
	delete [] value2Buffer;
	delete [] value3Buffer;
	delete [] value4Buffer;
	delete [] value5Buffer;
	
	free(applicationDelegate);
/*	
	free(accelXBuffer);
	free(accelYBuffer);
	free(accelZBuffer);
	free(joystickXBuffer);
	free(joystickYBuffer);
	free(zButtonBuffer);
	free(cButtonBuffer);
*/
}

float SampleAudioUnit::getParameter(int index)
{
/*
switch(index)
    {
		// Interface for retrieving parameter values
        case kParam1:	return param1Value;
        case kParam2:	return param2Value;
        case kParam3:	return param3Value;
    }
	return 0;
*/
	return 0.0;
}

void SampleAudioUnit::setParameter(int index = 0, float value = 0)
{
/*	switch(index)
    {
	// Setter method for adjusting values of parameters
        case kParam1: 
            param1Value = value;
            break;
	    case kParam2: 
            param2Value = value;
            break;
		case kParam3:
			param3Value = value;
			break;
	}
*/
}

char thresholdFloatingPointToBinaryChar(double inValue)
{
	if (inValue > kPulseThreshold) 
		return '1';
	return '0';
}

int charToInt(char c)
{
	return (int) (c - 48);
}

double binaryStringToDecimal_BigEndian(char *binaryValue, int length)
{
	if (DEBUG) NSLog(@"--binaryStringToDecimal_BigEndian()");
	
	double result = 0;
	int powerOfTwo = length - 1;
	
	for (int i = 0; i < length; i += 1, powerOfTwo -= 1)
	{
		result += (double) charToInt(binaryValue[i])*pow(2, powerOfTwo);
	}
	return result;
}

double binaryStringToDecimal_LittleEndian(char *binaryValue, int length)
{
	double result = 0;
	for (int i = 0; i < length; i += 1)                     
	{
		result += (double) charToInt(binaryValue[i])*pow(2, i);
	}
	
	return result;
}

bool wasErrorPulse(char currentBit, float *buffer, int i)
{
	if (DEBUG) NSLog(@"--wasErrorPulse() with cB: %c and index: %d", currentBit, i);
	
	int  redundantBits = 0;
	
	for (int j = i; j < kBufferSize; j += 1)
	{
		// If the current bit is the same as the next bit...
		if (currentBit == thresholdFloatingPointToBinaryChar((float) -buffer[j+1])) {
			redundantBits += 1;
			
			// As soon as we've seen enough similar bits to be a valid pulse, return false (not an error)
			if (redundantBits > kMinPulseLength)
				return false;
		}
		else {
			if (redundantBits < kMinPulseLength) {
				return true;
			}
			else
				return false;
		}
	}
	//printf("\nwasErrorPulse(): was not caught, CHECK THIS OUT!");
	return false;
}

double bufferAverage(double *buffer, int length)
{
	if (DEBUG) NSLog(@"--bufferAverage()");
	
	double sum = 0;
	for (int i = 0; i < length; i += 1)
		sum += buffer[i];
	return sum/length;
}

bool bufferAverage(bool *buffer, int length)
{
	if (DEBUG) NSLog(@"--bufferAverage()");
	
	int numPositive = 0;
	for (int i = 0; i < length; i += 1)
	{
		if (buffer[i])
			numPositive += 1;
	}
	if (numPositive > length/2)
		return true;
	return false;
}

/*	This function collects all of the calculated values, and stores them in a circular buffer. 
 *  The moving average of the kMovingAverageLength values will then be transmitted to the iPhone's display
 *	as the accurate (average) value being transmitted.  This is an attempt to reduce data noise.
 *
 *  The values are transmitted in the following sequence:
 *
 *	Value	1		2		3		4		5
 *  Bits	8		8		8		1		1
 */
void SampleAudioUnit::updateValueBuffers(int whichValue, double value)
{
	if (DEBUG) NSLog(@"--updateValueBuffers()");
	
	if (PRINT_VALUES) {
		for (int i = 0; i < whichValue-1; i += 1)
			printf("\t\t\t");
		printf("Value_%d: %.0f\n", whichValue, value);
	}
	
	if (whichValue == 1) {
		value1Buffer[value1count%kMovingAverageLength] = value;
		value1count += 1;
		if (value1count >= kMovingAverageLength) {
			value1 = bufferAverage(value1Buffer, kMovingAverageLength);
			[applicationDelegate updateValue:1 withValue:value1];
		}
	}
	else if (whichValue == 2) { 
		value2Buffer[value2count%kMovingAverageLength] = value;
		value2count += 1;
		if (value2count >= kMovingAverageLength) {
			value2 = bufferAverage(value2Buffer, kMovingAverageLength);
			[applicationDelegate updateValue:2 withValue:value2];
		}
	}
	else if (whichValue == 3) {
		value3Buffer[value3count%kMovingAverageLength] = value;
		value3count += 1;
		if (value3count >= kMovingAverageLength) {
			value3 = bufferAverage(value3Buffer, kMovingAverageLength);	
			[applicationDelegate updateValue:3 withValue:value3];
		}
	}
	else if (whichValue == 4) {
		if (kShouldAverageBits) {
			value4Buffer[value4count%kMovingAverageLength] = value;
			value4count += 1;
			if (value4count >= kMovingAverageLength) {
				value4 = bufferAverage((bool *)value4Buffer, kMovingAverageLength);	
				[applicationDelegate updateValue:4 withValue:(bool)value4];
			}
		}	
		else {
			value4 = (bool) value;
			[applicationDelegate updateValue:4 withValue:(bool)value4];
		}
	}
	else if (whichValue == 5) {
		if (kShouldAverageBits) {
			value5Buffer[value5count%kMovingAverageLength] = value;
			value5count += 1;
			if (value5count >= kMovingAverageLength) {
				value5 = bufferAverage((bool *)value5Buffer, kMovingAverageLength);	
				[applicationDelegate updateValue:5 withValue:(bool)value5];
			}		
		}
		else {
			value5 = (bool) value;
			[applicationDelegate updateValue:5 withValue:(bool)value5];
		}
	}
	packetCount += 1;
}

void SampleAudioUnit::writePulse(char pulse)
{
	if (DEBUG) NSLog(@"--writePulse()");

	char currentWord[kBitsPerWord];
	double value;
	
	// If a complete data packet has not yet been received...
	if (numBitsRead < kPacketLength) {
		dataWord[numBitsRead] = pulse;
		numBitsRead += 1;
	}
	else {
		for (int i = 0, j = 0; i < kPacketLength; i += 1, j += 1) {
			currentWord[j] = dataWord[i];
			
			// If we've received all of the 8 bit words, get ready to extract the next two bits (single bit values)
			if (wordsReceived >= kNumWords && kSingleBitWords > 0) {
				updateValueBuffers(wordsReceived+(singleBitsReceived+1), (dataWord[i] == '1'));
				singleBitsReceived += 1;
			}
			
			//else 
			if ((j+1) == kBitsPerWord) {
				value = binaryStringToDecimal_BigEndian(currentWord, kBitsPerWord);		
				
				if (PRINT_VALUES) {
					for (int x = 0; x < kBitsPerWord; x += 1)
						printf("%c", currentWord[x]);
					printf("\t\t");
				}
				
				wordsReceived += 1;
				wordCount += 1;

				// Sends the computed value to a buffer containing the past kMovingAverageLength values for that word
				updateValueBuffers(wordsReceived, value);
				
				j = -1;
			}
		}
		numBitsRead = 0;
		
		// Expexts a span of zeros >= length of kInitSequenceLength to begin each packet, hence: 
		// only sets readingBits to false when a complete packet has been read
		
		if (wordsReceived == kNumWords && singleBitsReceived == kSingleBitWords) {
			readingBits = false;
			wordsReceived = 0;
			singleBitsReceived = 0;
		}
	}

}

char SampleAudioUnit::makeAppropriatePulse(int numOnes)
{
	if (DEBUG) NSLog(@"--makeAppropriatePulse()");
	
	if (numOnes < kPulseLengthThreshold) {
		return '0';
	}
	else if (numOnes >= kPulseLengthThreshold) {
		return '1';
	}
	return '!';
}

void SampleAudioUnit::adjustBinaryCounters()
{
	if (currentBit == '0') {
		zeroTrainLength += 1;
		oneTrainLength = 0;
	}
	else if (currentBit == '1') {
		oneTrainLength += 1;
		zeroTrainLength = 0;
	}	
}

void SampleAudioUnit::process(float* buffer, int numSamplesPerChannel, int numChannels)
{
	if (DEBUG) NSLog(@"--process()");
	
	int i;
	char pulse;
//	bool foundError = false;
	
	for(i = 0; i < kBufferSize; i += 1)	/*numSamplesPerChannel*numChannels+1*/
	{
		currentBit = thresholdFloatingPointToBinaryChar((float) -buffer[i]);
		
		if (PRINT_BINARY_VALUES)				printf("%c", currentBit);
		else if (PRINT_FLOATING_POINT_VALUES)	printf("%f\n", (float)  -buffer[i]);		

		// If the current bit is the first '1' after a train of zeros (or if we are reading mid-word)
		if ((currentBit == '1' && zeroTrainLength > oneTrainLength) || readingBits) {
/*
			// Error checking for inadequate pulse
			if (!readingBits && wasErrorPulse(currentBit, buffer, i)) {
				foundError = true;
				continue;
			}
*/			
			if ((zeroTrainLength > kInitSequenceLength) || readingBits) {
				readingBits = true;

				if ((currentBit == '0') && (oneTrainLength > zeroTrainLength) && (oneTrainLength > kMinPulseLength)) {
					pulse = makeAppropriatePulse(oneTrainLength);
					writePulse(pulse);
				}
			}
		}

//		if (!foundError) {
		adjustBinaryCounters();
//		}
//		foundError = false;
		
		// Throw out data after finished processing, after all, this isn't audio that we want to listen to
		buffer[i] = 0;
	}
	
	if (PRINT_BINARY_VALUES)	printf("\n\n");

	frameCount += 1;
	if (frameCount % 1000 == 0)
		printf("----------- Processed %dk frames\n", frameCount/1000);
 }

void SampleAudioUnit::printStatus()
{
	printf("\n----- Status of Members -----");
	printf("\n currentBit:    %c", currentBit);
	printf("\n numBitsRead:   %d", numBitsRead);
	printf("\n wordsReceived: %d", wordsReceived);
	printf("\n wordCount:     %d", wordCount);
	printf("\n-----------------------------");
}
