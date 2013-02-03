/*
 *  MUEAudioUnit.h
 *  Base class for audio effect and synthesis modules
 *
 *  Created by Chris Santoro on 2/27/09.
 *  All rights reserved.
 *
 */
#ifndef MUE_AUDIO_UNIT_H
#define MUE_AUDIO_UNIT_H

//#include "AudioUnit/AudioUnit.h"


class MUEAudioUnit
{
public:
    
    //MUEAudioUnit();
    
    /*this function must be implemented in subclasses to use with MUEAudioIO*/
    virtual void	process(float* buffer, int numSamplesPerChannel, int numChannels) = 0;
    
    virtual float	getParameter(int index) = 0;
    virtual void 	setParameter(int index, float value) = 0;
    
    //TODO: get parameter display, label
};

#endif