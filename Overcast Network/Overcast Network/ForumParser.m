//
//  ForumParser.m
//  Overcast Network
//
//  Created by Yichen Cao on 1/11/14.
//  Copyright (c) 2014 Schem. All rights reserved.
//

#import "ForumParser.h"
#import "XMLReader.h"
#import "Alerts.h"

@implementation ForumParser

+ (void)refreshForumsWithDelegate:(id<ForumParserDelegate>)delegate
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@forumparser.php?link=https://oc.tc/forums",SOURCE]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:request
                                                    completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
                                                        NSData *xmlData = [NSData dataWithContentsOfURL:location];
                                                        dispatch_async(dispatch_get_main_queue(), ^{
                                                            if (error) {
                                                                NSLog(@"Retrieving forum source failed with error: \n%@", error);
                                                                [delegate receivedForumsContents:nil];
                                                            } else [self parseData:xmlData delegate:delegate];
                                                        });
                                                    }];
    [task resume];
}

+ (void)parseData:(NSData *)webData delegate:(id<ForumParserDelegate>)delegate
{
    [delegate receivedForumsContents:[[XMLReader dictionaryForXMLData:webData] valueForKeyPath:@"subforums.subforumtitle"]];
}

@end
