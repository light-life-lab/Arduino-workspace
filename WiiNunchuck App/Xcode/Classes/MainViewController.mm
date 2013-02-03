//
//  MainViewController.m
//  WiiNunchuck
//
//  Created by Sam Drazin on 4/11/10.
//  Copyright 2010 Drazin_Plugins. All rights reserved.
//

#import "MainViewController.h"
#import "WiiNunchuckAppDelegate.h"

int		refreshSessionsWithoutValues	= 0;
int		debounceValue1					= 0;
int		debounceValue2					= 0;
int		debounceValue3					= 0;
int		debounceZButton					= 0;
int		debounceCButton					= 0;

#define	kDebounceDelay					15
#define kValueHighThreshold				220
#define kValueLowThreshold				40

@implementation MainViewController

@synthesize valueLabel1, valueLabel2, valueLabel3;
@synthesize syncButton, stopSyncButton;
@synthesize zButtonImageView, cButtonImageView;
@synthesize valueLabel3Title;
@synthesize activityView;

@synthesize player;
@synthesize dj1URL, dj2URL, dj3URL, dj4URL, dj5URL;
@synthesize kickURL, snareURL, openHatURL;

@synthesize sine;

double map(double value, double oldLow, double oldHigh, double newLow, double newHigh)
{
	return (value - oldLow) * (newHigh - newLow) / (oldHigh - oldLow) + newLow;
}

- (void)viewDidLoad 
{
	[super viewDidLoad];
	
	// Initialize and link iPhone's accelerometer to the application
	UIAccelerometer *accel = [UIAccelerometer sharedAccelerometer];
	accel.delegate = self;
	accel.updateInterval = kUpdateInterval;
	
	
	// Load and store handles for all sound files
	NSString *soundFilePath = [[NSBundle mainBundle] pathForResource: @"vibraslap" ofType: @"aif"];
	soundFilePath = [[NSBundle mainBundle] pathForResource: @"weird_wah" ofType: @"aif"];
	dj1URL = [[NSURL alloc] initFileURLWithPath: soundFilePath];
	soundFilePath = [[NSBundle mainBundle] pathForResource: @"low_bubble" ofType: @"aif"];
	dj2URL = [[NSURL alloc] initFileURLWithPath: soundFilePath];
	soundFilePath = [[NSBundle mainBundle] pathForResource: @"cool_wind_scrape" ofType: @"aif"];
	dj3URL = [[NSURL alloc] initFileURLWithPath: soundFilePath];
	soundFilePath = [[NSBundle mainBundle] pathForResource: @"vibraslap" ofType: @"aif"];
	dj4URL = [[NSURL alloc] initFileURLWithPath: soundFilePath];
	soundFilePath = [[NSBundle mainBundle] pathForResource: @"low_rising_bubbles" ofType: @"aif"];
	dj5URL = [[NSURL alloc] initFileURLWithPath: soundFilePath];

	soundFilePath = [[NSBundle mainBundle] pathForResource: @"kick" ofType: @"caf"];
	kickURL = [[NSURL alloc] initFileURLWithPath: soundFilePath];
	soundFilePath = [[NSBundle mainBundle] pathForResource: @"snare" ofType: @"caf"];
	snareURL = [[NSURL alloc] initFileURLWithPath: soundFilePath];
	soundFilePath = [[NSBundle mainBundle] pathForResource: @"open_hat" ofType: @"caf"];
	openHatURL = [[NSURL alloc] initFileURLWithPath: soundFilePath];

	// Create an AVAudioPlayer to play the files
	AVAudioPlayer *newPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL: dj1URL error: nil];
	[soundFilePath release];

	self.player = newPlayer;
	[newPlayer release];
	[player prepareToPlay];
	[player setDelegate: self];
	
	// Allocate SineMaker object, and 'stop' it, which sets some initial flags
	sine = [[SineMaker alloc] init];
	[sine stopSineWave];
	[sine changePitch:kDefaultFrequency];
}

#pragma mark -
#pragma mark Data Syncing Methods

// Initializes a NSTimer to repeatedly sync incoming values to displays and value-handling functions
-(IBAction)startSynchingValues:(id)sender
{
	syncButton.enabled = NO;
	syncButton.hidden = YES;
	
	stopSyncButton.hidden = NO;
	stopSyncButton.enabled = YES;
	
	activityView = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] autorelease];
	activityView.frame=CGRectMake(245, 18, 25, 25);
	activityView.tag  = 1;
	[self.view addSubview:activityView];
	[activityView startAnimating];
	
	[self displayValuesToLabels];
	
	// reset the timer
	[myTimer invalidate];
	[myTimer release];
	myTimer = nil;
	
	refreshSessionsWithoutValues = 0;
	
	myTimer = [[NSTimer timerWithTimeInterval:kScreenRefreshTime target:self 
									 selector:@selector(timerFired:) 
									 userInfo:nil repeats:YES] retain];
	[[NSRunLoop currentRunLoop] addTimer:myTimer forMode:NSDefaultRunLoopMode];	
}

