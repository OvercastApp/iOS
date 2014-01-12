//
//  TopicParser.h
//  Overcast Network
//
//  Created by Yichen Cao on 1/11/14.
//  Copyright (c) 2014 Schem. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Topic.h"

@interface TopicParser : NSObject

@property (nonatomic,strong) NSDictionary *parsedContents;
@property (nonatomic,strong) NSMutableArray *topics;

- (void)refreshTopicsWithURL:(NSString *)urlString;

@end
