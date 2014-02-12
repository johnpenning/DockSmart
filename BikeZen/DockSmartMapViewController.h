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

extern NSString *kRefreshDataNotif;
extern NSString *kStationList;

typedef NS_ENUM(NSInteger, BikingStateType) {
    BikingStateInactive = 0,
    BikingStatePreparingToBike,
    BikingStateActive,
    BikingStateTrackingDidStop,
};

@class LocationDataController;

@interface DockSmartMapViewController : UIViewController <MKMapViewDelegate, UIToolbarDelegate, UIActionSheetDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@property (strong, nonatomic) LocationDataController *dataController;
@property BikingStateType bikingState;
@property (weak, nonatomic) IBOutlet UIToolbar *topMapToolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *updateLocationButton;

@end
