//
//  OCNForumsViewController.h
//  Overcast Network
//
//  Created by Yichen Cao on 1/3/14.
//  Copyright (c) 2014 Schem. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OCNTopics.h"

@interface OCNForumsViewController : UITableViewController

@property (nonatomic,weak) IBOutlet UIRefreshControl *refreshWheel;
@property (nonatomic,strong) OCNTopics *forumTopics;
@property (nonatomic,getter = isRefreshing) BOOL refreshing;
@property (nonatomic,strong) NSMutableDictionary *authorImages;

- (IBAction)refreshContent;

@end
