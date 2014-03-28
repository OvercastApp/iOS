//
//  OCNForumsViewController.h
//  Overcast Network
//
//  Created by Yichen Cao on 1/3/14.
//  Copyright (c) 2014 Schem. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TopicParser.h"
#import "ForumParser.h"
#import "Forum.h"

#define MAXSALI_AVATAR @"http://ocnapp.maxsa.li/avatar.php?name=%@&size=48"
#define OCN_AVATAR @"https://avatar.oc.tc/%@/48.png"

@class OCNTopicViewController;

@interface OCNForumsViewController : UITableViewController <UISplitViewControllerDelegate>

@property (nonatomic,weak) IBOutlet UIRefreshControl *refreshWheel;
@property (nonatomic,strong) IBOutlet UIBarButtonItem *categoriesButton;
@property (nonatomic,strong) NSMutableDictionary *authorImages;
@property (nonatomic,weak) UIPopoverController *categoriesPopover;
@property (nonatomic,strong) OCNTopicViewController *topicViewController;
@property (retain, nonatomic) UIPopoverController *topicPopoverController;

- (IBAction)refreshContent;

@end
