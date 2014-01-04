//
//  OCNTopics.h
//  Overcast Network
//
//  Created by Yichen Cao on 1/3/14.
//  Copyright (c) 2014 Schem. All rights reserved.
//

#import "Topic.h"
#import "RegexFinder.h"
#import "Source.h"

@interface OCNTopics : Topic

@property (nonatomic, strong) NSMutableArray *topics;

- (void)refreshTopics;

@end
