//
//  OCNTopicViewController.h
//  Overcast Network
//
//  Created by Yichen Cao on 3/25/14.
//  Copyright (c) 2014 Schem. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OCNForumsViewController.h"
#import "PostParser.h"
#import "Post.h"

@interface OCNTopicViewController : UITableViewController <UISplitViewControllerDelegate, UIWebViewDelegate>

@property (nonatomic,strong) Topic *topic;
@property (nonatomic,strong) UIPopoverController *masterPopoverController;
@property (nonatomic,strong) NSMutableDictionary *authorImages;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *reverseButton;

@property (nonatomic) int lastPage;

- (void)refreshTopic;
- (IBAction)refreshPulled;
- (IBAction)reverseOrder:(UIBarButtonItem *)sender;

@end