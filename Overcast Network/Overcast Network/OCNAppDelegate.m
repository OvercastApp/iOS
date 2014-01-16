//
//  OCNAppDelegate.m
//  Overcast Network
//
//  Created by Yichen Cao on 1/3/14.
//  Copyright (c) 2014 Schem. All rights reserved.
//

#import "OCNAppDelegate.h"

@implementation OCNAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
        UITabBar *tabBar = tabBarController.tabBar;
        UITabBarItem *tabBarItem1 = [tabBar.items objectAtIndex:0];
        UITabBarItem *tabBarItem2 = [tabBar.items objectAtIndex:1];
        
        tabBarItem1.selectedImage = [[UIImage imageNamed:@"ForumsSelected.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        tabBarItem1.image = [[UIImage imageNamed:@"Forums.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        tabBarItem1.title = @"Forums";
        
        tabBarItem2.selectedImage = [[UIImage imageNamed:@"ProfileSelected.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        tabBarItem2.image = [[UIImage imageNamed:@"Profile.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        tabBarItem2.title = @"Profile";
    }

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
        UINavigationController *navigationController = [[splitViewController viewControllers] lastObject];
        splitViewController.delegate = (id)navigationController.topViewController;
    }
    
    // Override point for customization after application launch.
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
