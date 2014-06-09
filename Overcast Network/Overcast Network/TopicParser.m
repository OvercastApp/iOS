//
//  TopicParser.m
//  Overcast Network
//
//  Created by Yichen Cao on 1/11/14.
//  Copyright (c) 2014 Schem. All rights reserved.
//

#import "TopicParser.h"
#import "XMLReader.h"
#import "Alerts.h"

@implementation TopicParser

+ (void)refreshTopicsWithURL:(NSString *)urlString delegate:(id <TopicParserDelegate>)delegate
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@topicparser.php?link=%@",SOURCE,urlString]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:request
                                                    completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
                                                        NSData *xmlData = [NSData dataWithContentsOfURL:location];
                                                        dispatch_async(dispatch_get_main_queue(), ^{
                                                            if (error) {
                                                                NSLog(@"Retrieving forum source failed with error: \n%@", error);
                                                                [delegate receivedTopics:nil];
                                                                [Alerts sendConnectionFailureAlert];
                                                            } else [self parseData:xmlData delegate:delegate];
                                                        });
                                                    }];
    [task resume];
}

#pragma mark XML Parser

+ (void)parseData:(NSData *)webData delegate:(id <TopicParserDelegate>)delegate
{
    NSDictionary *parsedContents = [XMLReader dictionaryForXMLData:webData];
    NSMutableArray *topics = [[NSMutableArray alloc] init];
    for (NSDictionary *topic in [parsedContents valueForKeyPath:@"topics.topic"]) {
        Topic *newTopic = [[Topic alloc] init];
        
        newTopic.title = [NSString stringWithFormat:@"%@",[topic valueForKeyPath:@"name.text"]];
        newTopic.title = [self removeParsingErrors:newTopic.title];
        newTopic.topicURL = [topic valueForKeyPath:@"link.text"];
        newTopic.author = [NSString stringWithFormat:@"%@",[topic valueForKeyPath:@"author.text"]];
        newTopic.rank = [NSString stringWithFormat:@"%@",[topic valueForKeyPath:@"author.rank"]];
        newTopic.lastUpdated = nil;
        [topics addObject:newTopic];
    }
    [delegate receivedTopics:topics];
}

+ (NSString *)removeParsingErrors:(NSString *)parsedString
{
    NSRange searchRange = NSMakeRange([parsedString length] - 1, 1);
    parsedString = [parsedString stringByReplacingOccurrencesOfString:@"Â"
                                                           withString:@""
                                                              options:0
                                                                range:searchRange];
    parsedString = [parsedString stringByReplacingOccurrencesOfString:@" îe2" withString:@""];
    const char *utf8Chars = [parsedString cStringUsingEncoding:NSISOLatin1StringEncoding];
    NSString *utf8String = [[NSString alloc] initWithCString:utf8Chars encoding:NSUTF8StringEncoding];
    return utf8String;
}


#pragma mark Misc

- (void)sendRefreshUINotification:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateTopics"
                                                        object:sender];
}

@end
