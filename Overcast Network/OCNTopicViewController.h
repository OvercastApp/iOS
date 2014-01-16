//
//  OCNTopicViewController.h
//  Overcast Network
//
//  Created by Yichen Cao on 1/10/14.
//  Copyright (c) 2014 Schem. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OCNForumsViewController.h"

@interface OCNTopicViewController : UIViewController <UISplitViewControllerDelegate>

@property (nonatomic,strong) Topic *topic;
@property (nonatomic,strong) IBOutlet UIWebView *topicWebView;
@property (strong, nonatomic) UIPopoverController *masterPopoverController;

- (void)refreshTopic;

@end
