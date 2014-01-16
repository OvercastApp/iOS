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

@class OCNTopicViewController;

@interface OCNForumsViewController : UITableViewController {
    @private
    BOOL refreshing;
    TopicParser *forumTopics;
    ForumParser *categoryParser;
    Forum *currentForum;
}

@property (nonatomic,weak) IBOutlet UIRefreshControl *refreshWheel;
@property (nonatomic,strong) IBOutlet UIBarButtonItem *categoriesButton;
@property (nonatomic,strong) NSMutableDictionary *authorImages;
@property (nonatomic,strong) OCNTopicViewController *topicViewController;
@property (nonatomic,weak) UIPopoverController *categoriesPopover;

- (IBAction)refreshContent;

@end
