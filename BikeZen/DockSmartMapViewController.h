//
//  DockSmartMapViewController.h
//  DockSmart
//
//  Created by John Penning on 4/30/13.
//  Copyright (c) 2013 John Penning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface DockSmartMapViewController : UIViewController <MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
//@property NSDate *lastDataUpdate;
//@property (weak, nonatomic) IBOutlet UISegmentedControl *bikeDockViewSwitch;
@property (nonatomic) NSMutableArray *stationList;
//@property (nonatomic, retain, readonly) NSDateFormatter *dateFormatter;

- (void)insertStations:(NSArray *)stations;   // addition method of earthquakes (for KVO purposes)
//- (void)insertStationList:(NSArray *)array atIndexes:(NSIndexSet *)indexes
- (void)plotStationPosition:(NSArray *)stationList;

@end