// Resets the NSTimer and stops the syncing of values
-(IBAction)resetSync
{	
	// reset the timer
	[myTimer invalidate];
	[myTimer release];
	myTimer = nil;
	
	UIActivityIndicatorView *tmpimg = (UIActivityIndicatorView *)[self.view viewWithTag:1];
	[tmpimg removeFromSuperview];
	
	stopSyncButton.enabled	= NO;
	stopSyncButton.hidden	= YES;
	syncButton.enabled		= YES;
	syncButton.hidden		= NO;
	
	zButtonImageView.hidden	= YES;
	cButtonImageView.hidden	= YES;
	
	value1 = 0;
	value2 = 0;
	value3 = 0;
	value4 = 0;
	value5 = 0;
	[self displayValuesToLabels];
}

// Displays read values to their respective labels
-(void)displayValuesToLabels
{
	NSString *message;
	
	message = [[NSString alloc] initWithFormat:@"%.0f", value1];
	valueLabel1.text = message;
	message = [[NSString alloc] initWithFormat:@"%.0f", value2];
	valueLabel2.text = message;
	
	if (![applicationDelegate->settingsViewController shouldUseiPhoneAccel]) {
		message = [[NSString alloc] initWithFormat:@"%.0f", value3];
		valueLabel3.text = message;	
	}
	[message release];
}

// Function called from the SampleAudioUnit.mm file, which sends values from the input stream
-(void)updateValueOfLabel:(int)labelNumber withValue:(double)value
{
	if (labelNumber == 1) {
		value1 = value;
	}
	else if (labelNumber == 2) {
		value2 = value;
	}
	else if (labelNumber == 3) {
		if ([applicationDelegate->settingsViewController shouldUseiPhoneAccel]) {
			value3 = iPhoneAccel;
		}
		else {
			value3 = value;
		}
	}
	else if (labelNumber == 4) {
		value4 = (bool) value;
	}
	else if (labelNumber == 5) {
		value5 = (bool) value;
	}
	
}

// This function is called every
-(void)timerFired:(NSTimer *)timer
{
	if (value1 == 0 && value2 == 0 && value3 == 0)
		refreshSessionsWithoutValues += 1;
	
	if (refreshSessionsWithoutValues >= 500) {// && ![applicationDelegate->settingsViewController shouldUseiPhoneAccel]) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Connection Error" 
														message:@"Failed to receive data sent through the headphone jack.  Check your connections and try again." 
													   delegate:self 
											  cancelButtonTitle:@"Ok" 
											  otherButtonTitles:nil];
		[alert show];
		[alert release];
		[self resetSync];
		refreshSessionsWithoutValues = 0;
		return;
	}
	// time has passed, handle sensor values and recall the display function
	
	[self handleValue1];
	[self handleValue2];
	[self handleValue3];
	[self handleZButton];
	[self handleCButton];
	[self displayValuesToLabels];
}

// Stores current synth-mode in local member 'synthMode'
/*
 *	#	Mode Name			Mode Reference (constant)
 *	------------------------------------------------
 *	0:	DJ Samples Mode		kSynthMode_DJ
 *	1:	Sine Mode			kSynthMode_Sine
 *	2:	Drum Mode			kSynthMode_Drums
 */
-(void)updateSynthMode:(int)inMode
{
	synthMode = inMode;
}

#pragma mark -
#pragma mark Value Handling Methods
/*	
 *	The following methods handle the various values being read in (stored in members named 'value1', 'value2', etc.)
 *	Several values have special properties/restrictions that are worth mentioning.  If the user selects to use the
 *	iPhone accelerometer data, for example, that value will automatically be stored in 'value3', and will override the 
 *	third value sent from the Arduino.  This can be changed, but other concerns (such as the label to the right of 
 *	'value3') should be taken into consideration in keeping the cosmetic/functionality of the iPhone's sensor information
 *	usable.
 *
 */

