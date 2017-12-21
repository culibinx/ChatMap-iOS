//
//  AppDelegate.m
//  ChatMap
//
//  Created by culibinx@gmail.com on 26.06.17.
//  Copyright © 2017 culibinx@gmail.com. All rights reserved.
//

#import "AppDelegate.h"
#import "BackgroundTask.h"
#import "AppCore.h"

@interface AppDelegate ()
{
    BackgroundTask * _bgTask;
}
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:600];
    
    UNAuthorizationOptions authOptions =
        UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge;
    [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:authOptions completionHandler:^(BOOL granted, NSError * _Nullable error) {
    }];
    [self clearAllNotifications:application];
    
    _bgTask =[[BackgroundTask alloc] init];
    
    return YES;
}

#pragma mark common methods

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    POST_NOTIFICATION(kUpdateSettings, @{});
    
    if (ON_NOTIFICATION_POINT || ON_NOTIFICATION_ROOM) {
        [_bgTask startBackgroundTasks:2 target:self selector:@selector(backgroundCallback:)];
    }
}

- (void)backgroundCallback:(id)sender
{
    /*
    float remaining = [UIApplication sharedApplication].backgroundTimeRemaining;
    NSString *string = [NSString stringWithFormat:@"%.1f", remaining];
    NSLog(@"%@",string);
    */
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    
    [_bgTask stopBackgroundTask];
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [self clearAllNotifications:application];
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)clearAllNotifications:(UIApplication *)application
{
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center removeAllPendingNotificationRequests];
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
}

@end
