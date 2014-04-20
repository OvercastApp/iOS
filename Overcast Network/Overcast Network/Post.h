//
//  Post.h
//  Overcast Network
//
//  Created by Yichen Cao on 3/25/14.
//  Copyright (c) 2014 Schem. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Post : NSObject

@property (nonatomic,strong) NSString *author;
@property (nonatomic,strong) NSString *rank;
@property (nonatomic,strong) NSString *lastPosted;
@property (nonatomic,strong) NSString *content;
@property (nonatomic,strong) NSString *postID;

+ (Post *)postWithAuthor:(NSString *)author rank:(NSString *)rank lastPosted:(NSString *)lastPosted content:(NSString *)content postID:(NSString *)postID;

@end
