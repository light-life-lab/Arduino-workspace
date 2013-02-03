//
//  InfoViewController.h
//  WiiNunchuck
//
//  Created by Sam Drazin on 4/25/10.
//  Copyright 2010 Drazin_Plugins. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface InfoViewController : UIViewController {
	IBOutlet UIWebView	*webView;
	IBOutlet UIButton	*infoButton;
}

@property (nonatomic, retain) IBOutlet UIWebView	*webView;
@property (nonatomic, retain) IBOutlet UIButton		*infoButton;

- (IBAction)toggleInformationWebView:(id)sender;

@end
