//
//  OCNPostViewController.h
//  Overcast Network
//
//  Created by Yichen Cao on 4/18/14.
//  Copyright (c) 2014 Schem. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Post.h"
#import "OCNAuthorImages.h"
#import "UIColor+OCNRanks.h"

@interface OCNPostViewController : UIViewController <UIActionSheetDelegate>

@property (nonatomic,strong) Post *post;
@property (nonatomic,strong) NSString *topicURL;

- (IBAction)sharePost:(id)sender;

@end
