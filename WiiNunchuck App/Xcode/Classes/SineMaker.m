#import "SineMaker.h"
#include "AudioToolbox/AudioToolbox.h"

#define BUFFERS				3
#define pi					acos(-1.0)
#define degreesToRadians(x) (M_PI * x / 180.0)
#define sampleRate			44100.0

// Callback info struct -- holds the queue and the buffers and some other stuff for the callback
typedef struct AQCallbackStruct {
	AudioQueueRef					queue;
	UInt32							frameCount;
	AudioQueueBufferRef				mBuffers[BUFFERS];
	AudioStreamBasicDescription		mDataFormat;
} AQCallbackStruct;

// Synth params
int		phaseL				= 0;
int		phaseR				= 0;
float	FreqL				= 200;
float	FreqR				= 200;
float	FL					= 0;
float	FR					= 0;
float	amp					= 0.8;
BOOL	stopAudio			= NO;

float	volumeLevel			= 0.85;

/*
** Parameters for tremolo effect
**		tremGain:			current gain applied to the output sample
**		tremGainDepth:		the max/min allowable value of tremGain
**		tremGainInterval:	the value by which tremGain will increment/decrement
**		tremDirection:		indicates the direction the tremolo is currently incrementing
**							YES:	incrementing
**							NO:		decrementing
*/
double	tremGain			= 0.0;
double	tremGainDepth		= 0.1;
double	tremGainInterval	= 0.02;
double	tremDirection		= NO;


// Synthesis callback. Make the music happen...
static void AQBufferCallback(void *	in,	AudioQueueRef inQ, AudioQueueBufferRef	outQB) {
	int i;
	UInt32 err;
	
	// Get the info struct and a pointer to our output data
	AQCallbackStruct * inData = (AQCallbackStruct *)in;
	short *coreAudioBuffer = (short*) outQB->mAudioData;
	
	// if we're being asked to render
	if (inData->frameCount > 0) {
		// Need to set this
		outQB->mAudioDataByteSize = 4*inData->frameCount; // two shorts per frame, one frame per packet
		// For each frame/packet (the same in our example)
		for(i = 0; i < inData->frameCount*2; i += 2) {
			
			// Render the sine waves - signed interleaved shorts (-32767 -> 32767), 16 bit stereo
			float sampleL = (amp * sin(FL * (float)phaseL));
			//float sampleL = (amp * (float)rand()/RAND_MAX);
			float sampleR = (amp * sin(FR * (float)phaseR));
			
			short sampleIL = (int)(sampleL * 32767.0);
			short sampleIR = (int)(sampleR * 32767.0);
			coreAudioBuffer[i] =   sampleIL;
			coreAudioBuffer[i+1] = sampleIR;
			phaseL++; phaseR++;
		}
		// "Enqueue" the buffer
		AudioQueueEnqueueBuffer(inQ, outQB, 0, NULL);
	} else {
		err = AudioQueueStop(inData->queue, false);
	}
}

@implementation SineMaker

