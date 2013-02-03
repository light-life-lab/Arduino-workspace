//
//  SettingsViewController.h
//  WiiNunchuck
//
//  Created by Sam Drazin on 4/11/10.
//  Copyright 2010 Drazin_Plugins. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WiiNunchuckAppDelegate;

@interface SettingsViewController : UIViewController {
	IBOutlet UISwitch			*useiPhoneAccel;
	IBOutlet UISegmentedControl *iPhoneAccelSelector;
	@public
	IBOutlet UISegmentedControl	*synthesisModeSelector;
	int							mSynthMode;
	
@public
	IBOutlet UISegmentedControl	*numberOfSineTonesSelector;
	
@public 
	WiiNunchuckAppDelegate		*applicationDelegate;

@public
	char						accelDimension;
	
	IBOutlet UILabel			*modeLabel;
}

@property (nonatomic, retain) IBOutlet UISwitch				*useiPhoneAccel;
@property (nonatomic, retain) IBOutlet UISegmentedControl	*iPhoneAccelSelector;
@property (nonatomic, retain) IBOutlet UISegmentedControl	*synthesisModeSelector;
@property (nonatomic, retain) IBOutlet UISegmentedControl	*numberOfSineTonesSelector;;
@property (nonatomic, retain) IBOutlet UILabel				*modeLabel;


-(BOOL)shouldUseiPhoneAccel;
-(IBAction)changedAccelSelector:(id)sender;
-(IBAction)toggleAccelState:(id)sender;

-(IBAction)changedSynthesisModeSelector:(id)sender;
-(void)updateModeLabel;
-(IBAction)changedNumberOfSineTonesSelector:(id)sender;

@end
