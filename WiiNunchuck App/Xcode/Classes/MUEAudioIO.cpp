/*
 *  MUEAudioIO.cpp
 *  GainSlider
 *
 *  Created by Chris Santoro on 2/25/09.
 *  All rights reserved.
 *
 */

#include "MUEAudioIO.h"
#include "AudioBasics.h"

//********************************************************************************************
//--------------------------------------------------------------------------------------------

/*
 *This function handles a change in the audio's route. 
 *(TODO) this needs some work, should be a member of the class and call setupIO in place of SetupRemoteIO;
 *(TODO) make sure we don't crash when input becomes unavailable on an iPod Touch.
 */
void propListener( void * inClientData, AudioSessionPropertyID	inID, UInt32 inDataSize, const void *inData )
{
	//NSLog(@"propListener");
	MUEAudioIO *THIS = (MUEAudioIO*)inClientData;
	if (inID == kAudioSessionProperty_AudioRouteChange)
	{
			// if there was a route change, we need to dispose the current rio unit and create a new one
			AudioComponentInstanceDispose(THIS->rioUnit);		
			
			//SetupRemoteIO(THIS->rioUnit, THIS->inputProc, THIS->thruFormat);
            THIS->setupIO(); //(TODO) will this work?
			
			UInt32 size = sizeof(THIS->hwSampleRate);
			AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareSampleRate, &size, &THIS->hwSampleRate);
			
			AudioOutputUnitStart(THIS->rioUnit);
			
			//See what the new routing is, and take dependent action...
			CFStringRef newRoute;
			size = sizeof(CFStringRef);
			AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &size, &newRoute);
			if (newRoute)
			{	
				CFShow(newRoute);
				if (CFStringCompare(newRoute, CFSTR("Headset"), NULL) == kCFCompareEqualTo) // headset plugged in
				{
					//Do something if you'd like
				}
				else if (CFStringCompare(newRoute, CFSTR("Receiver"), NULL) == kCFCompareEqualTo) // headset plugged in
				{
					//Do something if you'd like	
				}			
				else		//Something else must be plugged in...Third party?
				{
					//Do something if you'd like
				}
			}
		
	}
}

/*
 *This function is called when Core Audio interrupts your audio session. It waits until your session is no longer interrupted,
 *and handles reactivation of of the audio session once the interruption ends.
 *https://developer.apple.com/iphone/library/documentation/Audio/Conceptual/AudioSessionProgrammingGuide/HowAudioSessionsWork/chapter_3_section_4.html
 */
void rioInterruptionListener(	void *inUserData, UInt32	inInterruption)
{
	printf("Session interrupted! --- %s ---", inInterruption == kAudioSessionBeginInterruption ? "Begin Interruption" : "End Interruption");
	
	AudioUnit *remoteIO = (AudioUnit*)inUserData;
	
	if (inInterruption == kAudioSessionEndInterruption)
	{
		// make sure we are again the active session
		AudioSessionSetActive(true);
		AudioOutputUnitStart(*remoteIO);
	}
	
	if (inInterruption == kAudioSessionBeginInterruption)
		AudioOutputUnitStop(*remoteIO);		
}
//--------------------------------------------------------------------------------------------
//********************************************************************************************


/*
 *Class Constructor
 * Initializes our Callback.
 */
MUEAudioIO::MUEAudioIO()
{
    printf("Construcing New MUE Audio Engine\n");
    m_inputBuffer = NULL;
    m_inputBufferList = NULL;
    m_curNumEffects = 0; //we have no effects registered at startup
    
    printf("Configuring Audio Session...\n");
    configureAudioSession();
    
    printf("Setting up IO Audio Unit + Callbacks...\n");
    setupIO();
    
    //printf("Initializing Callbacks...\n");
    //init_callbacks();

}

/*
 *Class Destructor
 * Releases and frees dynamically allocated variables
 */
MUEAudioIO::~MUEAudioIO()
{
   
    
}



//TODO:comment
MUEAudioIO* MUEAudioIO::getInstance()
{
    static MUEAudioIO yourMom;
    return(&yourMom);
}


/*
 *Audio Session Configuration.
 * Requests an audio session from core audio and configures it for effects processing by default (one input, one output).
 * <Sam> All major configurations are set for the AudioSession Instance here
 */
int MUEAudioIO::configureAudioSession()
{
    try {
		// Initialize and configure the audio session
		AudioSessionInitialize(NULL, NULL, rioInterruptionListener, this);
		AudioSessionSetActive(true);
		

		//audio should not mix with iPod audio, and we want input and output.
		UInt32 audioCategory = kAudioSessionCategory_PlayAndRecord;
        //audio will mix with iPod audio, but we get output only (no input) with this type of session
        //UInt32 audioCategory = kAudioSessionCategory_AmbientSound;
		AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(audioCategory), &audioCategory);
		
        
		// The entire purpose of the propListener is to detect a change in signal flow (headphones w/ mic or even third party device)
		AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange, propListener, this);
		
        
        //(TODO) make get/set preferred buffer size
		// This value is in seconds! We want really low latency...
		preferredBufferSize = .01;	// .005 for buffer of 256, .01 for buffer of 512
		AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareIOBufferDuration, 
								sizeof(preferredBufferSize), &preferredBufferSize);
		
		
		// Related to our propListener. When the signal flow changes, sometimes the hardware sample rate can change. You'll notice in the propListener it checks for a new one.
		UInt32 size = sizeof(hwSampleRate);
		AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareSampleRate, &size, &hwSampleRate);
	}
	catch (...) {
		printf("An unknown error occurred in audio session configuration!\n");
		//if (url) CFRelease(url);
	}
    
    return 0;
}

