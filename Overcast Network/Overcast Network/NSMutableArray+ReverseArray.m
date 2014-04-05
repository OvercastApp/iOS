//
//  NSMutableArray+ReverseArray.m
//  Overcast Network
//
//  Created by Yichen Cao on 3/29/14.
//  Copyright (c) 2014 Schem. All rights reserved.
//

#import "NSMutableArray+ReverseArray.h"

@implementation NSMutableArray (ReverseArray)

- (void)reverseArray {
    if ([self count]) {
        NSUInteger firstHalf = 0;
        NSUInteger secondHalf = [self count] - 1;
        while (firstHalf < secondHalf) {
            [self exchangeObjectAtIndex:firstHalf
                               withObjectAtIndex:secondHalf];
            firstHalf++;
            secondHalf--;
        }
    }
}

@end
