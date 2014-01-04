//
//  RegexFinder.m
//  Overcast Network
//
//  Created by Yichen Cao on 1/4/14.
//  Copyright (c) 2014 Schem. All rights reserved.
//

#import "RegexFinder.h"

@implementation RegexFinder

- (NSArray *)getResultsFromRegexSearch:(NSString *)searchRegex withSource:(NSString *)sourceHTML
{
    if (sourceHTML) {
        NSError *error = nil;
        NSRegularExpression *query = [NSRegularExpression regularExpressionWithPattern:searchRegex
                                                                                    options:0
                                                                                      error:&error];
        NSArray *result = [query matchesInString:sourceHTML
                                              options:0
                                                range:NSMakeRange(0, [sourceHTML length])];
        NSLog(@"%lu entries found with regex %@",(unsigned long)[result count], searchRegex);
        if (error) {
            NSLog(@"Error with regex");
        }
        else return result;
    }
    return nil;
}

@end
