//
//  SettingsViewController.m
//  WiiNunchuck
//
//  Created by Sam Drazin on 4/11/10.
//  Copyright 2010 Drazin_Plugins. All rights reserved.
//

#import "SettingsViewController.h"
#import "WiiNunchuckAppDelegate.h"

@implementation SettingsViewController

@synthesize useiPhoneAccel;
@synthesize iPhoneAccelSelector;
@synthesize synthesisModeSelector;
@synthesize numberOfSineTonesSelector;
@synthesize modeLabel;

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
    [super viewDidLoad];

	// Initialize the iPhoneAccel selector and toggle switch
	iPhoneAccelSelector.enabled = useiPhoneAccel.on;
	iPhoneAccelSelector.hidden	= !useiPhoneAccel.on;

	// Initialize Mode Label
	[self updateModeLabel];
	
	// Initialize the current synthesis mode to the default selection of the UISegmentedController
	mSynthMode = synthesisModeSelector.selectedSegmentIndex;

	// Send that default value to the main controller so that it can behave properly upon first loading
	[applicationDelegate->mainViewController updateSynthMode:mSynthMode];	
	
	// Initialize the value 'numberOfSineTones' in the mainViewController
	applicationDelegate->mainViewController->numberOfSineTones = numberOfSineTonesSelector.selectedSegmentIndex + 1;
}


#pragma mark -
#pragma mark Accelerometer UI Methods

-(BOOL)shouldUseiPhoneAccel
{		
	return (BOOL) useiPhoneAccel.on;
}

-(IBAction)changedAccelSelector:(id)sender
{
	if(iPhoneAccelSelector.selectedSegmentIndex == 0){
		accelDimension = 'X';
	}
	else if(iPhoneAccelSelector.selectedSegmentIndex == 1){
		accelDimension = 'Y';		
	}
	else if(iPhoneAccelSelector.selectedSegmentIndex == 2){
		accelDimension = 'Z';
	}
	
	NSString *message = [[NSString alloc] initWithFormat:@"iPhone accel-%c", accelDimension];
	applicationDelegate->mainViewController->valueLabel3Title.text = message;
	[message release];

}

-(IBAction)toggleAccelState:(id)sender
{
	BOOL currState = useiPhoneAccel.on;
	
	iPhoneAccelSelector.enabled = currState;
	iPhoneAccelSelector.hidden	= !currState;
	
	NSString *message;
	if (currState) {
		message = [[NSString alloc] initWithFormat:@"iPhone accel-%c", accelDimension];
		applicationDelegate->mainViewController->valueLabel3Title.text = message;
	}
	else {
		message = [[NSString alloc] initWithFormat:@""];
		applicationDelegate->mainViewController->valueLabel3Title.text = message;
	}
	[message release];		
}

#pragma mark -
#pragma mark Synthesis Mode UI Methods

-(IBAction)changedSynthesisModeSelector:(id)sender
{
	mSynthMode = synthesisModeSelector.selectedSegmentIndex;
	[applicationDelegate->mainViewController updateSynthMode:mSynthMode];

	[self updateModeLabel];
	
	if ([applicationDelegate->mainViewController->sine isPlaying] && mSynthMode != kSynthMode_Sine) {
		[applicationDelegate->mainViewController->sine stopSineWave];
	}
}

-(void)updateModeLabel
{
	NSString *message;
	if (synthesisModeSelector.selectedSegmentIndex == 0)
		message = [[NSString alloc] initWithFormat:@"DJ Samples Mode"];
	else if (synthesisModeSelector.selectedSegmentIndex == 1)
		message = [[NSString alloc] initWithFormat:@"Sine Mode"];
	else if (synthesisModeSelector.selectedSegmentIndex == 2)
		message = [[NSString alloc] initWithFormat:@"Drum Mode"];
	else
		message = [[NSString alloc] initWithFormat:@"Sweedish Mode"];

	modeLabel.text = message;
	[message release];
}

-(IBAction)changedNumberOfSineTonesSelector:(id)sender
{
	applicationDelegate->mainViewController->numberOfSineTones = numberOfSineTonesSelector.selectedSegmentIndex + 1;
}

#pragma mark -
#pragma mark Memory Management Methods

- (void)didReceiveMemoryWarning 
{
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload 
{
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (void)dealloc 
{
    [super dealloc];
}


@end
