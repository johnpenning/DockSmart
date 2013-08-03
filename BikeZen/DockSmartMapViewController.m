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
//    static NSString *identifier = @"Station";
    
    if ([annotation isKindOfClass:[MyLocation class]]) {
        MyLocation* location = (MyLocation*)annotation;
        MKAnnotationView *annotationView;
        if ([location.annotationIdentifier isEqualToString:kDestinationLocation])
        {
            //Use a standard red MKPinAnnotationView for the final destination address, if it's not a station itself
            annotationView = (MKPinAnnotationView *) [self.mapView dequeueReusableAnnotationViewWithIdentifier:location.annotationIdentifier];
            if (annotationView == nil)
            {
//                MKPinAnnotationView* pinView = (MKPinAnnotationView *)annotationView;
                MKPinAnnotationView* pinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:location.annotationIdentifier];
                pinView.enabled = YES;
                pinView.canShowCallout = YES;
                pinView.pinColor = MKPinAnnotationColorRed;
                pinView.animatesDrop = YES;
                pinView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
                annotationView = pinView;
            }
            else
            {
                annotationView.annotation = annotation;
            }
        }
        else
        {
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
                    annotationView.image = [UIImage imageNamed:[NSString stringWithFormat:@"green%02d.png", (station.nbBikes <= 20 ? station.nbBikes : 20)]];
                }
                else if ([location.annotationIdentifier isEqualToString:kDestinationStation])
                {
                    //Use red icons to denote destinations, and show the number of empty docks:
                    annotationView.image = [UIImage imageNamed:[NSString stringWithFormat:@"red%02d.png", (station.nbEmptyDocks <= 99 ? station.nbEmptyDocks : 99)]];
                }
                else if ([location.annotationIdentifier isEqualToString:kAlternateStation] || [location.annotationIdentifier isEqualToString:kStation])
                {
                    //Use black icons to denote alternate stations and generic station:
                    annotationView.image = [UIImage imageNamed:[NSString stringWithFormat:@"black%02d.png", (station.nbEmptyDocks <= 99 ? station.nbEmptyDocks : 99)]];
                }
                //move the centerOffset up so the "point" of the image is pointed at the station location, instead of the image being centered directly over it:
                annotationView.centerOffset = CGPointMake(0, -13);
            }
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
    
    //Refresh all station data to get the absolute latest nbBikes and nbEmptyDocks counts.
    //Equivalent to hitting Refresh:
//    [[NSNotificationCenter defaultCenter] postNotificationName:kRefreshTappedNotif
//                                                        object:self
//                                                      userInfo:nil];
    
    //TODO put the rest of this function in a callback after the latest station data arrives?
    
    //Calculate and store the distances from the destination to each station:
    MyLocation *destination = [[notif userInfo] valueForKey:kBikeDestinationKey];
    for (Station *station in self.dataController.stationList)
    {
        station.distanceFromDestination = MKMetersBetweenMapPoints(MKMapPointForCoordinate(station.coordinate), MKMapPointForCoordinate(destination.coordinate));
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
    MKMapPoint annotationPoint = MKMapPointForCoordinate(self.dataController.userCoordinate);
    MKMapRect zoomRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0.1, 0.1);
    //Then add the closest station to the user:
    annotationPoint = MKMapPointForCoordinate(sourceStation.coordinate);
    MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0.1, 0.1);
    zoomRect = MKMapRectUnion(zoomRect, pointRect);
    //Then add the destination:
    annotationPoint = MKMapPointForCoordinate(destination.coordinate);
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
    //TODO: change the pin colors/sizes for start, end and backup end stations?
    sourceStation.annotationIdentifier = kSourceStation;
    destination.annotationIdentifier = kDestinationLocation;
    //Destintation stations: label the closest one with at least one empty dock as the destination and the rest as "alternates"
    BOOL destinationFound = NO;
    for (Station* station in closestStationsToDestination)
    {
        if ((station.nbEmptyDocks > 0) && !destinationFound)
        {
            station.annotationIdentifier = kDestinationStation;
            destinationFound = YES;
        }
        else
        {
            station.annotationIdentifier = kAlternateStation;
        }
    }
    
    //Hide the annotations for all other stations.
    [self.mapView removeAnnotations:self.mapView.annotations];
    
    //Add new annotations.
    //TODO: if destination and destination station are the same object, which annotation do we show?
    [self.mapView addAnnotation:sourceStation];
    [self.mapView addAnnotation:destination];
    for (Station* station in closestStationsToDestination)
    {
        [self.mapView addAnnotation:station];
    }
    
    //TODO: If there is no station in closestStationsToDestination with >0 nbEmptyDocks, do we warn the user or just keep going down the list?
    //TODO: If the closest station to the destination is closer than the sourceStation, perhaps it's best to just tell the user to walk?
    
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
