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
    [self refreshTopic];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.masterPopoverController presentPopoverFromBarButtonItem:self.navigationController.navigationBar.items[0]
                                         permittedArrowDirections:UIPopoverArrowDirectionUnknown
                                                         animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)refreshTopic
{
    [self.masterPopoverController dismissPopoverAnimated:YES];
    NSURL *url = self.topic.topicURL;
    if (url != nil) {
        NSLog(@"%@",url);
        NSURLRequest *webRequest = [NSURLRequest requestWithURL:url];
        [self.topicWebView loadRequest:webRequest];
    }
}

#pragma mark - Split view

- (void)splitViewController:(UISplitViewController *)svc popoverController:(UIPopoverController *)pc willPresentViewController:(UIViewController *)aViewController
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Update"
                                                        object:self];
}

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"Topics", @"Topics");
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}


@end