/*
 *Setup RemoteIO Audio Unit.
 * (TODO) provide dynamic configuration options here.
 */
int MUEAudioIO::setupIO()
{
    try {		
		// Open the output unit
		AudioComponentDescription desc;
		desc.componentType			= kAudioUnitType_Output;
		desc.componentSubType		= kAudioUnitSubType_RemoteIO;
		desc.componentManufacturer	= kAudioUnitManufacturer_Apple;
		desc.componentFlags			= 0;
		desc.componentFlagsMask		= 0;
		
		AudioComponent comp = AudioComponentFindNext(NULL, &desc);
		
		AudioComponentInstanceNew(comp, &rioUnit);
        
		UInt32 one = 1;
		AudioUnitSetProperty(rioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &one, sizeof(one));
        
        
        
        // Setup Callbacks--------------------------------------------------
        printf("setupIO: Initializing Callbacks\n");
        AURenderCallbackStruct inProc;
        
        inProc.inputProc = MUEinputCallback;
        inProc.inputProcRefCon = this;
        
		AudioUnitSetProperty(rioUnit, kAudioOutputUnitProperty_SetInputCallback,
							 kAudioUnitScope_Global, AUDIO_INPUT_BUS, &inProc, sizeof(inProc));
		
        inProc.inputProc = MUEoutputCallback;
        inProc.inputProcRefCon = this;
        
        AudioUnitSetProperty(rioUnit, kAudioUnitProperty_SetRenderCallback,
							 kAudioUnitScope_Global, AUDIO_OUTPUT_BUS, &inProc, sizeof(inProc));
        //-----------------------------------------------------------------
        
        
        // Enable Input and Output------------------------------------------
        // Enable Output....
        UInt32 flag = 1;
        OSStatus status = AudioUnitSetProperty(rioUnit, kAudioOutputUnitProperty_EnableIO, 
											   kAudioUnitScope_Output, AUDIO_OUTPUT_BUS, &flag, sizeof(flag));
        
        if (status != noErr)
        {
            printf("MUEAudioIO::setupIO: Enable Output failed: status = %d\n", status);
        }
        
        // Enable Input....
        status = AudioUnitSetProperty(rioUnit, kAudioOutputUnitProperty_EnableIO, 
									  kAudioUnitScope_Input, AUDIO_INPUT_BUS, &flag, sizeof(flag));
        
        if (status != noErr)
        {
            printf("MUEAudioIO::setupIO: Enable Input failed: status = %d\n", status);
        }
        //-----------------------------------------------------------------
        
        
		// Set up audio I/0 format, data type whatever. Describe the stream.
        // AudioStreamBasicDescription streamDesc;
        // This next function is built into Core Audio
        FillOutASBDForLPCM(m_streamDesc, AUDIO_SAMPLE_RATE, AUDIO_NUM_CHANNELS, AUDIO_BIT_DEPTH,
						   AUDIO_BIT_DEPTH, false, false, AUDIO_FORMAT_IS_NONINTERLEAVED);
        
        
		// XThrowIfError(AudioUnitGetProperty(rioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &m_streamDesc, sizeof(m_streamDesc) ), "couldn't get the remote I/O unit's output client format");
        
        // TODO: why is scope input associated with output bus? and vice versa?
		AudioUnitSetProperty(rioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, AUDIO_OUTPUT_BUS, &m_streamDesc, sizeof(m_streamDesc));
        AudioUnitSetProperty(rioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, AUDIO_INPUT_BUS, &m_streamDesc, sizeof(m_streamDesc));

/*		// Prints audio configuration settings, why wont this print?
		printf("  m_streamDesc initialized with AUDIO_SAMPLE_RATE  : %f", AUDIO_SAMPLE_RATE);
		printf("                                AUDIO_NUM_CHANNELS : %d", AUDIO_NUM_CHANNELS);
		printf("                                AUDIO_BIT_DEPTH    : %d", AUDIO_BIT_DEPTH);
*/		
		AudioUnitInitialize(rioUnit);

	}
	catch (...) {
		printf("An unknown error occurred\n");
		return 1;
	}	
	
	return 0;
	
	
}


/*
 * Start Audio.
 * When you're ready to start your audio flowing, call this beast of a function.
 */
