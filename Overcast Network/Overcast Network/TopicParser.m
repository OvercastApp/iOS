//
//  TopicParser.m
//  Overcast Network
//
//  Created by Yichen Cao on 1/11/14.
//  Copyright (c) 2014 Schem. All rights reserved.
//

#import "TopicParser.h"
#import "XMLReader.h"

@implementation TopicParser

- (void)refreshTopicsWithURL:(NSString *)urlString
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://ocnapp.maxsa.li/topicparser.php?link=%@",urlString]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:request
                                                    completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
                                                        NSData *xmlData = [NSData dataWithContentsOfURL:location];
                                                        dispatch_async(dispatch_get_main_queue(), ^{
                                                            if (error) {
                                                                NSLog(@"Retrieving forum source failed with error: \n%@", error);
                                                                [self sendFailedAlert];
                                                            } else [self parseData:xmlData];
                                                        });
                                                    }];
    [task resume];
}

#pragma mark XML Parser

- (void)parseData:(NSData *)webData
{
    self.parsedContents = [XMLReader dictionaryForXMLData:webData];
    self.topics = [[NSMutableArray alloc] init];
    for (NSDictionary *topic in [self.parsedContents valueForKeyPath:@"topics.topic"]) {
        Topic *newTopic = [[Topic alloc] init];
        
        newTopic.title = [NSString stringWithFormat:@"%@",[topic valueForKeyPath:@"name.text"]];
        newTopic.topicURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@",[topic valueForKeyPath:@"link.text"]]];
        newTopic.author = [NSString stringWithFormat:@"%@",[topic valueForKeyPath:@"author.text"]];
        newTopic.rank = [NSString stringWithFormat:@"%@",[topic valueForKeyPath:@"rank.text"]];
        newTopic.lastUpdated = nil;
        
        NSLog(@"Topic Found: %@ by %@",newTopic.title,newTopic.author);
        
        [self.topics addObject:newTopic];
    }
    [self sendRefreshUINotification:self];
}

#pragma mark Misc

- (void)sendRefreshUINotification:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Update"
                                                        object:sender];
}

- (void)sendFailedAlert
{
    UIAlertView *failedAlert = [[UIAlertView alloc] initWithTitle:@"Cannot Refresh Content"
                                                          message:@"Check your internet connection please :D"
                                                         delegate:nil
                                                cancelButtonTitle:nil
                                                otherButtonTitles:@"I'll fix it!", nil];
    [failedAlert show];
    [self sendRefreshUINotification:self];
}

@end
