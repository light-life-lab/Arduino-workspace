//
//  WiiNunchuckAppDelegate.h
//  WiiNunchuck
//
//  Created by Sam Drazin on 4/11/10.
//  Copyright Drazin_Plugins 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MUEAudioIO.h"
#import "SampleAudioUnit.h"
#import "SettingsViewController.h"
#import "MainViewController.h"
#import "InfoViewController.h"


@interface WiiNunchuckAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow							*window;
	IBOutlet UITabBarController			*rootController;

	@public MainViewController			*mainViewController;
	@public	SettingsViewController		*settingsViewController;
	@public InfoViewController			*infoViewController;
	
	// MUEAudioIO Components
	MUEAudioIO							*m_audioController;
	SampleAudioUnit						*m_sampleAudioUnit;
}

@property (nonatomic, retain) IBOutlet UIWindow				*window;
@property (nonatomic, retain) IBOutlet UITabBarController	*rootController;

-(void)updateValue:(int)labelNumber withValue:(double)value;

@end

