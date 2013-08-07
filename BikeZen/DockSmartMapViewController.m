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
#import "Address.h"
#import "LocationDataController.h"
#import "ParseOperation.h"

// NSNotification name for reporting that refresh was tapped
NSString *kRefreshTappedNotif = @"RefreshTappedNotif";
NSString *kStationList = @"stationList";

// NSNotification userInfo key for obtaining command to refresh the station list
//NSString *kRefreshStationsKey = @"RefreshStationsKey";

@interface DockSmartMapViewController ()
- (IBAction)refeshTapped:(id)sender;
- (IBAction)cancelTapped:(id)sender;
- (IBAction)startStopTapped:(id)sender;
- (IBAction)bikesDocksToggled:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *startStopButton;
@property (weak, nonatomic) IBOutlet UILabel *destinationDetailLabel;
@property (weak, nonatomic) IBOutlet UIImageView *bikeCrosshairImage;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UISegmentedControl *bikesDocksControl;

//location property for the center of the map:
@property (nonatomic) Address* mapCenterAddress;

//keep track of where we're going:
@property (nonatomic) MyLocation* finalDestination;
@property (nonatomic) Station* currentDestinationStation;
@property (nonatomic) Station* idealDestinationStation;

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
    self.mapCenterAddress = [[Address alloc] init];
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
    [self setStartStopButton:nil];
    [self setDestinationDetailLabel:nil];
    [self setBikeCrosshairImage:nil];
    [self setCancelButton:nil];
    [self setBikesDocksControl:nil];
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

#pragma mark -
#pragma mark MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    //TODO: place annotations on top of center bike image, if possible?
    
    //    static NSString *identifier = @"Station";
    
    if ([annotation isKindOfClass:[MyLocation class]]) {
        MyLocation* location = (MyLocation*)annotation;
        MKAnnotationView *annotationView;
        //        if ([location.annotationIdentifier isEqualToString:kDestinationLocation])
        //        {
        //            //Use a standard red MKPinAnnotationView for the final destination address, if it's not a station itself
        //            annotationView = (MKPinAnnotationView *) [self.mapView dequeueReusableAnnotationViewWithIdentifier:location.annotationIdentifier];
        //            if (annotationView == nil)
        //            {
        ////                MKPinAnnotationView* pinView = (MKPinAnnotationView *)annotationView;
        //                MKPinAnnotationView* pinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:location.annotationIdentifier];
        //                pinView.enabled = YES;
        //                pinView.canShowCallout = YES;
        //                pinView.pinColor = MKPinAnnotationColorRed;
        //                pinView.animatesDrop = YES;
        //                pinView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        //                annotationView = pinView;
        //            }
        //            else
        //            {
        //                annotationView.annotation = annotation;
        //            }
        //        }
        //        else
        //        {
        //Use a generic MKAnnotationView instead of a pin view so we can use our custom image
        annotationView = [self.mapView dequeueReusableAnnotationViewWithIdentifier:location.annotationIdentifier];
        
        if (annotationView == nil)
        {
            annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:location.annotationIdentifier];
            annotationView.enabled = YES;
            annotationView.canShowCallout = YES;
            annotationView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        }
        else
        {
            annotationView.annotation = annotation;
        }
        
        //Make sure that we're looking at a Station object
        if ([annotation isKindOfClass:[Station class]])
        {
            Station* station = (Station*)annotation;
            
            if ([location.annotationIdentifier isEqualToString:kSourceStation])
            {
                //Use green icons to denote a starting point, and show the number of bikes in the start station:
                //TODO create green icons for numbers above 20
                annotationView.image = [UIImage imageNamed:[NSString stringWithFormat:@"green%02d.png", (station.nbBikes <= 20 ? station.nbBikes : 20)]];
            }
            else if ([location.annotationIdentifier isEqualToString:kDestinationStation])
            {
                //Use red icons to denote destinations, and show the number of empty docks:
                annotationView.image = [UIImage imageNamed:[NSString stringWithFormat:@"red%02d.png", (station.nbEmptyDocks <= 99 ? station.nbEmptyDocks : 99)]];
            }
            else if ([location.annotationIdentifier isEqualToString:kAlternateStation])
            {
                //Use black icons to denote alternate stations:
                annotationView.image = [UIImage imageNamed:[NSString stringWithFormat:@"black%02d.png", (station.nbEmptyDocks <= 99 ? station.nbEmptyDocks : 99)]];
            }
            else if ([location.annotationIdentifier isEqualToString:kStation])
            {
                //Use black icons for generic stations in Inactive state as well, but switch between showing the number of bikes or docks based on the toggle control:
                NSInteger numberToShow = ([self.bikesDocksControl selectedSegmentIndex] == 0) ? station.nbBikes : station.nbEmptyDocks;
                annotationView.image = [UIImage imageNamed:[NSString stringWithFormat:@"black%02d.png", (numberToShow <= 99 ? numberToShow : 99)]];
            }
            //move the centerOffset up so the "point" of the image is pointed at the station location, instead of the image being centered directly over it:
            annotationView.centerOffset = CGPointMake(0, -13);
        }
        else if ([annotation isKindOfClass:[Address class]])
        {
            Address* address = (Address*)annotation;
            
            if ([address.annotationIdentifier isEqualToString:kDestinationLocation])
            {
                //do not show a separate destination annotation if it's the station the user is actually about to bike to
                if (address.coordinate.latitude == self.currentDestinationStation.coordinate.latitude && address.coordinate.longitude == self.currentDestinationStation.coordinate.longitude)
                {
                    return nil;
                }
                annotationView.image = [UIImage imageNamed:@"bikepointer.png"];
                annotationView.centerOffset = CGPointMake(0, 0);
            }
        }
        //        }
        
        return annotationView;
    }
    
    return nil;
}

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated
{
    if (animated == YES)
    {
        [self.destinationDetailLabel setText:nil];
//        [self.destinationDetailLabel setAlpha:0.5];
        [self.startStopButton setEnabled:NO];
    }
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    [self.startStopButton setEnabled:YES];
    
    if (self.bikingState == BikingStateInactive)
    {
        //geocode new location, then create a new MyLocation object
        CLLocationCoordinate2D centerCoord = self.mapView.centerCoordinate;
        CLLocation *centerLocation = [[CLLocation alloc] initWithLatitude:centerCoord.latitude longitude:centerCoord.longitude];
        CLGeocoder *geocoder = [[CLGeocoder alloc] init];
        
        [self.mapCenterAddress initCoordinateWithLatitude:centerCoord.latitude longitude:centerCoord.longitude];
        
        [geocoder reverseGeocodeLocation:centerLocation completionHandler:^(NSArray *placemarks, NSError *error) {
            if (error)
            {
                NSLog(@"Reverse geocode failed with error: %@", error);
                //still use the center coordinate for mapCenterAddress
                return;
            }
            
            [self.mapCenterAddress initWithPlacemark:[placemarks objectAtIndex:0] distanceFromUser:MKMetersBetweenMapPoints(MKMapPointForCoordinate(centerCoord), MKMapPointForCoordinate(self.dataController.userCoordinate))];
            
            [self.destinationDetailLabel setText:[self.mapCenterAddress name]];
            
        }];
    }
}

