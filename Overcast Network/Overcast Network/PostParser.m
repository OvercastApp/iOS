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

+ (void)refreshPostsWithURL:(NSURL *)urlString delegate:(id<PostParserDelegate>)delegate
{
    NSLog(@"Refreshing Posts with URL %@", urlString);
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@postparser2.php?link=%@",SOURCE,urlString]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:request
                                                    completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
                                                        NSData *xmlData = [NSData dataWithContentsOfURL:location];
                                                        dispatch_async(dispatch_get_main_queue(), ^{
                                                            if (error) {
                                                                NSLog(@"Retrieving posts source failed with error: \n%@", error);
                                                                [delegate receivedPosts:nil
                                                                               lastPage:0];
                                                                [Alerts sendConnectionFailureAlert];
                                                            } else [self parseData:xmlData
                                                                          delegate:delegate];
                                                        });
                                                    }];
    [task resume];
}

+ (void)parseData:(NSData *)webData delegate:(id<PostParserDelegate>)delegate
{
    NSDictionary *parsedContents = [XMLReader dictionaryForXMLData:webData];
    NSMutableArray *forumPosts = [[NSMutableArray alloc] init];
    id posts = [parsedContents valueForKeyPath:@"topic.post"];
    if ([posts respondsToSelector:@selector(objectForKey:)]) {
        [self newPost:(NSDictionary *)posts];
    }
    else if ([posts respondsToSelector:@selector(objectAtIndex:)]) {
        for (NSDictionary *post in (NSArray *)posts) {
            [forumPosts addObject:[self newPost:post]];
        }
    }
    int lastPage = [[parsedContents valueForKeyPath:@"topic.lastpage.text"] intValue];
    if (!lastPage) {
        lastPage = 1;
    }
    [delegate receivedPosts:forumPosts
                   lastPage:lastPage];
}

+ (Post *)newPost:(NSDictionary *)post
{
    NSString *author = [post valueForKeyPath:@"author.text"];
    NSString *rank = [post valueForKeyPath:@"author.rank"];
    NSString *lastPosted = [[[post valueForKeyPath:@"status.text"] componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsJoinedByString:@" "];
    NSString *content = [post valueForKeyPath:@"content.text"];
    NSString *postID = [post valueForKeyPath:@"id.text"];
    content = [self removeParsingErrors:content];
    Post *newPost = [Post postWithAuthor:author
                                    rank:rank
                              lastPosted:lastPosted
                                 content:content
                                  postID:postID];
    return newPost;
}

+ (NSString *)removeParsingErrors:(NSString *)parsedString
{
    NSString *utf8String = [parsedString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *heading = @"<font face='Helvetica' size='2'>";
    parsedString = [NSString stringWithFormat:@"%@<p>%@</p>",heading,utf8String];
    parsedString = [parsedString stringByReplacingOccurrencesOfString:@"<br/>" withString:@"<br>"];
    parsedString = [parsedString stringByReplacingOccurrencesOfString:@"<i/>" withString:@"</i>"];
    parsedString = [parsedString stringByReplacingOccurrencesOfString:@"<b/>" withString:@"</b>"];
    parsedString = [parsedString stringByReplacingOccurrencesOfString:@"<img" withString:@"<img width=\"100%\""];
    return parsedString;
}

@end
