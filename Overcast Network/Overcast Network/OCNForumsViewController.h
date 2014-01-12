//
//  OCNForumsViewController.h
//  Overcast Network
//
//  Created by Yichen Cao on 1/3/14.
//  Copyright (c) 2014 Schem. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TopicParser.h"
#import "Forum.h"
#import "CategoriesViewController.h"

@interface OCNForumsViewController : UITableViewController {
    @private
    TopicParser *forumTopics;
    BOOL refreshing;
    Forum *currentForum;
}

@property (nonatomic,weak) IBOutlet UIRefreshControl *refreshWheel;
@property (nonatomic,strong) NSMutableDictionary *authorImages;

- (IBAction)refreshContent;

@end
