//
//  ForumParser.h
//  Overcast Network
//
//  Created by Yichen Cao on 1/11/14.
//  Copyright (c) 2014 Schem. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ForumParserDelegate <NSObject>

- (void)receivedForumsContents:(NSArray *)parsedContents;

@end

@interface ForumParser : NSObject

+ (void)refreshForumsWithDelegate:(id <ForumParserDelegate>)delegate;

@end
