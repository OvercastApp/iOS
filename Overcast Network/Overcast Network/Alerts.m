//
//  Alerts.m
//  Overcast Network
//
//  Created by Yichen Cao on 3/28/14.
//  Copyright (c) 2014 Schem. All rights reserved.
//

#import "Alerts.h"

@implementation Alerts

+ (void)sendConnectionFailureAlert
{
    UIAlertView *failedAlert = [[UIAlertView alloc] initWithTitle:@"Cannot Connect :-("
                                                          message:@"Check your internet connection please :D"
                                                         delegate:nil
                                                cancelButtonTitle:nil
                                                otherButtonTitles:@"I'll fix it!", nil];
    [failedAlert show];
}

@end
