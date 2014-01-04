//
//  OCNTopics.m
//  Overcast Network
//
//  Created by Yichen Cao on 1/3/14.
//  Copyright (c) 2014 Schem. All rights reserved.
//

#import "OCNTopics.h"

@implementation OCNTopics

- (void)refreshTopics
{
    self.topics = nil;
    self.topics = [[NSMutableArray alloc] initWithArray:@[]];
    NSURL *forumURL = [NSURL URLWithString:@"https://oc.tc/forums"];
    NSString *topicPattern = @"<a href=\"/forums/topics/(.*)\">(.*)</a>";
    NSString *authorPattern = @"'/.{1,16}' ";
    NSString *colorPattern = @"' style='color:(.*)'";
    
    Source *pageSource = [[Source alloc] init];
    RegexFinder *newRegex = [[RegexFinder alloc] init];
    
    NSString *source = [pageSource getSourceFromURL:forumURL];
    if (source) {
        NSArray *topicResult = [newRegex getResultsFromRegexSearch:topicPattern withSource:source];
        NSArray *authorResult = [newRegex getResultsFromRegexSearch:authorPattern withSource:source];
        NSArray *colorResult = [newRegex getResultsFromRegexSearch:colorPattern withSource:source];
        
        [self findFromSource:source
                 topicSearch:topicResult
                authorSearch:authorResult
                 colorSearch:colorResult];
    }
    else [self sendFailedAlert];
}

- (void)findFromSource:(NSString *)source topicSearch:(NSArray *)topicResult authorSearch:(NSArray *)authorResult colorSearch:(NSArray *)colorResult
{
    int index = 0;
    NSTextCheckingResult *authorMatch = [authorResult objectAtIndex:index];
    NSTextCheckingResult *colorMatch = [colorResult objectAtIndex:index];
    for (NSTextCheckingResult *titleMatch in topicResult) {
        authorMatch = [authorResult objectAtIndex:index];
        colorMatch = [colorResult objectAtIndex:index];
        
        Topic *newTopic = [[Topic alloc] init];
        
        NSString *substringForTitleMatch = [source substringWithRange:titleMatch.range];
        NSString *substringForAuthorMatch = [source substringWithRange:authorMatch.range];
        NSString *substringForColorMatch = [source substringWithRange:colorMatch.range];
        NSString *correctedColorMatch = [substringForColorMatch substringWithRange:NSMakeRange(16, [substringForColorMatch length] - 17)];
        
        newTopic.title = [substringForTitleMatch substringWithRange:NSMakeRange(50,[substringForTitleMatch length] - 54)];
        newTopic.topicID = [substringForTitleMatch substringWithRange:NSMakeRange(24,24)];
        newTopic.author = [substringForAuthorMatch substringWithRange:NSMakeRange(2,[substringForAuthorMatch length] - 4)];
        if ([correctedColorMatch isEqualToString:@"none"]) {
            newTopic.color = [UIColor blackColor];
        } else newTopic.color = [UIColor colorFromHexString:correctedColorMatch];
        
        NSLog(@"Found entry: \"%@\" with id \"%@\" by %@",newTopic.title,newTopic.topicID,newTopic.author);
        [self.topics addObject:newTopic];
        index += 2;
    }
}

- (void)sendFailedAlert
{
    UIAlertView *failedAlert = [[UIAlertView alloc] initWithTitle:@"Cannot Refresh Content"
                                                          message:@"Check your internet connection please :D"
                                                         delegate:nil
                                                cancelButtonTitle:nil
                                                otherButtonTitles:@"I'll fix it!", nil];
    [failedAlert show];
}

@end
