//
//  SCAppDelegate.h
//  Drool
//
//  Created by Nils Munch on 07/11/12.
//  Copyright (c) 2012 NilsMunch. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SCViewController;
@class DemoViewController;

@interface SCAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) DemoViewController *viewController;

@end
