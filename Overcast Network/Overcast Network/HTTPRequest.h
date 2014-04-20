//
//  HTTPRequest.h
//  TestOCNLogin
//
//  Created by Yichen Cao on 4/15/14.
//  Copyright (c) 2014 Schem. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSURLRequest+Identifier.h"

@interface HTTPRequest : NSObject

+ (NSURLRequest *)requestWithType:(NSString *)type request:(NSString *)request withURL:(NSURL *)URL headers:(NSArray *)headers identifier:(NSString *)identifier;

@end
