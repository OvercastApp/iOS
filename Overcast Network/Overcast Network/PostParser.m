//
//  PostParser.m
//  Overcast Network
//
//  Created by Yichen Cao on 3/25/14.
//  Copyright (c) 2014 Schem. All rights reserved.
//

#import "PostParser.h"
#import "XMLReader.h"
#import "Alerts.h"

@implementation PostParser

- (void)refreshPostsWithURL:(NSURL *)urlString
{
    NSLog(@"Refreshing Posts with URL %@", urlString);
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://ocnapp.maxsa.li/postparser.php?link=%@",urlString]];
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
    self.parsedContents = [XMLReader dictionaryForXMLData:webData];
    self.posts = [[NSMutableArray alloc] init];
    for (NSDictionary *post in [self.parsedContents valueForKeyPath:@"topic.post"]) {
        NSString *author = [NSString stringWithFormat:@"%@",[post valueForKeyPath:@"author.text"]];
        NSString *rank = [NSString stringWithFormat:@"%@",[post valueForKeyPath:@"author.rank"]];
        NSString *lastPosted = [[[NSString stringWithFormat:@"%@",[post valueForKeyPath:@"status.text"]] componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsJoinedByString:@" "];
        NSString *content = [NSString stringWithFormat:@"%@",[post valueForKeyPath:@"content.text"]];
        content = [[content stringByReplacingOccurrencesOfString:@"(("
                                                      withString:@"<"]
                   stringByReplacingOccurrencesOfString:@"))"
                   withString:@">"];
        Post *newPost = [Post postWithAuthor:author
                                        rank:rank
                                  lastPosted:lastPosted
                                     content:content];
        [self.posts addObject:newPost];
    }
    self.lastPage = [[self.parsedContents valueForKeyPath:@"topic.lastpage.text"] intValue];
    if (!self.lastPage) {
        self.lastPage = 1;
    }
    [self sendRefreshUINotification:self];
}

- (void)sendRefreshUINotification:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdatePosts"
                                                        object:sender];
}

@end
