//
//  DockSmartMapViewController.m
//  DockSmart
//
//  Created by John Penning on 4/30/13.
//  Copyright (c) 2013 John Penning. All rights reserved.
//

//#import <UIKit/UIKit.h>
//#import <MapKit/MapKit.h>
#import "DockSmartMapViewController.h"
#import "DockSmartDestinationsMasterViewController.h"
#import "define.h"
#import "Station.h"
#import "LocationDataController.h"
#import "ParseOperation.h"

// NSNotification name for reporting that refresh was tapped
NSString *kRefreshTappedNotif = @"RefreshTappedNotif";
NSString *kStationList = @"stationList";

// NSNotification userInfo key for obtaining command to refresh the station list
//NSString *kRefreshStationsKey = @"RefreshStationsKey";

@interface DockSmartMapViewController ()
- (IBAction)refeshTapped:(id)sender;
@end

@implementation DockSmartMapViewController

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    // KVO: listen for changes to our station data source for map view updates
//    [self addObserver:self forKeyPath:kStationList options:0 context:NULL];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(addStations:)
                                                 name:kAddStationsNotif
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(startBiking:)
                                                 name:kStartBikingNotif
                                               object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
//    self.stationList = [NSMutableArray array];
    self.dataController = [[LocationDataController alloc] init];
    
//    // KVO: listen for changes to our station data source for map view updates
    [self addObserver:self forKeyPath:kStationList options:0 context:NULL];
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(addStations:)
//                                                 name:kAddStationsNotif
//                                               object:nil];
    
    //Define the initial zoom location (Dupont Circle for now)
    CLLocationCoordinate2D zoomLocation = CLLocationCoordinate2DMake((CLLocationDegrees)DUPONT_LAT, (CLLocationDegrees)DUPONT_LONG);
    
//    zoomLocation.latitude = DUPONT_LAT;
//    zoomLocation.longitude = DUPONT_LONG;
    
    //define the initial view region -> about the size of the neighborhood:
//    MKCoordinateRegion viewRegion = [self.mapView regionThatFits:MKCoordinateRegionMakeWithDistance(zoomLocation, 2*METERS_PER_MILE, 2*METERS_PER_MILE)];
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(zoomLocation, 2*METERS_PER_MILE, 2*METERS_PER_MILE);
    
    [self.mapView setRegion:viewRegion animated:YES];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//- (void)viewWillAppear:(BOOL)animated
//{
//    [super viewWillAppear:animated];
//    //Define the initial zoom location (Dupont Circle for now)
//    CLLocationCoordinate2D zoomLocation;// = CLLocationCoordinate2DMake((CLLocationDegrees)DUPONT_LAT, (CLLocationDegrees)DUPONT_LONG);
//    
//    zoomLocation.latitude = DUPONT_LAT;
//    zoomLocation.longitude = DUPONT_LONG;
//    
//    //define the initial view region -> about the size of the neighborhood:
////    MKCoordinateRegion viewRegion = [_mapView regionThatFits:MKCoordinateRegionMakeWithDistance(zoomLocation, 2*METERS_PER_MILE, 2*METERS_PER_MILE)];
//    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(zoomLocation, 2*METERS_PER_MILE, 2*METERS_PER_MILE);
//    
//    [_mapView setRegion:viewRegion animated:YES];
//}

//- (void)mapViewWillStartLoadingMap:(MKMapView *)mapView
//{
//    //Define the initial zoom location (Dupont Circle for now)
//    CLLocationCoordinate2D zoomLocation;// = CLLocationCoordinate2DMake((CLLocationDegrees)DUPONT_LAT, (CLLocationDegrees)DUPONT_LONG);
//    
//    zoomLocation.latitude = DUPONT_LAT;
//    zoomLocation.longitude = DUPONT_LONG;
//    
//    //define the initial view region -> about the size of the neighborhood:
//    MKCoordinateRegion viewRegion = [mapView regionThatFits:MKCoordinateRegionMakeWithDistance(zoomLocation, 2*METERS_PER_MILE, 2*METERS_PER_MILE)];
////    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(zoomLocation, 2*METERS_PER_MILE, 2*METERS_PER_MILE);
//    
//    [mapView setRegion:viewRegion animated:NO];
//}

- (void)viewDidUnload {
//    [self setBikeDockViewSwitch:nil];
//    [self setRefreshButtonTapped:nil];
    [super viewDidUnload];
//    
//    self.dataController.stationList = nil;
//    
//    [self unregisterFromKVO];
}

- (void)dealloc
{
    self.dataController.stationList = nil;
    
    [self unregisterFromKVO];
}

- (void)refreshWasTapped
{
    assert([NSThread isMainThread]);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kRefreshTappedNotif
                                                        object:self
                                                      userInfo:nil];
}

