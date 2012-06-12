//
//  AppDelegate.m
//  BurgerTime
//
//  Created by Nathaniel Griswold on 1/24/12.
//  Copyright (c) 2012 Nathaniel Griswold. All rights reserved.
//

#import "AppDelegate.h"
#import <Socialize/Socialize.h>

@implementation AppDelegate

@synthesize window = _window;
@synthesize viewController = _viewController;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSString* appID = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
    if ([appID isEqualToString:@"com.getsocialize.simplesample"]) {
        [Socialize storeFacebookAppId:@"193049117470843"];
        [Socialize storeConsumerKey:@"8d4afa04-0ab8-4173-891a-5027c8b827f6"];
        [Socialize storeConsumerSecret:@"25957111-3f42-413d-8d5b-a602c32680d5"];
    } else if ([appID isEqualToString:@"com.getsocialize.simplesamplestage"]) {
        [Socialize storeFacebookAppId:@"210343369066525"];
        [Socialize storeConsumerKey:@"e8d3c6b2-6cef-483d-ba13-1127030a5575"];
        [Socialize storeConsumerSecret:@"a3f06467-cc9a-4b92-a9a3-a1f04599d073"];
    }

    [Socialize storeTwitterConsumerKey:@"PlOb10oxhUAy2CFuUo5Ew"];
    [Socialize storeTwitterConsumerSecret:@"lBJQuDVCvK769tmMpzC3kSdr2gcOu0Q18ywPtTt2dk"];
    //your application specific code
    // Override point for customization after application launch.
    [application registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound)]; 

    [Socialize storeAnonymousAllowed:YES];
    
    [Socialize setEntityLoaderBlock:^(UINavigationController *navigationController, id<SocializeEntity>entity) {
        SampleEntityLoader *entityLoader = [[SampleEntityLoader alloc] initWithEntity:entity];
        [navigationController pushViewController:entityLoader animated:YES];
    }];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    self.viewController = [[ViewController alloc] init];
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];

    NSDictionary *notification = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (notification != nil) {
        if ([Socialize handleNotification:notification]) {
            NSLog(@"Socialize handled the notification on app launch.");
        } else {
            NSLog(@"Socialize did not handle the notification on app launch.");
        }
    }
    
    return YES;
}
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {    
    return [Socialize handleOpenURL:url];
}							
- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken
{
    NSLog(@"Sucessfully registered with apple: %@", [deviceToken description]);
    [Socialize registerDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    NSLog(@"Handling notiication from didReceiveRemoteNotification");

    if ([Socialize handleNotification:userInfo]) {
        return;
    }
    // Nonsocialize notification handling goes here
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
    NSLog(@"Error Register Notifications: %@", [error localizedDescription]);
} 



@end
