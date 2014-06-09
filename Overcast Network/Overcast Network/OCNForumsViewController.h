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
#import "OCNAuthorImages.h"
#import "OCNTopicViewController.h"

@interface OCNForumsViewController : UITableViewController <UISplitViewControllerDelegate, AuthorImagesDelegate, TopicParserDelegate, ForumParserDelegate>

@property (nonatomic,weak) IBOutlet UIRefreshControl *refreshWheel;
@property (nonatomic,strong) IBOutlet UIBarButtonItem *categoriesButton;
@property (nonatomic,weak) UIPopoverController *categoriesPopover;
@property (nonatomic,strong) OCNTopicViewController *topicViewController;
@property (retain, nonatomic) UIPopoverController *topicPopoverController;

- (IBAction)refreshContent;

@end
