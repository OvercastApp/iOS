//
//  OCNReplyViewController.h
//  Overcast Network
//
//  Created by Yichen Cao on 4/17/14.
//  Copyright (c) 2014 Schem. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OCNReplyViewController : UIViewController <NSURLConnectionDelegate, UITextViewDelegate>

@property (nonatomic,strong) NSString *postURL;
@property (nonatomic,strong) NSString *replyToID;

@property (weak, nonatomic) IBOutlet UITextView *content;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *replyButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;

@property (nonatomic,strong) NSString *loginCookie;

- (IBAction)cancelPressed:(id)sender;
- (IBAction)sendReply:(id)sender;

@end
