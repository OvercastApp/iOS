//
//  CategoriesViewController.h
//  Overcast Network
//
//  Created by Yichen Cao on 1/11/14.
//  Copyright (c) 2014 Schem. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ForumParser.h"
#import "Forum.h"

@interface CategoriesViewController : UITableViewController

@property (nonatomic,strong) Forum *currentForum;
@property (nonatomic,strong) NSArray *parsedContents;

- (IBAction)cancel:(UIBarButtonItem *)sender;

@end
