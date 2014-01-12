//
//  Forum.m
//  Overcast Network
//
//  Created by Yichen Cao on 1/12/14.
//  Copyright (c) 2014 Schem. All rights reserved.
//

#import "Forum.h"

@implementation Forum

- (instancetype)init
{
    self = [super init];
    self.index = [NSIndexPath indexPathForRow:0 inSection:0];
    self.title = @"What's New";
    self.url = @"https://oc.tc/forums";
    return self;
}

@end
