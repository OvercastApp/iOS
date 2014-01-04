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

@property (weak, nonatomic) IBOutlet UIRefreshControl *refreshWheel;
@property (strong, nonatomic) OCNTopics *forumTopics;

- (IBAction)refreshContent;

@end
