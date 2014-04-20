//
//  NSURLRequest+Identifier.m
//  TestOCNLogin
//
//  Created by Yichen Cao on 4/16/14.
//  Copyright (c) 2014 Schem. All rights reserved.
//

#import "NSURLRequest+Identifier.h"
#import <objc/runtime.h>

@implementation NSURLRequest (Identifier)

static char staticIdentifier;

- (NSString *)identifier
{
    return objc_getAssociatedObject(self, &staticIdentifier);
}

- (void)setIdentifier:(NSString *)identifier
{
    objc_setAssociatedObject(self, &staticIdentifier, identifier, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