- (void)playSineWave {
	if (isPlaying)
		return;
	
	isPlaying = YES;
	stopAudio = NO;
	
	UInt32 err;
	int i;
	AQCallbackStruct in;
	
	// 2 sine waves
	FL = (2.0 * pi * FreqL) / sampleRate;
	FR = (2.0 * pi * FreqR) / sampleRate;
	
	// Set up our audio format 
	in.mDataFormat.mSampleRate = sampleRate;
	in.mDataFormat.mFormatID = kAudioFormatLinearPCM;
	in.mDataFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger  | kAudioFormatFlagIsPacked;
	in.mDataFormat.mBytesPerPacket = 4;
	in.mDataFormat.mFramesPerPacket = 1; // this means each packet in the AQ has two samples, one for each channel -> 4 bytes/frame/packet
	in.mDataFormat.mBytesPerFrame = 4;
	in.mDataFormat.mChannelsPerFrame = 2;
	in.mDataFormat.mBitsPerChannel = 16;
	
	// Set up the output buffer callback on the current run loop
	err = AudioQueueNewOutput(&in.mDataFormat, AQBufferCallback, &in, CFRunLoopGetCurrent(), kCFRunLoopCommonModes, 0, &in.queue);
	if(err) fprintf(stderr, "AudioQueueNewOutput err %d\n", err);
	
	// Set the size and packet count of each buffer read. (e.g. "frameCount")
	in.frameCount = 1024;
	// Byte size is 4*frames (see above)
	UInt32 bufferBytes  = in.frameCount * in.mDataFormat.mBytesPerFrame;
	
	// alloc how ever many buffers.
	for (i=0; i<BUFFERS; i++) {
		err = AudioQueueAllocateBuffer(in.queue, bufferBytes, &in.mBuffers[i]);
		if(err) fprintf(stderr, "AudioQueueAllocateBuffer [%d] err %d\n",i, err);
		// "Prime" by calling the callback once per buffer
		AQBufferCallback (&in, in.queue, in.mBuffers[i]);
	}	
	
	// set the volume of the queue -- note that the volume knobs on the ipod also change this
	err = AudioQueueSetParameter(in.queue, kAudioQueueParam_Volume, 1.0);
	if(err) fprintf(stderr, "AudioQueueSetParameter err %d\n", err);
	
	// Start the queue
	err = AudioQueueStart(in.queue, NULL);
	if(err) fprintf(stderr, "AudioQueueStart err %d\n", err);
	
	// Hang around forever...
	int sampleIndex = 0;
	while(YES) {
		if (stopAudio == YES) {
			break;
		}
		if (tremGain > tremGainDepth || tremGain < -tremGainDepth) {
			tremDirection = !tremDirection;
		}
		if (tremDirection) {
			tremGain += tremGainInterval;
		}
		else {
			tremGain -= tremGainInterval;
		}
		//		printf("tremGain: %.2f\tand volumeLevel: %.2f\n", tremGain, volumeLevel);
		
		err = AudioQueueSetParameter(in.queue, kAudioQueueParam_Volume, volumeLevel+tremGain);
		if(err) fprintf(stderr, "AudioQueueSetParameter err %d\n", err);
		
		CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.01, false);	//.25
		sampleIndex += 1;
	}
	
	// This is how you kill it... if you so choose to do so
	err = AudioQueueDispose(in.queue, true);
}

- (void)stopSineWave {	
	stopAudio = YES;
	isPlaying = NO;
}

-(void)changeTremDepth:(double)value{
	tremGainDepth = value;
}

-(void)changeTremSpeed:(double)value{
	tremGainInterval = value;
}

-(void)changePitch:(double)value {
	FreqL = value;
	
	if (FreqL > kMaxFrequency)
		FreqL = kMaxFrequency;
	else if (FreqL < kMinFrequency)
		FreqL = kMinFrequency;
	
	FL = (2.0 * pi * FreqL) / sampleRate;
	FreqR = FreqL;
	FR = FL;
}

-(void)changeVolume:(double)value {
	volumeLevel = value;
}

// Assigning a pitch to the left channel can either overwrite both channels, or just the left
-(void)changeLeftPitchBy:(double)value andCopyToRight:(BOOL)mono {

//	while(sin(FL*(float)phaseL)) 
//	{
//		printf("<\n");
//		sleep(1);
//	}
	
	FreqL += value;

	if (FreqL > kMaxFrequency)
		FreqL = kMaxFrequency;
	else if (FreqL < kMinFrequency)
		FreqL = kMinFrequency;
	
	FL = (2.0 * pi * FreqL) / sampleRate;
	
	if (mono) {
		FreqR = FreqL;
		FR = FL;
	}
}

-(void)changeRightPitchBy:(double)value {
	
//	while(sin(FR*(float)phaseR)) 
//	{
//		printf(">\n");
//		sleep(1);
//	}
	
	FreqR += value;
	
	if (FreqR > kMaxFrequency)
		FreqR = kMaxFrequency;
	else if (FreqR < kMinFrequency)
		FreqR = kMinFrequency;
	
	FR = (2.0 * pi * FreqR) / sampleRate;
}

-(void)changeVolumeBy:(double)value {
	volumeLevel += value;
	
	if (volumeLevel > 1.0)
		volumeLevel = 1;
	else if (volumeLevel < 0.0)
		volumeLevel = 0;
}

-(BOOL)isPlaying {
	return isPlaying;
}

@end
