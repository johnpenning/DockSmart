//
//  DockSmartAppDelegate.h
//  DockSmart
//
//  Created by John Penning on 4/30/13.
//  Copyright (c) 2013 John Penning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "LocationController.h"

@class Station, DockSmartMapViewController;

@interface DockSmartAppDelegate : UIResponder <UIApplicationDelegate, NSXMLParserDelegate, UIStateRestoring>

@property (strong, nonatomic) UIWindow *window;
//@property (strong, nonatomic) IBOutlet DockSmartMapViewController *mapViewController;

//CLLocationManager properties
//@property (strong, nonatomic) CLLocationManager *locationManager;
//@property (readonly) CLLocationCoordinate2D userCoordinate;

@property (nonatomic) NSString *currentCityUrl;

- (void)setNetworkActivityIndicatorVisible:(BOOL)setVisible;

@end
