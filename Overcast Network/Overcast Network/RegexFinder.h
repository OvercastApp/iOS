//
//  RegexFinder.h
//  Overcast Network
//
//  Created by Yichen Cao on 1/4/14.
//  Copyright (c) 2014 Schem. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RegexFinder : NSObject

- (NSArray *)getResultsFromRegexSearch:(NSString *)searchRegex withSource:(NSString *)sourceHTML;

@end
