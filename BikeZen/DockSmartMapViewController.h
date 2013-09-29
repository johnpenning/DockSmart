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

extern NSString *kRefreshTappedNotif;
extern NSString *kTrackingStartedNotif;
extern NSString *kTrackingStoppedNotif;
extern NSString *kStationList;

//extern NSString *kInsertStations

typedef NS_ENUM(NSInteger, BikingStateType) {
    BikingStateInactive = 0,
    BikingStatePreparingToBike,
    BikingStateActive,
};

@class LocationDataController;

@interface DockSmartMapViewController : UIViewController <MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
//@property NSDate *lastDataUpdate;
//@property (weak, nonatomic) IBOutlet UISegmentedControl *bikeDockViewSwitch;
//@property (nonatomic, retain, readonly) NSDateFormatter *dateFormatter;

- (void)insertStations:(NSArray *)stations;   // addition method of stations (for KVO purposes)
//- (void)insertStationList:(NSArray *)array atIndexes:(NSIndexSet *)indexes
//- (void)plotStationPosition:(NSArray *)stationList;
//- (void)updateDistancesFromUserLocation:(CLLocation *)location;

@property (strong, nonatomic) LocationDataController *dataController;
@property BikingStateType bikingState;

@end
