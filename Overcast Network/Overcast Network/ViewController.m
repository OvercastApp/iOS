//
//  ViewController.m
//  TestOCNLogin
//
//  Created by Yichen Cao on 4/14/14.
//  Copyright (c) 2014 Schem. All rights reserved.
//

#import "ViewController.h"
#import "OCNHTTPRequest.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self reset:nil];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if ([[connection originalRequest].identifier isEqualToString:@"Topic"]) {
        NSLog(@"New topic made!");
        return;
    }
    if ([[connection originalRequest].identifier isEqualToString:@"Post"]) {
        NSLog(@"Posted!");
        return;
    }
    if ([[connection originalRequest].identifier isEqualToString:@"Reply"]) {
        NSLog(@"Replied!");
        return;
    }
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
    if ([[connection originalRequest].identifier isEqualToString:@"Ping"]) {
        NSLog(@"Pinged!");
        [self login:nil];
    }
    if ([[connection originalRequest].identifier isEqualToString:@"Login"]) {
        NSLog(@"Logged in!");
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)ping:(id)sender
{
    NSMutableURLRequest *loginRequest = [[NSMutableURLRequest alloc] init];
    NSURL *loginPageURL = [NSURL URLWithString:@"http://oc.tc/"];
    [loginRequest setURL:loginPageURL];
    [loginRequest setHTTPMethod:@"GET"];
    loginRequest.identifier = @"Ping";
    [NSURLConnection connectionWithRequest:loginRequest delegate:self];
}

- (IBAction)login:(id)sender
{
    NSString *username = @"xxx@gmail.com";
    NSString *password = @"xxxxx";
    [OCNHTTPRequest loginWithUsername:username
                             password:password
                               cookie:self.loginCookie
                               sender:self];
}

- (IBAction)reply:(id)sender {
    NSString *post = @"The login is as secure as logging in on the web. (Also first ever reply done on OCN App!)";
    NSString *postID = @"534e462212ca95b6eb001bdb";
    NSString *topicURL = @"https://oc.tc/forums/topics/534d3d7312ca95844900265d";
    [OCNHTTPRequest newReplyToPost:postID
                       WithContent:post
                               URL:topicURL
                            cookie:self.loginCookie
                            sender:self];
}

- (IBAction)postPost:(id)sender {
    NSString *post = @"Testing senders";
    NSString *topicURL = @"https://oc.tc/forums/topics/534d3d7312ca95844900265d";
    [OCNHTTPRequest newPostWithContent:post
                                   URL:topicURL
                                cookie:self.loginCookie
                                sender:self];
}

- (IBAction)postTopic:(id)sender {
    NSString *topicTitle = @"First ever topic from OCN iOS App";
    if (topicTitle.length > 100){
        [self messageTooLong];
        return;
    }
    NSString *topicContent = @"With help from Akorlith, MasterEjay, iamramsey, and the entire OCN iOS Testing group!";
    NSString *subforumURL = @"https://oc.tc/forums/4fc17a31c4637515f700001e";
    [OCNHTTPRequest newTopic:topicTitle
                     content:topicContent
                         URL:subforumURL
                      cookie:self.loginCookie
                      sender:self];
}

- (void)messageTooLong
{
    //Alert
}

- (IBAction)reset:(id)sender {
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *each in [cookieStorage cookiesForURL:[NSURL URLWithString:@"https://oc.tc"]]) {
        [cookieStorage deleteCookie:each];
    }
    NSLog(@"Reset Cookies");
    [self ping:nil];
}

@end
