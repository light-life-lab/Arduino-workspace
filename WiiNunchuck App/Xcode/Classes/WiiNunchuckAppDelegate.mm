//
//  WiiNunchuckAppDelegate.m
//  WiiNunchuck
//
//  Created by Sam Drazin on 4/11/10.
//  Copyright Drazin_Plugins 2010. All rights reserved.
//

#import "WiiNunchuckAppDelegate.h"

@implementation WiiNunchuckAppDelegate

@synthesize window;
@synthesize rootController;


-(void)applicationDidFinishLaunching:(UIApplication *)application {    

	// Associates references with views of the TabBarController (0-indexed)
	infoViewController = [rootController.viewControllers objectAtIndex:0];
	mainViewController = [rootController.viewControllers objectAtIndex:1];
	settingsViewController = [rootController.viewControllers objectAtIndex:2];

	
	// Override point for customization after application launch
	[window addSubview:rootController.view];
	[window makeKeyAndVisible];
	
	m_audioController = MUEAudioIO::getInstance();

    //add effects here
    static SampleAudioUnit sampleAudioUnit;
    m_sampleAudioUnit =	&sampleAudioUnit;
    m_audioController->addMUEAudioUnit(&sampleAudioUnit);	
	
	// Connect the SampleAudioUnit's delegate pointer to the actual WiiNunchuckAppDelegate
	m_sampleAudioUnit->applicationDelegate		= self;
	mainViewController->applicationDelegate		= self;
	settingsViewController->applicationDelegate = self;

	m_audioController->startIO();
}

-(void)updateValue:(int)labelNumber withValue:(double)value {
	[mainViewController updateValueOfLabel:labelNumber withValue:value];
}
-(void)dealloc {
	m_audioController->~MUEAudioIO();
	
	[rootController release];
    [window release];
    [super dealloc];
}


@end
