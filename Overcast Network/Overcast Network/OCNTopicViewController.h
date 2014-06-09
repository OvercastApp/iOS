//
//  OCNTopicViewController.h
//  Overcast Network
//
//  Created by Yichen Cao on 3/25/14.
//  Copyright (c) 2014 Schem. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TopicParser.h"
#import "PostParser.h"
#import "OCNAuthorImages.h"
#import "OCNPostViewController.h"

@interface OCNTopicViewController : UITableViewController <UISplitViewControllerDelegate, UIWebViewDelegate, UIActionSheetDelegate, AuthorImagesDelegate, PostParserDelegate>

@property (nonatomic,strong) Topic *topic;
@property (nonatomic,strong) UIPopoverController *masterPopoverController;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *reverseButton;

@property (nonatomic) int lastPage;

- (void)refreshTopic;
- (IBAction)refreshPulled;
- (IBAction)reverseOrder:(UIBarButtonItem *)sender;

- (IBAction)shareTopic:(id)sender;

@end