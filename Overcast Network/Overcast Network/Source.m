//
//  Source.m
//  Overcast Network
//
//  Created by Yichen Cao on 1/4/14.
//  Copyright (c) 2014 Schem. All rights reserved.
//

#import "Source.h"

@implementation Source

- (NSString *)getSourceFromURL:(NSURL *)url {
    NSError *error = nil;
#warning Blocking Main Thread
    NSString *source = [NSString stringWithContentsOfURL:url
                                                      encoding:NSUTF8StringEncoding
                                                         error:&error];
    if(error) {
        NSLog(@"Retrieving forum source failed with error: \n%@", error);
    }
    return source;
}
@end