//- (IBAction)refreshTapped:(id)sender
//{
//    [self performSelectorOnMainThread:@selector(refreshWasTapped:)
//                           withObject:nil
//                        waitUntilDone:NO];
//}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    MyLocation *location = (MyLocation*)view.annotation;
    
//    NSDictionary *launchOptions = @{MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving};
//    [station.mapItem openInMapsWithLaunchOptions:launchOptions];
    
    //Use this location as our final destination, same as selecting it from the Destinations tableView
    //TODO: add action sheet later for adding this location to favorites
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kStartBikingNotif
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:location forKey:kBikeDestinationKey]];
}

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
    //Clear out current stations:
    [self.dataController.stationList removeAllObjects];
    //Add new stations:
    [self.dataController addLocationObjectsFromArray:stations toList:self.dataController.stationList];
    [self didChangeValueForKey:kStationList];
}

- (void)startBiking:(NSNotification *)notif
{
    assert([NSThread isMainThread]);

    //Make sure this view is showing (TODO: let the tableViewController handle this?)
//    [[self view] bringSubviewToFront:[self view]];
    
    //Get ready to bike, set the new state and the final destination location
    self.bikingState = BikingStatePreparingToBike;
    self.finalDestination = [[notif userInfo] valueForKey:kBikeDestinationKey];
    
    //Disable the bikes/docks toggle:
    [self.bikesDocksControl setHidden:YES];
    
    //Refresh all station data to get the absolute latest nbBikes and nbEmptyDocks counts.
    //Equivalent to hitting Refresh:
    [[NSNotificationCenter defaultCenter] postNotificationName:kRefreshTappedNotif
                                                        object:self
                                                      userInfo:nil];
}

