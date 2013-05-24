//
//  BikeZenAppDelegate.h
//  BikeZen
//
//  Created by John Penning on 4/30/13.
//  Copyright (c) 2013 John Penning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@class Station, BikeZenSecondViewController;

@interface BikeZenAppDelegate : UIResponder <UIApplicationDelegate, NSXMLParserDelegate, CLLocationManagerDelegate>

@property (strong, nonatomic) UIWindow *window;
//@property (strong, nonatomic) IBOutlet BikeZenSecondViewController *secondViewController;

//@property (strong, nonatomic) CLLocationManager *locationManager;

@end
