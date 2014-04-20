//
//  OCNAuthorImages.m
//  Overcast Network
//
//  Created by Yichen Cao on 4/19/14.
//  Copyright (c) 2014 Schem. All rights reserved.
//

#import "OCNAuthorImages.h"

#define MAXSALI_AVATAR @"http://ocnapp.maxsa.li/avatar.php?name=%@&size=48"
#define OCN_AVATAR @"https://avatar.oc.tc/%@/48.png"

@implementation OCNAuthorImages

- (void)getImageFromAuthor:(NSString *)author source:(int)source pathToReload:(NSIndexPath *)indexPath sender:(id)sender
{
    dispatch_queue_t imageQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
    dispatch_async(imageQueue, ^(void) {
        NSString *sourceURL = [[NSString alloc] init];
        switch (source) {
            case 0:
                sourceURL = [NSString stringWithFormat:MAXSALI_AVATAR,author];
                break;
                
            case 1:
                sourceURL = [NSString stringWithFormat:OCN_AVATAR,author];
                break;
        }
        NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:sourceURL]];
        UIImage* image = [[UIImage alloc] initWithData:imageData];
        /* Broken code
        if (image) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [sender.authorImages setObject:image
                                      forKey:author];
                if (!sender.refreshing) {
                    NSIndexPath *rowToReload = [NSIndexPath indexPathForRow:index
                                                                  inSection:section];
                    NSArray *rowsToReload = [[NSArray alloc] initWithObjects:rowToReload, nil];
                    [sender.tableView reloadRowsAtIndexPaths:rowsToReload
                                          withRowAnimation:UITableViewRowAnimationAutomatic];
                }
            });
        }
         */
    });
}

@end
