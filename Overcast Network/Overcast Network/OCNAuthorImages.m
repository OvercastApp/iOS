//
//  OCNAuthorImages.m
//  Overcast Network
//
//  Created by Yichen Cao on 4/19/14.
//  Copyright (c) 2014 Schem. All rights reserved.
//

#import "OCNAuthorImages.h"

#define OCN_AVATAR @"https://avatar.oc.tc/%@/48.png"

@implementation OCNAuthorImages

- (NSMutableDictionary *)authorImages
{
    if (!_authorImages) {
        _authorImages = [[NSMutableDictionary alloc] init];
    }
    return _authorImages;
}

- (void)getImageForAuthor:(NSString *)author source:(int)source
{
    dispatch_queue_t imageQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
    dispatch_async(imageQueue, ^(void) {
        NSString *sourceURL = [[NSString alloc] init];
        switch (source) {
            case 0:
                sourceURL = [NSString stringWithFormat:@"%@avatar.php?name=%@&size=48",SOURCE,author];
                break;
                
            case 1:
                sourceURL = [NSString stringWithFormat:OCN_AVATAR,author];
                break;
        }
        NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:sourceURL]];
        UIImage* image = [[UIImage alloc] initWithData:imageData];
        if (image) {
            dispatch_async(dispatch_get_main_queue(), ^{
                (self.authorImages)[author] = image;
                [self.delegate imageFinishedLoadingForAuthor:author];
            });
        }
    });
}

- (id)initSingleton
{
    if ((self = [super init]))
    {
        // Initialization code here.
    }

    return self;
}

// Persistent instance.
static OCNAuthorImages *_default = nil;

+ (OCNAuthorImages *)instance
{
    
    // Small optimization to avoid wasting time after the singleton being initialized.
    if (_default != nil)
    {
        return _default;
    }
    static dispatch_once_t safer;
    dispatch_once(&safer, ^(void)
                  {
                      _default = [[OCNAuthorImages alloc] initSingleton];
                  });
    return _default;
}

@end
