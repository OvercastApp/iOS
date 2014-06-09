//
//  TopicParser.h
//  Overcast Network
//
//  Created by Yichen Cao on 1/11/14.
//  Copyright (c) 2014 Schem. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Topic.h"

@protocol TopicParserDelegate <NSObject>

- (void)receivedTopics:(NSMutableArray *)topics;

@end

@interface TopicParser : NSObject

@property (nonatomic,strong) id <TopicParserDelegate> delegate;

+ (void)refreshTopicsWithURL:(NSString *)urlString delegate:(id <TopicParserDelegate>)delegate;

@end
