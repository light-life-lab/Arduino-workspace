#import <Foundation/Foundation.h>
#include "MUEAudioUnit.h"
#include "Filter.h"

// Describe the data stream expected from the Arduino
#define kNumWords					3
#define kBitsPerWord				8
#define	kSingleBitWords				2
#define kPacketLength				(kNumWords*kBitsPerWord) + (kSingleBitWords)
#define kBufferSize					512
#define kMovingAverageLength		2

/* Endianness declared by arbitrary constant with the following values:
		Little Endian:	1001
		Big Endian:		1002

#define	kLittleEndian				1001
#define kBigEndian					1002
#define kEndianness					kLittleEndian
*/
#define kPulseLengthThreshold		22//20
#define kMinPulseLength				3
#define kPulseThreshold				0.425

#define kInitSequenceLength			250

@class WiiNunchuckAppDelegate;

class SampleAudioUnit : public MUEAudioUnit
{
public:
    SampleAudioUnit();
   ~SampleAudioUnit();

    void	process(float *buffer, int numSamplesPerChannel, int numChannels);
	char	makeAppropriatePulse(int numOnes);
    void	writePulse(char pulse);	
	void	printValues(int wordsReceived, double *valueBuffer[]);
	void	adjustBinaryCounters();
	void	updateValueBuffers(int whichValue, double value);
	void	printStatus();

	float	getParameter(int index);
    void	setParameter(int index, float value);

	WiiNunchuckAppDelegate	*applicationDelegate;
	
	bool					readingBits;

	char					currentBit;
	char					*dataWord;

	int						numBitsRead;	
	int						wordsReceived;
	int						singleBitsReceived;
	int						wordCount;

	int						zeroTrainLength;
	int						oneTrainLength;
	
	double					value1, value2, value3;

	bool					value4, value5;

	int						packetCount;
	
	int						value1count, value2count, value3count, value4count, value5count;
	
	double					*value1Buffer, *value2Buffer, *value3Buffer;
	bool					*value4Buffer, *value5Buffer;

/*
	int		*accelXBuffer;
	char	*accelYBuffer;
	char	*accelZBuffer;
	char	*joystickXBuffer;
	char	*joystickYBuffer;
	char	*zButtonBuffer;
	char	*cButtonBuffer;
	
	int		accelX;
	int		accelY;
	int		accelZ;
	int		joystickX;
	int		joystickY;
	bool	zButton;
	bool	cButton;
*/
protected:
    int					frameCount;
};
