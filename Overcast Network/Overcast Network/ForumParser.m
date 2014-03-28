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

- (void)refreshForums
{
    NSURL *url = [NSURL URLWithString:@"http://ocnapp.maxsa.li/forumparser.php?link=https://oc.tc/forums"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:request
                                                    completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
                                                        NSData *xmlData = [NSData dataWithContentsOfURL:location];
                                                        dispatch_async(dispatch_get_main_queue(), ^{
                                                            if (error) {
                                                                NSLog(@"Retrieving forum source failed with error: \n%@", error);
                                                                [self sendRefreshUINotification:self];
                                                                [Alerts sendConnectionFaliureAlert];
                                                            } else [self parseData:xmlData];
                                                        });
                                                    }];
    [task resume];
}

- (void)parseData:(NSData *)webData
{
    self.parsedContents = [[XMLReader dictionaryForXMLData:webData] valueForKeyPath:@"subforums.subforumtitle"];
    [self sendRefreshUINotification:self];
}

- (void)sendRefreshUINotification:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateForums"
                                                        object:sender];
}

@end