- (void)stopBiking
{    
    //Refresh all station data to get the absolute latest nbBikes and nbEmptyDocks counts.
    //Equivalent to hitting Refresh:
    [[NSNotificationCenter defaultCenter] postNotificationName:kRefreshTappedNotif
                                                        object:self
                                                      userInfo:nil];
    //re-center map on previous final destination
    [self.mapView setCenterCoordinate:self.finalDestination.coordinate animated:YES];
    
    //re-display center bike pointer image
    [self.bikeCrosshairImage setHidden:NO];
    
    //re-enable the bikes/docks toggle:
    [self.bikesDocksControl setHidden:NO];
    
    //Change buttons and label:
    [self.destinationDetailLabel setText:[self.finalDestination name]];
//    [self.startStopButton setBackgroundColor:[UIColor whiteColor]];
    [self.startStopButton setTitleColor:[UIColor colorWithRed:.196 green:0.3098 blue:0.52 alpha:1.0] forState:UIControlStateNormal];
    [self.startStopButton setTitle:@"Set Destination" forState:UIControlStateNormal];
    //hide cancel button
    [self.cancelButton setHidden:YES];
    
    //Return to idle/inactive state
    self.bikingState = BikingStateInactive;
    self.finalDestination = nil;
}

- (void)startBikingCallback
{

    //TODO put the rest of this function in a callback after the latest station data arrives?
    
    //Calculate and store the distances from the destination to each station:
//    MyLocation *destination = [[notif userInfo] valueForKey:kBikeDestinationKey];
    for (Station *station in self.dataController.stationList)
    {
        station.distanceFromDestination = MKMetersBetweenMapPoints(MKMapPointForCoordinate(station.coordinate), MKMapPointForCoordinate(self.finalDestination.coordinate));
    }
    
    //Figure out the three closest stations to the destination:
    //First sort by distance from destination:
    [self.dataController setSortedStationList:[self.dataController sortLocationList:[self.dataController stationList] byMethod:LocationDataSortByDistanceFromDestination]];
    //Then grab the top 3:
//    NSMutableArray *closestStationsToDestination = [[NSMutableArray alloc] initWithCapacity:3];
    NSArray *closestStationsToDestination = [self.dataController.sortedStationList objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 3)]];
    
    //Figure out the closest station to the user with at least one bike
    //First sort by distance from user:
    [self.dataController setSortedStationList:[self.dataController sortLocationList:[self.dataController stationList] byMethod:LocationDataSortByDistanceFromUser]];
    //Then grab the top one with a bike:
    Station *sourceStation;
    for (Station *station in self.dataController.sortedStationList)
    {
        if ([station nbBikes] >= 1)
        {
            sourceStation = station;
            break;
        }
    }
    
    /* Change the map view to show the current user location, and the start, end and backup end stations */
    
    //Really nice code for this adapted from https://gist.github.com/andrewgleave/915374 via http://stackoverflow.com/a/7141612 :
    //Start with the user coordinate:
    MKMapPoint annotationPoint;
    MKMapRect zoomRect;
    if (self.dataController.userCoordinate.latitude && self.dataController.userCoordinate.longitude)
    {
        annotationPoint = MKMapPointForCoordinate(self.dataController.userCoordinate);
        zoomRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0.1, 0.1);
    }
    else
    {
        zoomRect = MKMapRectNull;
    }
    //Then add the closest station to the user:
    annotationPoint = MKMapPointForCoordinate(sourceStation.coordinate);
    MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0.1, 0.1);
    zoomRect = MKMapRectUnion(zoomRect, pointRect);
    //Then add the destination:
    annotationPoint = MKMapPointForCoordinate(self.finalDestination.coordinate);
    pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0.1, 0.1);
    zoomRect = MKMapRectUnion(zoomRect, pointRect);
    //Then add the closest stations to the destination:
    for (Station* station in closestStationsToDestination)
    {
        annotationPoint = MKMapPointForCoordinate(station.coordinate);
        pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0.1, 0.1);
        zoomRect = MKMapRectUnion(zoomRect, pointRect);
    }
    [self.mapView setVisibleMapRect:zoomRect edgePadding:UIEdgeInsetsMake(44, 5, 5, 5) animated:YES];
    
    //Change the annotation identifiers for the Station/MyLocation objects we want to view as annotations on the map:
    //i.e. change the pin color (other attributes?) for start, end and backup end stations
    sourceStation.annotationIdentifier = kSourceStation;
    self.finalDestination.annotationIdentifier = kDestinationLocation;
    //Label the closest destination to the finalDestination as the idealDestinationStation, so if it's full we can check to see if a dock opens up there later.
    self.idealDestinationStation = [closestStationsToDestination objectAtIndex:0];
    //Destintation stations: label the closest one with at least one empty dock as the current destination and the rest as "alternates."
    BOOL destinationFound = NO;
    for (Station* station in closestStationsToDestination)
    {
        if ((station.nbEmptyDocks > 0) && !destinationFound)
        {
            station.annotationIdentifier = kDestinationStation;
            self.currentDestinationStation = station;
            destinationFound = YES;
        }
        else
        {
            station.annotationIdentifier = kAlternateStation;
        }
    }
    
    //Hide the annotations for all other stations.
    [self.mapView removeAnnotations:self.mapView.annotations];
    //Hide center bike pointer image
    [self.bikeCrosshairImage setHidden:YES];
    
    //Change buttons and label:
    [self.destinationDetailLabel setText:[NSString stringWithFormat:@"Pick up bike at %@ - %d bike%@ available\nBike to %@ - %d empty dock%@", sourceStation.name, sourceStation.nbBikes, (sourceStation.nbBikes > 1) ? @"s" : @"", self.currentDestinationStation.name, self.currentDestinationStation.nbEmptyDocks, (self.currentDestinationStation.nbEmptyDocks > 1) ? @"s" : @""]];
