//
//  OCNForumsViewController.h
//  Overcast Network
//
//  Created by Yichen Cao on 1/3/14.
//  Copyright (c) 2014 Schem. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ForumParser.h"
#import "Forum.h"

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
