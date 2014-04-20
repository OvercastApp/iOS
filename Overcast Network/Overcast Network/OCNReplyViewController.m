//
//  OCNReplyViewController.m
//  Overcast Network
//
//  Created by Yichen Cao on 4/17/14.
//  Copyright (c) 2014 Schem. All rights reserved.
//

#import "OCNReplyViewController.h"
#import "OCNHTTPRequest.h"

@interface OCNReplyViewController ()

@end

@implementation OCNReplyViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [NSTimer scheduledTimerWithTimeInterval:1
                                     target:self
                                   selector:@selector(checkLogins)
                                   userInfo:nil
                                    repeats:NO];
}

- (void)checkLogins
{
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    BOOL didLogin = NO;
    for (NSHTTPCookie *each in [cookieStorage cookiesForURL:[NSURL URLWithString:@"https://oc.tc"]]) {
        if ([each.name isEqualToString:@"remember_user_token"])
            didLogin = YES;
    }
    if (!didLogin)
        [self performSegueWithIdentifier:@"Login" sender:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)cancelPressed:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)sendReply:(id)sender {
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSString *cookies = @"";
    for (NSHTTPCookie *each in [cookieStorage cookiesForURL:[NSURL URLWithString:@"https://oc.tc"]]) {
        cookies = [cookies stringByAppendingString:each.name];
        cookies = [cookies stringByAppendingString:@"="];
        cookies = [cookies stringByAppendingString:each.value];
        cookies = [cookies stringByAppendingString:@";"];
    }
    cookies = [cookies stringByAppendingString:@" __utma=40309308.64665819.1397484934.1397484934.1397484934.1; __utmb=40309308.24.10.1397484934; __utmc=40309308; __utmz=40309308.1397484934.1.1.utmcsr=(direct)|utmccn=(direct)|utmcmd=(none)"];
    self.loginCookie = cookies;
    
    self.replyButton.enabled = NO;
    self.cancelButton.enabled = NO;
    if (self.replyToID) [self reply];
    else [self post];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if ([[connection originalRequest].identifier isEqualToString:@"Post"]) {
        NSLog(@"Posted!");
        [self performSegueWithIdentifier:@"Replied Unwind" sender:self];
        return;
    }
    if ([[connection originalRequest].identifier isEqualToString:@"Reply"]) {
        NSLog(@"Replied!");
        [self performSegueWithIdentifier:@"Replied Unwind" sender:self];
        return;
    }
}

- (void)reply
{
    [OCNHTTPRequest newReplyToPost:self.replyToID
                       WithContent:self.content.text
                               URL:self.postURL
                            cookie:self.loginCookie
                            sender:self];
}

- (void)post
{
    [OCNHTTPRequest newPostWithContent:self.content.text
                                   URL:self.postURL
                                cookie:self.loginCookie
                                sender:self];
}

- (void)messageTooLong
{
    //Alert
}

@end
