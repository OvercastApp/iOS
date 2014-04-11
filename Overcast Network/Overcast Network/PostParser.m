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
                                                                NSLog(@"Retrieving posts source failed with error: \n%@", error);
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
        content = [self removeParsingErrors:content];
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

- (NSString *)removeParsingErrors:(NSString *)parsedString
{
    NSRange searchRange = NSMakeRange([parsedString length] - 1, 1);
    parsedString = [parsedString stringByReplacingOccurrencesOfString:@"Â"
                                                           withString:@""
                                                              options:0
                                                                range:searchRange];
    parsedString = [parsedString stringByReplacingOccurrencesOfString:@" îe2" withString:@""];
    const char *utf8Chars = [parsedString cStringUsingEncoding:NSISOLatin1StringEncoding];
    NSString *utf8String = [[NSString alloc] initWithCString:utf8Chars encoding:NSUTF8StringEncoding];
    NSString *heading = @"<font face='Helvetica' size='2'>";
    parsedString = [NSString stringWithFormat:@"%@<p>%@</p>",heading,utf8String];
    parsedString = [parsedString stringByReplacingOccurrencesOfString:@"((" withString:@"<"];
    parsedString = [parsedString stringByReplacingOccurrencesOfString:@"))" withString:@">"];
    parsedString = [parsedString stringByReplacingOccurrencesOfString:@"<br/>" withString:@"<br>"];
    parsedString = [parsedString stringByReplacingOccurrencesOfString:@"<img" withString:@"<img width=\"100%\""];
    parsedString = [parsedString stringByReplacingOccurrencesOfString:@"<(" withString:@"(<"];
    return parsedString;
}

- (void)sendRefreshUINotification:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdatePosts"
                                                        object:sender];
}

@end
