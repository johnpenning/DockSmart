//
//  DockSmartMapViewController.h
//  DockSmart
//
//  Created by John Penning on 4/30/13.
//  Copyright (c) 2013 John Penning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "LocationController.h"

extern NSString * const kRefreshDataNotif;
extern NSString * const kStationList;

typedef NS_ENUM(NSInteger, BikingStateType) {
    BikingStateInactive = 0,
    BikingStatePreparingToBike,
    BikingStateActive,
    BikingStateTrackingDidStop,
};

@class LocationDataController;

@interface DockSmartMapViewController : UIViewController <MKMapViewDelegate, UIToolbarDelegate, UIActionSheetDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

//LocationDataController object to keep track of all of our station lists
@property (strong, nonatomic) LocationDataController *dataController;
//Current biking trip state
@property BikingStateType bikingState;
//toolbar on top of the map... outlet for iOS7 compatibility
@property (weak, nonatomic) IBOutlet UIToolbar *topMapToolbar;
//Button that pans to the current user location on the map and updates the CLLocationManager location
@property (weak, nonatomic) IBOutlet UIBarButtonItem *updateLocationButton;

@end