// Handles the 'Z' button being pressed
-(void)handleZButton
{
	if (debounceZButton <= 0) {
		zButtonImageView.hidden = YES;		
		if (value4) {
			zButtonImageView.hidden = NO;
			debounceZButton += kDebounceDelay;
			
			if (synthMode == kSynthMode_DJ) {
//				[self.player initWithContentsOfURL: dj1URL error: nil]; 
//				[self.player play];
			}
/*
			else if (synthMode == kSynthMode_Sine) {
				if (![sine isPlaying]) {
					[sine playSineWave];
				}
				else {
					[sine playSineWave];
				}
			}
 */
			else if (synthMode == kSynthMode_Drums) {
				[self.player initWithContentsOfURL: kickURL error: nil]; 
				[self.player play];
			}
		}
//		else {
//			if ([sine isPlaying]) {
//				[sine stopSineWave];
//			}
//		}
	}
	else {
		debounceZButton -= 1;
	}
}

// Handles the 'C' button being pressed
-(void)handleCButton
{
	if (debounceCButton <= 0) {
		
		cButtonImageView.hidden = YES;
		
		if (value5) {
			cButtonImageView.hidden = NO;
			debounceCButton += kDebounceDelay;

			if (synthMode == kSynthMode_DJ) {
				[self.player initWithContentsOfURL: dj2URL error: nil]; 
				[self.player play];
			}
/*
			else if (synthMode == kSynthMode_Sine) {
				if ([sine isPlaying]) {
					[sine stopSineWave];
				}
				else {
					[sine playSineWave];
				}
			}
*/ 
			else if (synthMode == kSynthMode_Drums) {
				[self.player initWithContentsOfURL: openHatURL error: nil]; 
				[self.player play];
			}				
		}
	}
	else {
		debounceCButton -= 1;
	}	
}

// Handles the first value sent from the Arduino
-(void)handleValue1
{
	if (debounceValue1 <= 0) {
		
		// If in sineMode, Inc/decrement sine wave if value is changing
		if (synthMode == kSynthMode_Sine && value1) {
			// Calculates the difference between the resting state value of the given sensor controlling value1,
			// in this case, WiiNunchuck X-acceleration				
			double difference = value1 - kNominalAccelX;
			
			if (fabs(difference) > kAccelThreshold) {
				difference /= kAccelMappingScale;
				
				if (numberOfSineTones == 2)
					[sine changeRightPitchBy:difference];
				else if (numberOfSineTones == 1)
				{
					[sine changeLeftPitchBy:difference andCopyToRight:YES];
				}
			}
		}
		
		// Otherwise, check to see that value surpasses threshold
		else if (value1 > kValueHighThreshold) {
			debounceValue1 += kDebounceDelay;

			if (synthMode == kSynthMode_DJ) {
				[self.player initWithContentsOfURL: dj1URL error: nil]; 
				[self.player play];
			}
			else if (synthMode == kSynthMode_Drums) {
				[self.player initWithContentsOfURL: snareURL error: nil]; 
				[self.player play];
			}
			
		}
		else if (value1 < kValueLowThreshold) {
			debounceValue1 += kDebounceDelay;				
			
			if (synthMode == kSynthMode_DJ) {
				[self.player initWithContentsOfURL: dj1URL error: nil]; 
				[self.player play];
			}
			else if (synthMode == kSynthMode_Drums) {
				[self.player initWithContentsOfURL: snareURL error: nil]; 
				[self.player play];
			}				
		}
	}
	else {
		debounceValue1 -= 1;
	}
}

// Handles the second value sent from the Arduino
-(void)handleValue2
{	
	if (debounceValue2 <= 0) {		
		if (value2 > kValueHighThreshold) {
			debounceValue2 += kDebounceDelay;
	
			if (synthMode == kSynthMode_DJ) {
				[self.player initWithContentsOfURL: dj4URL error: nil]; 
				[self.player play];
			}
			else if (synthMode == kSynthMode_Drums) {
				[self.player initWithContentsOfURL: snareURL error: nil]; 
				[self.player play];
			}
		}
		else if (value2 < kValueLowThreshold) {
			debounceValue2 += kDebounceDelay;
			
			if (synthMode == kSynthMode_DJ) {
				[self.player initWithContentsOfURL: dj2URL error: nil]; 
				[self.player play];
			}
			else if (synthMode == kSynthMode_Drums) {
				[self.player initWithContentsOfURL: snareURL error: nil]; 
				[self.player play];				
			}			
		}
	}
	else {
		debounceValue2 -= 1;
	}
}

