//
//  Post.m
//  Overcast Network
//
//  Created by Yichen Cao on 3/25/14.
//  Copyright (c) 2014 Schem. All rights reserved.
//

#import "Post.h"

@implementation Post

+ (Post *)postWithAuthor:(NSString *)author rank:(NSString *)rank lastPosted:(NSString *)lastPosted content:(NSString *)content postID:(NSString *)postID
{
    Post *newPost = [[Post alloc] init];
    newPost.author = author;
    newPost.rank = rank;
    newPost.lastPosted = lastPosted;
    newPost.content = content;
    newPost.postID = postID;
    return newPost;
}

@end
