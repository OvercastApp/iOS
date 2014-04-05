//
//  OCNLoginViewController.h
//  Overcast Network
//
//  Created by Yichen Cao on 3/28/14.
//  Copyright (c) 2014 Schem. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OCNLoginViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIWebView *loginWebView;

- (IBAction)refreshButton;
- (IBAction)cancel;

@end
