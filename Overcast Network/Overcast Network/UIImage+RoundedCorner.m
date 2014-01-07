//
//  UIImage+RoundedCorner.m
//  Overcast Network
//
//  Created by Yichen Cao on 1/7/14.
//  Copyright (c) 2014 Schem. All rights reserved.
//

#import "UIImage+RoundedCorner.h"

@implementation UIImage (RoundedCorner)

- (UIImage *)imageWithRoundedCornersRadius:(float)radius
{
    // Begin a new image that will be the new image with the rounded corners
    UIGraphicsBeginImageContextWithOptions(self.size, NO, 0);
    
    // Add a clip before drawing anything, in the shape of an rounded rect
    CGRect rect = CGRectMake(0, 0, self.size.width, self.size.height);
    [[UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:radius] addClip];
    
    // Draw your image
    [self drawInRect:rect];
    
    // Get the image, here setting the UIImageView image
    UIImage *roundedImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // Lets forget about that we were drawing
    UIGraphicsEndImageContext();
    
    return roundedImage;
}

@end
