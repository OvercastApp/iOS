//
//  OCNHTTPRequest.m
//  TestOCNLogin
//
//  Created by Yichen Cao on 4/16/14.
//  Copyright (c) 2014 Schem. All rights reserved.
//

#import "OCNHTTPRequest.h"

@implementation OCNHTTPRequest

+ (void)loginWithUsername:(NSString *)username password:(NSString *)password cookie:(NSString *)cookie sender:(id)sender
{
    NSString *loginPOST = [NSString stringWithFormat:@"utf8=✓&user[email]=%@&user[password]=%@&user[remember_me]=1&commit=Login",username,password];
    NSURL *loginPOSTURL = [NSURL URLWithString:@"https://oc.tc/users/sign_in"];
    NSArray *headers = @[@{@"HTTPHeaderField": @"Referer",
                           @"Value": @"https://oc.tc/users/sign_in"},
                         @{@"HTTPHeaderField": @"Origin",
                           @"Value": @"https://oc.tc"},
                         @{@"HTTPHeaderField": @"Cookie",
                           @"Value": cookie}];
    
    [NSURLConnection connectionWithRequest:[HTTPRequest requestWithType:@"POST"
                                                                request:loginPOST
                                                                withURL:loginPOSTURL
                                                                headers:headers
                                                             identifier:@"Login"]
                                  delegate:sender];
}

+ (void)newTopic:(NSString *)topic content:(NSString *)content URL:(NSString *)url cookie:(NSString *)cookie sender:(id)sender
{
    NSString *topicPOST = [NSString stringWithFormat:@"utf8=✓&topic[subject]=%@&topic[posts_attributes][0][text]=%@&_wysihtml5_mode=1&commit=Create Topic",[topic stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],[content stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSURL *topicPOSTURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/create",url]];
    NSArray *headers = @[@{@"HTTPHeaderField": @"Referer",
                           @"Value": [NSString stringWithFormat:@"%@/new",url]},
                         @{@"HTTPHeaderField": @"Origin",
                           @"Value": @"https://oc.tc"},
                         @{@"HTTPHeaderField": @"Cookie",
                           @"Value": cookie}];
    
    [NSURLConnection connectionWithRequest:[HTTPRequest requestWithType:@"POST"
                                                                request:topicPOST
                                                                withURL:topicPOSTURL
                                                                headers:headers
                                                             identifier:@"Topic"]
                                  delegate:sender];
}

+ (void)newPostWithContent:(NSString *)content URL:(NSString *)url cookie:(NSString *)cookie sender:(id)sender
{
    NSString *postPOST = [NSString stringWithFormat:@"utf8=✓&post[text]=%@&_wysihtml5_mode=1&commit=Reply",[content stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSURL *postPOSTURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/posts",url]];
    NSArray *headers = @[@{@"HTTPHeaderField": @"Referer",
                           @"Value": [NSString stringWithFormat:@"%@/posts/new",url]},
                         @{@"HTTPHeaderField": @"Origin",
                           @"Value": @"https://oc.tc"},
                         @{@"HTTPHeaderField": @"Cookie",
                           @"Value": cookie}];
    
    [NSURLConnection connectionWithRequest:[HTTPRequest requestWithType:@"POST"
                                                                request:postPOST
                                                                withURL:postPOSTURL
                                                                headers:headers
                                                             identifier:@"Post"]
                                  delegate:sender];
}

+ (void)newReplyToPost:(NSString *)postID WithContent:(NSString *)content URL:(NSString *)url cookie:(NSString *)cookie sender:(id)sender
{
    NSString *convertedContent = [[content componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsJoinedByString:@"<br>"];
    NSString *replyPOST = [NSString stringWithFormat:@"utf8=✓&post[text]=%@&post[reply_to_id]=%@&_wysihtml5_mode=1&commit=Reply",[convertedContent stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],postID];
    NSURL *replyPOSTURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/posts",url]];
    NSArray *headers = @[@{@"HTTPHeaderField": @"Referer",
                           @"Value": [NSString stringWithFormat:@"%@/posts/new?reply_to_id=%@",url,postID]},
                         @{@"HTTPHeaderField": @"Origin",
                           @"Value": @"https://oc.tc"},
                         @{@"HTTPHeaderField": @"Cookie",
                           @"Value": cookie}];
    
    [NSURLConnection connectionWithRequest:[HTTPRequest requestWithType:@"POST"
                                                                request:replyPOST
                                                                withURL:replyPOSTURL
                                                                headers:headers
                                                             identifier:@"Reply"]
                                  delegate:sender];
}

@end
