/*
 *  MUEAudioIO.h
 *
 *  Created by Chris Santoro on 2/25/09.
 *  chris@lsbaudio.com
 *  All rights reserved.
 *
 *  Revisions:
 *  0.1, 2/25/09: initial class design by CAS.
 *  0.2, 2/27/09: expanded commentary
 */
/*----------------------------------------------------------------------------------------------------
 This is a generalized class for setting up real-time audio IO on the iPhone and iPod Touch platforms.
 It contains functions for setting up an I/O Audio Unit in the most common configuration(s). It contains
 functions to handle interrupts (phone calls) and changes in audio routing (headphones/speaker). It also
 contains a global callback, which is not a member of the class. You should edit this callback to use
 as a controller for your other audio processing modules.
 
 This class was developed for the mobile audio processing class in the Music Engineering Department at
 the University of Miami. Thanks to Pat O'Keefe for doing a lot of the legwork in cannibalizing the
 aurio Touch sample code.
 --------------------------------------------------------------------------------------------------*/

#ifndef MUE_AUDIO_IO_H
#define MUE_AUDIO_IO_H


#include <AudioToolbox/AudioToolbox.h>
#include <AudioUnit/AudioUnit.h>
#include <stdio.h>

//#include "CAXException.h"
#include "CAStreamBasicDescription.h"
#include "MUEAudioUnit.h"

#define EFFECT_CAPACITY 20

class MUEAudioIO
{
public:
    //(TODO) expand comments for each function in the interface
    
    // Class constructor
    MUEAudioIO();
    
	// Class destructor
	~MUEAudioIO();

    static MUEAudioIO* getInstance();
    
    // Configuration functions, used by the constructor
    int configureAudioSession();
    int setupIO();
    
    // Start and stop audio
    int startIO();
    int stopIO();
    
    // Adds an audio unit to the processing queue. returns its index in the queue.
    int addMUEAudioUnit(MUEAudioUnit* unit);
    
    // Returns a pointer to the audio unit at the given index
    MUEAudioUnit* getMUEAudioUnit(int index);
        
/*
    //(TODO)hardware control
    //Float64 getSampleRate();
    //Float64 setSampleRate();
    
    //(TODO)
    //Float64 getBufferSize();
    //Float64 setBufferSize(Float32 bufSizeInSeconds);
*/    
    
    static OSStatus MUEinputCallback(void *inRefCon, 
                         AudioUnitRenderActionFlags *ioActionFlags, 
                         const AudioTimeStamp *inTimeStamp, 
                         UInt32 inBusNumber, 
                         UInt32 inNumberFrames, 
                         AudioBufferList *ioData);
    
    static OSStatus MUEoutputCallback(void *inRefCon, 
                           AudioUnitRenderActionFlags *ioActionFlags, 
                           const AudioTimeStamp *inTimeStamp, 
                           UInt32 inBusNumber, 
                           UInt32 inNumberFrames, 
                           AudioBufferList *ioData);
    
    void allocate_input_buffers(UInt32 inNumberFrames);
    
    
    AudioUnit					rioUnit;
    CAStreamBasicDescription	thruFormat;
    AudioStreamBasicDescription m_streamDesc;
    
    AudioBufferList				*m_inputBufferList;
    float						*m_inputBuffer;
    
    Float64						hwSampleRate;
    Float32						preferredBufferSize;
    
    // We can hold up to 20 effects, I'm avoiding dynamically allocating space for simplicity.
    MUEAudioUnit				*m_Modules[EFFECT_CAPACITY];
    int							m_curNumEffects;
    
};

#endif
