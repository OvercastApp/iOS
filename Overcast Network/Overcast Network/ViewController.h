//
//  ViewController.h
//  TestOCNLogin
//
//  Created by Yichen Cao on 4/14/14.
//  Copyright (c) 2014 Schem. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <NSURLConnectionDelegate>

@property (nonatomic,strong) NSString *loginCookie;

- (IBAction)postPost:(id)sender;
- (IBAction)postTopic:(id)sender;
- (IBAction)login:(id)sender;
- (IBAction)ping:(id)sender;
- (IBAction)reset:(id)sender;
- (IBAction)reply:(id)sender;

@end
