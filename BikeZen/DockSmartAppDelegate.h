//
//  DockSmartAppDelegate.h
//  DockSmart
//
//  Created by John Penning on 4/30/13.
//  Copyright (c) 2013 John Penning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "LocationController.h"
#import "DSHTTPSessionManager.h"

extern NSString * const kAddStationsNotif;
extern NSString * const kStationResultsKey;
extern NSString * const kStationErrorNotif;
extern NSString * const kStationsMsgErrorKey;

@class Station, DockSmartMapViewController;

@interface DockSmartAppDelegate : UIResponder <UIApplicationDelegate, UIStateRestoring>

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic) NSString *currentCityUrl;

@end