- (void)plotStationPosition:(NSArray *)stationList {
    for (id<MKAnnotation> annotation in self.mapView.annotations) {
        [self.mapView removeAnnotation:annotation];
    }
    
    for (Station* station in stationList)
    {
        //TODO: if we should show this... (i.e., if it's public: write a method to determine this. gray it out if it's locked?)
        //add to the map
        [self.mapView addAnnotation:station];
    }

//    NSDictionary *root = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
//    NSArray *data = [root objectForKey:@"data"];
//    
//    for (NSArray *row in data) {
//        NSNumber *latitude = row[21][1];
//        NSNumber *longitude = row[21][2];
//        NSString *crimeDescription = row[17];
//        NSString *address = row[13];
//        
//        CLLocationCoordinate2D coordinate;
//        coordinate.latitude = latitude.doubleValue;
//        coordinate.longitude = longitude.doubleValue;
//        MyLocation *annotation = [[MyLocation alloc] initWithName:crimeDescription address:address coordinate:coordinate];
//        [self.mapView addAnnotation:annotation];
//    }
    
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    static NSString *identifier = @"Station";
    
    if ([annotation isKindOfClass:[Station class]]) {
        MKPinAnnotationView *annotationView = (MKPinAnnotationView *) [self.mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
        if (annotationView == nil) {
            annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
            annotationView.enabled = YES;
            annotationView.canShowCallout = YES;
//            annotationView.image = [UIImage imageNamed:@"arrest.png"];
            annotationView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
            annotationView.animatesDrop = YES;
        }
        else {
            annotationView.annotation = annotation;
        }
        
        return annotationView;
    }
    
    return nil;
}

//- (IBAction)refreshTapped:(id)sender
//{
//    [self performSelectorOnMainThread:@selector(refreshWasTapped:)
//                           withObject:nil
//                        waitUntilDone:NO];
//}

//- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
//{
//    Station *station = (Station*)view.annotation;
//    
//    NSDictionary *launchOptions = @{MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving};
//    [station.mapItem openInMapsWithLaunchOptions:launchOptions];
//}

#pragma mark -
#pragma mark KVO support

- (void)addStations:(NSNotification *)notif
{
    assert([NSThread isMainThread]);
    
    [self insertStations:[[notif userInfo] valueForKey:kStationResultsKey]];
}

- (void)insertStations:(NSArray *)stations
{
    // this will allow us as an observer to notified (see observeValueForKeyPath)
    // so we can update our MapView
    //
    [self willChangeValueForKey:kStationList];
//    [self.stationList addObjectsFromArray:stations];
    [self.dataController addLocationObjectsFromArray:stations toList:self.dataController.stationList];
    [self didChangeValueForKey:kStationList];
}

- (void)startBiking:(NSNotification *)notif
{
    assert([NSThread isMainThread]);

    //Make sure this view is showing (TODO: let the tableViewController handle this?)
//    [[self view] bringSubviewToFront:[self view]];
    
    //Refresh all station data to get the absolute latest nbBikes and nbEmptyDocks counts.
    //Equivalent to hitting Refresh:
    [[NSNotificationCenter defaultCenter] postNotificationName:kRefreshTappedNotif
                                                        object:self
                                                      userInfo:nil];
    
    //Figure out the three closest stations to the destination:
    //First sort by distance:
    [self.dataController setSortedStationList:[self.dataController sortLocationList:[self.dataController stationList] byMethod:LocationDataSortByDistance]];
    //Then grab the top 3:
    
    //Figure out the closest station to the user with at least one bike
    
    //Change the map view to show the current user location, and the start, end and backup end stations.
    //Hide the annotations for all other stations.
    //TODO: change the pin colors/sizes for start, end and backup end stations?
    
    //Start the timer, if we have one
    
    //Start tracking nbEmptyDocks by refreshing the data every minute until we manually stop
    //(or until the timer runs out, or until our geofence tells us we are at our destination)
    
}

//- (void)updateLocation:(NSNotification *)notif {
//    assert([NSThread isMainThread]);
//    
//    [self updateDistancesFromUserLocation:[[notif userInfo] valueForKey:kNewLocationKey]];
//}
//
//- (void)updateDistancesFromUserLocation:(CLLocation *)location
//{
//    
//}

- (void)registerForKVO {
	for (NSString *keyPath in [self observableKeypaths]) {
		[self addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionNew context:NULL];
	}
}

- (void)unregisterFromKVO {
	for (NSString *keyPath in [self observableKeypaths]) {
		[self removeObserver:self forKeyPath:keyPath];
	}
}

- (NSArray *)observableKeypaths {
	return [NSArray arrayWithObjects:kAddStationsNotif, kStationList, nil];
}

// listen for changes to the station list coming from our app delegate.
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    //Reload map view
    if (![NSThread isMainThread]) {
		[self performSelectorOnMainThread:@selector(plotStationPosition:) withObject:self.dataController.stationList waitUntilDone:NO];
    }
    else
    {
        [self plotStationPosition:self.dataController.stationList];
    }
}

- (IBAction)refeshTapped:(id)sender {
    [self performSelectorOnMainThread:@selector(refreshWasTapped)
                           withObject:nil
                        waitUntilDone:NO];
}

//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
//{
//    NSLog(@"Segue identifier: %@", [segue identifier]);
//    NSLog(@"Segue destination: %@", [[segue destinationViewController] title]);
//    
//    if ([[segue identifier] isEqualToString:@"Test"])
//    {
//        DockSmartDestinationsMasterViewController *vc = [segue destinationViewController];
//        //pass current station list to Destinations view controller
////        [vc setDataController:self.dataController];
//    };
//}

@end
