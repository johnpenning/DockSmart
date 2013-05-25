//
//  DockSmartAppDelegate.h
//  DockSmart
//
//  Created by John Penning on 4/30/13.
//  Copyright (c) 2013 John Penning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@class Station, DockSmartMapViewController;

@interface DockSmartAppDelegate : UIResponder <UIApplicationDelegate, NSXMLParserDelegate, CLLocationManagerDelegate>

@property (strong, nonatomic) UIWindow *window;
//@property (strong, nonatomic) IBOutlet DockSmartMapViewController *mapViewController;

//@property (strong, nonatomic) CLLocationManager *locationManager;

@end
