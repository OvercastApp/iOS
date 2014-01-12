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

@interface CategoriesViewController : UITableViewController {
    @private
    ForumParser *parser;
    NSArray *parsedContents;
}

@property (nonatomic,strong) Forum *currentForum;

- (IBAction)cancel:(UIBarButtonItem *)sender;

@end
