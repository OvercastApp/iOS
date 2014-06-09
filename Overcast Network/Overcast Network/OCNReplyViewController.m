//
//  OCNReplyViewController.m
//  Overcast Network
//
//  Created by Yichen Cao on 4/17/14.
//  Copyright (c) 2014 Schem. All rights reserved.
//

#import "OCNReplyViewController.h"
#import "OCNHTTPRequest.h"
#import "Alerts.h"

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
    self.content.delegate = self;
    self.content.text = @"Tap to enter reply";
    self.content.textColor = [UIColor lightGrayColor];
    
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

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    if ([textView.text isEqualToString:@"Tap to enter reply"]) {
        textView.text = @"";
        textView.textColor = [UIColor blackColor]; //optional
    }
    [textView becomeFirstResponder];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    if ([textView.text isEqualToString:@""]) {
        textView.text = @"Tap to enter reply";
        textView.textColor = [UIColor lightGrayColor]; //optional
    }
    [textView resignFirstResponder];
}

- (IBAction)cancelPressed:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)sendReply:(id)sender {
    [self getCookies];
    self.replyButton.enabled = NO;
    self.cancelButton.enabled = NO;
    [self.content endEditing:YES];
    if (self.replyToID)
        [self reply];
    else
        [self post];
}

- (void)getCookies
{
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
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if ([[connection originalRequest].identifier isEqualToString:@"Post"]) {
        NSLog(@"Posted!");
        [self performSegueWithIdentifier:@"Replied Unwind" sender:self];
        [self dismissViewControllerAnimated:YES
                                 completion:nil];
        return;
    }
    if ([[connection originalRequest].identifier isEqualToString:@"Reply"]) {
        NSLog(@"Replied!");
        [self performSegueWithIdentifier:@"Replied Unwind" sender:self];
        [self dismissViewControllerAnimated:YES
                                 completion:nil];
        return;
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [Alerts sendConnectionFailureAlert];
    NSLog(@"Posting failed with error: \n%@", error);
    
    self.replyButton.enabled = YES;
    self.cancelButton.enabled = YES;
}

- (void)reply
{
    [OCNHTTPRequest newReplyToPost:self.replyToID
                       WithContent:[[self.content.text componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsJoinedByString:@"<br>"]
                               URL:self.postURL
                            cookie:self.loginCookie
                            sender:self];
}

- (void)post
{
    [OCNHTTPRequest newPostWithContent:[[self.content.text componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsJoinedByString:@"<br>"]
                                   URL:self.postURL
                                cookie:self.loginCookie
                                sender:self];
}

- (void)messageTooLong
{
    //Alert
}

@end
