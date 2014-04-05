//
//  OCNLoginViewController.m
//  Overcast Network
//
//  Created by Yichen Cao on 3/28/14.
//  Copyright (c) 2014 Schem. All rights reserved.
//

#import "OCNLoginViewController.h"

@interface OCNLoginViewController ()

@end

@implementation OCNLoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self loadLoginView];
}

- (void)loadLoginView
{
    NSURL *loginPageURL = [NSURL URLWithString:@"http://oc.tc/users/sign_in"];
    NSURLRequest *loginPageRequest = [NSURLRequest requestWithURL:loginPageURL];
    [self.loginWebView loadRequest:loginPageRequest];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)refreshButton
{
}

- (IBAction)cancel
{
    [self.presentingViewController dismissViewControllerAnimated:YES
                                                      completion:NULL];
}
@end