// Handles the third value sent from the Arduino
-(void)handleValue3
{
	if (debounceValue3 <= 0) {
		// If in sineMode, Inc/decrement sine wave if value is changing
		if (synthMode == kSynthMode_Sine) {
				
			double difference = 0;
			if ([applicationDelegate->settingsViewController shouldUseiPhoneAccel])
			{
				char accelDim = applicationDelegate->settingsViewController->accelDimension;
				
				if (accelDim == 'X' || accelDim == 'x')			{difference = iPhoneAccel - kNominalAccelX;}
				else if (accelDim == 'Y' || accelDim == 'y')	{difference = iPhoneAccel - kNominalAccelY;}
				else if (accelDim == 'Z' || accelDim == 'z')	{difference = iPhoneAccel - kNominalAccelZ;}
			}
			else {
				difference = value3 - kNominalValue3;
			}
			if (fabs(difference) > kAccelThreshold) {
				difference /= kAccelMappingScale;
				[sine changeLeftPitchBy:difference andCopyToRight:(numberOfSineTones == 1)];
			}				
		}
		
		// Otherwise, check to see that value surpasses threshold
		else if (value3 > kValueHighThreshold) {
			debounceValue3 += kDebounceDelay;


			if (synthMode == kSynthMode_DJ) {
				[self.player initWithContentsOfURL: dj3URL error: nil]; 
				[self.player play];
			}
			else if (synthMode == kSynthMode_Drums) {
				[self.player initWithContentsOfURL: kickURL error: nil]; 
				[self.player play];
			}
			
		}
		else if (value3 < kValueLowThreshold) {
			debounceValue3 += kDebounceDelay;				

			if (synthMode == kSynthMode_DJ) {
				[self.player initWithContentsOfURL: dj3URL error: nil]; 
				[self.player play];
			}
			else if (synthMode == kSynthMode_Drums) {
				[self.player initWithContentsOfURL: kickURL error: nil]; 
				[self.player play];
			}				
		}
	}
	else {
		debounceValue3 -= 1;
	}
}

#pragma mark -
// Toggles the sine generation
-(IBAction)toggleSineGenerator:(id)sender
{
	if (applicationDelegate->settingsViewController->synthesisModeSelector.selectedSegmentIndex != kSynthMode_Sine) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Incorrect Synth Mode"
														message:@"You must be in 'Sine' mode to test out the sine generator.  Select synth modes from the buttons at the top of the Settings tab."
													   delegate:self
											  cancelButtonTitle:@"Ok"
											  otherButtonTitles:nil];
		[alert show];
		[alert release];
		return;
	}
	
	BOOL newState = ![sine isPlaying];
	
	if (newState)
		[sine playSineWave];
	else
		[sine stopSineWave];
	
	UIButton *button = (UIButton *)sender;
	button.highlighted = newState;
}

#pragma mark -
#pragma mark Accelerometer Callback

// Method called with any change to the iPhone's acceleration
-(void) accelerometer:(UIAccelerometer *) accelerometer didAccelerate:(UIAcceleration *) acceleration 
{	
	if([applicationDelegate->settingsViewController shouldUseiPhoneAccel])
	{
		//cast accelerometer values from double -> float
		double accelY = (double) acceleration.y;
		double accelX = (double) acceleration.x;
		double accelZ = (double) acceleration.z;
		
		double selectedAccel;
		char dimension = applicationDelegate->settingsViewController->accelDimension;
		
		if (dimension == 'x' || dimension == 'X') {
			selectedAccel = accelX;
		}
		else if (dimension == 'y' || dimension == 'Y') {
			selectedAccel = accelY;
		}
		else if (dimension == 'z' || dimension == 'Z') {
			selectedAccel = accelZ;
		}
		
		double newValue	= map(selectedAccel, kMinAccel, kMaxAccel, kMinValue, kMaxValue);
		
		if(newValue > kMaxValue) { 
			iPhoneAccel = kMaxValue; 
		}
		else if (newValue < kMinValue) {
			iPhoneAccel = kMinValue;
		}
		else {
			iPhoneAccel = newValue; 
		}

		NSString *message = [[NSString alloc] initWithFormat:@"%.0f", iPhoneAccel];
		valueLabel3.text = message;
		
		// MAY BE DANGEROUS, BE AWARE!
		// Defaults to sending the accel value to Value3 of the mainViewController
		value3 = iPhoneAccel;
		[message release];
	}
	else {
		valueLabel3Title.text = @"";
	}

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
	
	[sine release];
	[valueLabel1 release];
	[valueLabel2 release];
	[valueLabel3 release];
	[syncButton release];
	[stopSyncButton release];
	[activityView release];
	[zButtonImageView release];
	[cButtonImageView release];
	[valueLabel3Title release];
	[activityView release];
	[dj1URL release];
	
	[player release];
	[dj2URL release];
	[dj3URL release];
	[dj4URL release];
	[dj5URL release];
	[kickURL release];
	[snareURL release];
	[openHatURL release];
}


@end
