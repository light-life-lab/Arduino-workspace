//
//  MainViewController.h
//  WiiNunchuck
//
//  Created by Sam Drazin on 4/11/10.
//  Copyright 2010 Drazin_Plugins. All rights reserved.
//

#import <UIKit/UIKit.h>
#include <AudioToolbox/AudioToolbox.h>
#import	 <AVFoundation/AVFoundation.h>
#include "SineMaker.h"

#define kUpdateInterval		(1.0f/10.0f)
#define kMaxAccel			1.35f
#define kMinAccel		   -1.35f
#define kNominalAccelX		130
#define kNominalAccelY		90
#define kNominalAccelZ		95
#define	kNominalValue3		131

#define kAccelThreshold		25


#define kAccelMappingScale	20
#define kDefaultFrequency	440.0

#define	kMaxValue			255.0
#define kMinValue			0.0
#define	kScreenRefreshTime	0.01

#define kSynthMode_DJ		0
#define kSynthMode_Sine		1
#define kSynthMode_Drums	2


@class WiiNunchuckAppDelegate;

@interface MainViewController : UIViewController <UIAccelerometerDelegate, AVAudioPlayerDelegate> {

	IBOutlet UILabel		*valueLabel1;
	IBOutlet UILabel		*valueLabel2;
	IBOutlet UILabel		*valueLabel3;
	IBOutlet UIImageView	*zButtonImageView;	// for value4
	IBOutlet UIImageView	*cButtonImageView;	// for value5

@public 
	IBOutlet UILabel		*valueLabel3Title;
	
	IBOutlet UIButton		*syncButton;
	IBOutlet UIButton		*stopSyncButton;
	NSTimer					*myTimer;
	UIActivityIndicatorView *activityView;
	
@public
	WiiNunchuckAppDelegate	*applicationDelegate;
	
	// Local copies of the values read in from the SampleAudioUnit.mm file (from Arduino)
	double					value1, value2, value3;
	bool					value4, value5; // zButton and cButton
	
	double					iPhoneAccel;
	
	AVAudioPlayer			*player;
	
	NSURL					*dj1URL, *dj2URL, *dj3URL, *dj4URL, *dj5URL;
	NSURL					*kickURL, *snareURL, *openHatURL;
	
	// SineMaker object for Sine mode			{synthMode == 1}
	SineMaker				*sine;
	@public int				numberOfSineTones;
	
	int						synthMode;
}

@property (nonatomic, retain)	IBOutlet UILabel		*valueLabel1;
@property (nonatomic, retain)	IBOutlet UILabel		*valueLabel2;
@property (nonatomic, retain)	IBOutlet UILabel		*valueLabel3;
@property (nonatomic, retain)	IBOutlet UIButton		*syncButton;
@property (nonatomic, retain)	IBOutlet UIButton		*stopSyncButton;
@property (nonatomic, retain)	UIActivityIndicatorView	*activityView;

@property (nonatomic, retain)	IBOutlet UIImageView	*zButtonImageView;
@property (nonatomic, retain)	IBOutlet UIImageView	*cButtonImageView;

@property (nonatomic, retain)	IBOutlet UILabel		*valueLabel3Title;

@property (nonatomic, retain)	AVAudioPlayer			*player;
@property (nonatomic, retain)	SineMaker				*sine;

@property (nonatomic, retain)	NSURL					*dj1URL;
@property (nonatomic, retain)	NSURL					*dj2URL;
@property (nonatomic, retain)	NSURL					*dj3URL;
@property (nonatomic, retain)	NSURL					*dj4URL;
@property (nonatomic, retain)	NSURL					*dj5URL;
@property (nonatomic, retain)	NSURL					*snareURL;
@property (nonatomic, retain)	NSURL					*kickURL;
@property (nonatomic, retain)	NSURL					*openHatURL;


-(IBAction)startSynchingValues:(id)sender;
-(IBAction)resetSync;
-(IBAction)toggleSineGenerator:(id)sender;

-(void)displayValuesToLabels;
-(void)updateValueOfLabel:(int)labelNumber withValue:(double)value;

-(void)handleCButton;
-(void)handleZButton;
-(void)handleValue1;
-(void)handleValue2;
-(void)handleValue3;

-(void)timerFired:(NSTimer *)timer;
-(void)updateSynthMode:(int)inMode;


@end