int MUEAudioIO::startIO()
{

    OSStatus err = AudioOutputUnitStart(rioUnit);
    
    if(err) printf("MUEAudioIO::startIO: Couldn't start audio unit\n");

    return 0;
}


int MUEAudioIO::stopIO()
{
    OSStatus err = AudioOutputUnitStop(rioUnit);
    
    if(err) printf("MUEAudioIO::stopIO: Couldn't stop audio unit\n");
    
    return 0;
}




OSStatus MUEAudioIO::MUEinputCallback(void *inRefCon, 
									  AudioUnitRenderActionFlags *ioActionFlags, 
									  const AudioTimeStamp *inTimeStamp, 
									  UInt32 inBusNumber, 
									  UInt32 inNumberFrames, 
									  AudioBufferList *ioData)
{
	MUEAudioIO *THIS = (MUEAudioIO *)inRefCon;
    
    if(THIS->m_inputBufferList == NULL)
    {
        THIS->m_inputBuffer = (float*)malloc(inNumberFrames*sizeof(float));
        
        THIS->allocate_input_buffers(inNumberFrames);        
    }
    
    //Make a request for samples, put them in ioData
	OSStatus err = AudioUnitRender(THIS->rioUnit, ioActionFlags, inTimeStamp, 1, inNumberFrames, THIS->m_inputBufferList);
	if (err) { printf("Rendering Error: error %d\n", (int)err); return err; }
    
    
    //convert samples to float and put them in our input buffer
	AudioSamplesShortToFloat((short*)THIS->m_inputBufferList->mBuffers[0].mData, (float*)THIS->m_inputBuffer, inNumberFrames);
	return err;
}


OSStatus MUEAudioIO::MUEoutputCallback(void *inRefCon, 
									   AudioUnitRenderActionFlags *ioActionFlags, 
									   const AudioTimeStamp *inTimeStamp, 
									   UInt32 inBusNumber, 
									   UInt32 inNumberFrames, 
									   AudioBufferList *ioData)
{
    //TODO: hard coded to 1 channel of input right now
    
    MUEAudioIO *THIS = (MUEAudioIO *)inRefCon;
    //process crap thats in our buffer
    for(int i = 0; i < THIS->m_curNumEffects; i++)
    {
       THIS->m_Modules[i]->process(THIS->m_inputBuffer, inNumberFrames, 1); 
    }
    
    //convert back to short and send to DAC
    AudioSamplesFloatToShort((float*)THIS->m_inputBuffer, (short*)ioData->mBuffers[0].mData, inNumberFrames);
    
    return 0; //TODO: is this going to fuck something up?
    //FIXME: 

}



int MUEAudioIO::addMUEAudioUnit(MUEAudioUnit* unit)
{
    if(m_curNumEffects < EFFECT_CAPACITY)
    {
        m_Modules[m_curNumEffects] = unit;
        m_curNumEffects++;
        return(m_curNumEffects - 1);
    }
    else
    {
        printf("addMUEAudioUnit: We don't have any more room for modules!\n");
        return -1;
    }
}

MUEAudioUnit* MUEAudioIO::getMUEAudioUnit(int index)
{
    if((index >= 0) && (index < EFFECT_CAPACITY))
    {
        return(m_Modules[index]);
    }
    else
    {
        printf("getMUEAudioUnit: index out of bounds\n");
        return NULL;
    }
}


void MUEAudioIO::allocate_input_buffers(UInt32 inNumberFrames)
{
    printf("AudioEngine::allocate_input_buffers: inNumberFrames = %d\n", inNumberFrames);
    
    UInt32 bufferSizeInBytes = inNumberFrames * (AUDIO_FORMAT_IS_NONINTERLEAVED ? AUDIO_BIT_DEPTH_IN_BYTES :  (AUDIO_BIT_DEPTH_IN_BYTES * AUDIO_NUM_CHANNELS));
    
    // allocate buffer list
    m_inputBufferList = new AudioBufferList; 
    m_inputBufferList->mNumberBuffers = AUDIO_FORMAT_IS_NONINTERLEAVED ? AUDIO_NUM_CHANNELS : 1;
    for (UInt32 i = 0; i < m_inputBufferList->mNumberBuffers; i++)
    {
        printf("AudioEngine::allocate_input_buffers: i = %d, bufferSizeInBytes = %d\n", i, bufferSizeInBytes);
        m_inputBufferList->mBuffers[i].mNumberChannels = AUDIO_FORMAT_IS_NONINTERLEAVED ? 1 : AUDIO_NUM_CHANNELS;
        m_inputBufferList->mBuffers[i].mDataByteSize = bufferSizeInBytes;
        m_inputBufferList->mBuffers[i].mData = malloc(bufferSizeInBytes); // could write this with new/delete...
    }
    
    /*if (m_recordedData == NULL)
    {
        m_inputBuffer = malloc(bufferSizeInBytes);
        m_recordedDataSizeInBytes = bufferSizeInBytes;
    }*/
}

//(TODO) get/set sample rate (probably not possible because the "phone always wins")
