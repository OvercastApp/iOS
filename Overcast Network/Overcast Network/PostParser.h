//
//  PostParser.h
//  Overcast Network
//
//  Created by Yichen Cao on 3/25/14.
//  Copyright (c) 2014 Schem. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Post.h"

@interface PostParser : NSObject

@property (nonatomic,strong) NSDictionary *parsedContents;
@property (nonatomic,strong) NSMutableArray *posts;

- (void)refreshPostsWithURL:(NSString *)urlString;

@end
