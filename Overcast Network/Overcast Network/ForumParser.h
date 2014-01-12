//
//  ForumParser.h
//  Overcast Network
//
//  Created by Yichen Cao on 1/11/14.
//  Copyright (c) 2014 Schem. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ForumParser : NSObject

@property (nonatomic,strong) NSArray *parsedContents;

- (void)refreshForums;

@end
