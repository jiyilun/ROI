/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  Application delegate.
  
 */

#import "AAPLAppDelegate.h"

@implementation AAPLAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.

    [NSThread sleepForTimeInterval:3.0];
    return YES;
}

@end