//    [self.startStopButton setBackgroundColor:[UIColor greenColor]];
    [self.startStopButton setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
    [self.startStopButton setTitle:@"Start Station Tracking" forState:UIControlStateNormal];
    [self.cancelButton setHidden:NO];

    //Add new annotations.
    //TODO: if final destination and current destination station are the same object, only show the station object
    [self.mapView addAnnotation:sourceStation];
//    if (![self.finalDestination isEqual:self.currentDestinationStation])
    if (self.finalDestination.coordinate.latitude != self.currentDestinationStation.coordinate.latitude && self.finalDestination.coordinate.longitude != self.currentDestinationStation.coordinate.longitude)
        [self.mapView addAnnotation:self.finalDestination];
    for (Station* station in closestStationsToDestination)
    {
        [self.mapView addAnnotation:station];
    }
    
    //TODO: If there is no station in closestStationsToDestination with >0 nbEmptyDocks, do we warn the user or just keep going down the list?
    //TODO: If the closest station to the destination is closer than the sourceStation, perhaps it's best to just tell the user to walk?
    
    //Start the rental timer, if we have one
    
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
    switch (self.bikingState) {
        case BikingStateInactive:
            //Reload map view
            if (![NSThread isMainThread]) {
                [self performSelectorOnMainThread:@selector(plotStationPosition:) withObject:self.dataController.stationList waitUntilDone:NO];
            }
            else
            {
                [self plotStationPosition:self.dataController.stationList];
            }
            break;
        case BikingStatePreparingToBike:
            //Do not reload the map view yet, just go to the callback to finish the setup to start biking:
            [self startBikingCallback];
            break;
        case BikingStateActive:
            //Do not reload the map view at all, unless the app is coming back into the foreground.  Just check to see if we need to send a notification based on nbEmptyDocks for our current goal station
            break;
        default:
            break;
    }

}

- (IBAction)refeshTapped:(id)sender {
    [self performSelectorOnMainThread:@selector(refreshWasTapped)
                           withObject:nil
                        waitUntilDone:NO];
}

- (IBAction)cancelTapped:(id)sender {
    //reset to inactive
    [self stopBiking];
}

- (IBAction)startStopTapped:(UIButton *)sender {
    switch (self.bikingState) {
        case BikingStateInactive:
            //set the final destination to equal the placemark at the center of the crosshairs
            //then call startBiking: with the location
            [self startBiking:[NSNotification notificationWithName:kStartBikingNotif object:self userInfo:[NSDictionary dictionaryWithObject:self.mapCenterAddress forKey:kBikeDestinationKey]]];
            break;
        case BikingStatePreparingToBike:
            //start station tracking (TODO)
            //For now... just do this
            //Change buttons:
//            [self.startStopButton setBackgroundColor:[UIColor redColor]];
            [self.startStopButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
            [self.startStopButton setTitle:@"Stop Station Tracking" forState:UIControlStateNormal];
            [self.cancelButton setHidden:YES];
            //Change the state to active:
            self.bikingState = BikingStateActive;
            break;
        case BikingStateActive:
            //stop station tracking and return PreparingToBike state
            [self startBiking:[NSNotification notificationWithName:kStartBikingNotif object:self userInfo:[NSDictionary dictionaryWithObject:self.finalDestination forKey:kBikeDestinationKey]]];
            break;
        default:
            break;
    }
}

- (IBAction)bikesDocksToggled:(id)sender {
    //replot the station annotations with either the number of bikes or empty docks at each
    [self plotStationPosition:self.dataController.stationList];
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
