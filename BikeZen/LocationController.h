//
//  LocationController.h
//  DockSmart
//
//  Created by John Penning on 9/14/13.
//  Copyright (c) 2013 John Penning. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "LocationDataController.h"
#import "DockSmartMapViewController.h"
#import "DockSmartLogViewController.h"

extern NSString *kLocationUpdateNotif;
extern NSString *kNewLocationKey;
//extern NSString *kRegionUpdateNotif;
extern NSString *kRegionEntryNotif;
extern NSString *kRegionExitNotif;
extern NSString *kNewRegionKey;

@interface LocationController : NSObject <CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager* locationManager;
@property (nonatomic, strong) CLLocation* location;
@property (nonatomic, weak) id delegate;

- (void)startUpdatingCurrentLocation;
- (void)stopUpdatingCurrentLocation;
- (BOOL)registerRegionWithCoordinate:(CLLocationCoordinate2D)coordinate radius:(CLLocationDistance)radius identifier:(NSString*)identifier accuracy:(CLLocationAccuracy)accuracy;
- (void)stopAllRegionMonitoring;

+ (LocationController*)sharedInstance; // Singleton method

@end
