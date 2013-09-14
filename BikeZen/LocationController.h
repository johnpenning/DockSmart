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
#import "DockSmartSettingsViewController.h"

// protocol for sending location updates to another view controller
@protocol LocationControllerDelegate
@required
- (void)locationUpdate:(CLLocation*)location;
@end

@interface LocationController : NSObject <CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager* locationManager;
@property (nonatomic, strong) CLLocation* location;
@property (nonatomic, weak) id delegate;

- (void)startUpdatingCurrentLocation;
- (void)stopUpdatingCurrentLocation;

+ (LocationController*)sharedInstance; // Singleton method

@end
