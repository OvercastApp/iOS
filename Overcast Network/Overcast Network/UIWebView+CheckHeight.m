//
//  UIWebView+CheckHeight.m
//  Overcast Network
//
//  Created by Yichen Cao on 4/18/14.
//  Copyright (c) 2014 Schem. All rights reserved.
//

#import "UIWebView+CheckHeight.h"

@implementation UIWebView (CheckHeight)

- (int)checkHeight
{
    CGRect frame = self.frame;
    frame.size.height = 1;
    self.frame = frame;
    CGSize fittingSize = [self sizeThatFits:CGSizeZero];
    frame.size = fittingSize;
    self.frame = frame;
    return frame.size.height;
}

@end
