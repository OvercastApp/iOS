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
    self.mode = 1;
    NSURL *forumURL = [NSURL URLWithString:@"https://oc.tc/forums"];
    if (!self.mode) {
        forumURL = [NSURL URLWithString:@"http://maxsa.li/pigu/forumparser.php?link=http://oc.tc/forums"];
    }
    [self startFetchingURL:forumURL];
}

#pragma mark Official

- (void)startFetchingURL:(NSURL *)url {
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:request
                                                    completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
                                                        if (!error) {
                                                            NSString *source = [NSString stringWithContentsOfURL:location
                                                                                                      encoding:NSUTF8StringEncoding
                                                                                                         error:NULL];
                                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                                if (self.mode) {
                                                                    [self startRegexSearch:source];
                                                                }
                                                            });
                                                        }
                                                        else {
                                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                                NSLog(@"Retrieving forum source failed with error: \n%@", error);
                                                                [self sendFailedAlert];
                                                            });
                                                        }
                                                    }];
    [task resume];
}

- (void)startRegexSearch:(NSString *)source
{
    NSString *topicPattern = @"<a href=\"/forums/topics/(.*)\">(.*)</a>";
    NSString *authorPattern = @"'/.{1,16}' ";
    NSString *colorPattern = @"' style='color:(.*)'";
    
    NSString *stringSource = [NSString stringWithFormat:@"%@",source];
    if (stringSource && self.mode) {
        [self findFromSource:source
                 topicSearch:[self getResultsFromRegexSearch:topicPattern withSource:source]
                authorSearch:[self getResultsFromRegexSearch:authorPattern withSource:source]
                 colorSearch:[self getResultsFromRegexSearch:colorPattern withSource:source]];
    }
    else [self sendFailedAlert];
}

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
    else {
        [self sendFailedAlert];
    }
    return nil;
}

- (void)findFromSource:(NSString *)source topicSearch:(NSArray *)topicResult authorSearch:(NSArray *)authorResult colorSearch:(NSArray *)colorResult
{
    if (source) {
        self.topics = nil;
        self.topics = [[NSMutableArray alloc] initWithArray:@[]];
        int index = 0;
        NSTextCheckingResult *authorMatchNSTCR = [[NSTextCheckingResult alloc] init];
        NSTextCheckingResult *colorMatchNSTCR = [[NSTextCheckingResult alloc] init];
        for (NSTextCheckingResult *titleMatchNSTCR in topicResult) {
            authorMatchNSTCR = [authorResult objectAtIndex:index];
            colorMatchNSTCR = [colorResult objectAtIndex:index];
            
            Topic *newTopic = [[Topic alloc] init];
            
            NSString *titleMatch = [source substringWithRange:titleMatchNSTCR.range];
            NSString *authorMatch = [source substringWithRange:authorMatchNSTCR.range];
            NSString *colorMatch = [source substringWithRange:colorMatchNSTCR.range];
            
            newTopic.title = [titleMatch substringWithRange:NSMakeRange(50,[titleMatch length] - 54)];
            newTopic.topicID = [titleMatch substringWithRange:NSMakeRange(24,24)];
            newTopic.author = [authorMatch substringWithRange:NSMakeRange(2,[authorMatch length] - 4)];
            NSString *colorMatchString = [colorMatch substringWithRange:NSMakeRange(16, [colorMatch length] - 17)];
            
            if ([colorMatchString isEqualToString:@"#FA0"])newTopic.color = [UIColor orangeColor];
            else if ([colorMatchString isEqualToString:@"#F55"]) newTopic.color = [UIColor redColor];
            else if ([colorMatchString isEqualToString:@""]) newTopic.color = [UIColor blueColor];
            else newTopic.color = [UIColor blackColor];
            
            NSLog(@"Found entry: \"%@\" with id \"%@\" by %@",newTopic.title,newTopic.topicID,newTopic.author);
            [self.topics addObject:newTopic];
            index += 2;
        }
        [self sendRefreshUINotification:self];
    }
    else [self sendFailedAlert];
}

#pragma mark XML 3rd Party

- (void)startFetchingXMLURL:(NSURL *)url {
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:request
                                                    completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
                                                        if (!error) {
                                                            NSXMLParser *XML = [[NSXMLParser alloc] initWithContentsOfURL:location];
                                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                                if (self.mode) {
                                                                    [self startXMLParse:XML];
                                                                }
                                                            });
                                                        }
                                                        else NSLog(@"Retrieving forum source failed with error: \n%@", error);
                                                    }];
    [task resume];
}

- (void)startXMLParse:(NSXMLParser *)XML {
    
}

#pragma mark Misc

- (void)sendRefreshUINotification:(id)sender {
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
