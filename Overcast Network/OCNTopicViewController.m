//
//  OCNTopicViewController.m
//  Overcast Network
//
//  Created by Yichen Cao on 1/10/14.
//  Copyright (c) 2014 Schem. All rights reserved.
//

#import "OCNTopicViewController.h"

@interface OCNTopicViewController () <UIScrollViewDelegate>

@end

@implementation OCNTopicViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.topicWebView = [[UIWebView alloc] init];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@",self.topic.topicURL]];
    NSLog(@"%@",url);
    NSURLRequest *webRequest = [NSURLRequest requestWithURL:url];
    [self.topicWebView loadRequest:webRequest];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
