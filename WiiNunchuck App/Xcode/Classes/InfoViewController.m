    //
//  InfoViewController.m
//  WiiNunchuck
//
//  Created by Sam Drazin on 4/25/10.
//  Copyright 2010 Drazin_Plugins. All rights reserved.
//

#import "InfoViewController.h"


@implementation InfoViewController

@synthesize webView;

@synthesize infoButton;

- (void)viewDidLoad 
{
	[super viewDidLoad];

	NSString *infoSouceFile	= [[NSBundle mainBundle] pathForResource:@"info" ofType:@"html"];
	NSString *infoText		= [NSString stringWithContentsOfFile:infoSouceFile encoding:NSUTF8StringEncoding error:nil];
    [self.webView loadHTMLString:infoText baseURL:nil];

	
//	self.webView.frame
	self.webView.hidden = YES;
}

- (IBAction)toggleInformationWebView:(id)sender
{
	BOOL currState = self.webView.hidden;
	self.webView.hidden = !currState;
}

/*
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex 
{
	if(buttonIndex == 1) {
		NSURL *myURL = [[NSURL alloc] initWithString:@"http://www.samdrazin.com/classes/mmi593"];
		[[UIApplication sharedApplication] openURL:myURL];
	}
}
*/

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload 
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)dealloc 
{
    [super dealloc];
}


@end
