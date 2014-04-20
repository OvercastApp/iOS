//
//  HTTPRequest.m
//  TestOCNLogin
//
//  Created by Yichen Cao on 4/15/14.
//  Copyright (c) 2014 Schem. All rights reserved.
//

#import "HTTPRequest.h"

@implementation HTTPRequest

+ (NSURLRequest *)requestWithType:(NSString *)type request:(NSString *)request withURL:(NSURL *)URL headers:(NSArray *)headers identifier:(NSString *)identifier
{
    NSData *requestData = [request dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *requestLength = [NSString stringWithFormat:@"%d",[requestData length]];
    NSURL *requestURL = URL;
    NSMutableURLRequest *URLRequest = [[NSMutableURLRequest alloc] init];
    
    //URL and request data
    [URLRequest setURL:requestURL];
    [URLRequest setHTTPMethod:type];
    [URLRequest setHTTPBody:requestData];
    
    //Headers
    for (NSDictionary *header in headers) {
        [URLRequest setValue:[header objectForKey:@"Value"]
          forHTTPHeaderField:[header objectForKey:@"HTTPHeaderField"]];
    }
    [URLRequest setValue:requestLength
      forHTTPHeaderField:@"Content-Length"];
    [URLRequest setValue:@"application/x-www-form-urlencoded"
           forHTTPHeaderField:@"Content-Type"];
    [URLRequest setValue:@"Mozilla/5.0 (Windows NT 6.3; WOW64; rv:28.0) Gecko/20100101 Firefox/28.0"
           forHTTPHeaderField:@"User-Agent"];
    
    URLRequest.identifier = identifier;
    return URLRequest;
}

@end
