//
//  BikeZenSecondViewController.m
//  BikeZen
//
//  Created by John Penning on 4/30/13.
//  Copyright (c) 2013 John Penning. All rights reserved.
//

//#import <UIKit/UIKit.h>
//#import <MapKit/MapKit.h>
#import "BikeZenSecondViewController.h"
#import "BikeZenDefine.h"
#import "Station.h"

//#define METERS_PER_MILE 1609.344
//#define DUPONT_LAT      38.909600
//#define DUPONT_LONG     -77.043400

@interface BikeZenSecondViewController ()

@end

@implementation BikeZenSecondViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.stationList = [NSMutableArray array];
    
    // KVO: listen for changes to our station data source for map view updates
    [self addObserver:self forKeyPath:@"stationList" options:0 context:NULL];
    
    //Define the initial zoom location (Dupont Circle for now)
    CLLocationCoordinate2D zoomLocation;// = CLLocationCoordinate2DMake((CLLocationDegrees)DUPONT_LAT, (CLLocationDegrees)DUPONT_LONG);
    
    zoomLocation.latitude = DUPONT_LAT;
    zoomLocation.longitude = DUPONT_LONG;
    
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
    [super viewDidUnload];
    
    self.stationList = nil;
    
    [self removeObserver:self forKeyPath:@"stationList"];

}

- (void)plotStationPosition:(NSArray *)stationList {
    for (id<MKAnnotation> annotation in self.mapView.annotations) {
        [self.mapView removeAnnotation:annotation];
    }
    
    for (Station* station in stationList)
        [self.mapView addAnnotation:station];

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

//- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
//{
//    static NSString *identifier = @"Station";
//    
//    if ([annotation isKindOfClass:[Station class]]) {
//        MKAnnotationView *annotationView = (MKAnnotationView *) [self.mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
//        if (annotationView == nil) {
//            annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
//            annotationView.enabled = YES;
//            annotationView.canShowCallout = NO;//YES;
//            annotationView.image = [UIImage imageNamed:@"arrest.png"];
//            annotationView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
//        }
//        else {
//            annotationView.annotation = annotation;
//        }
//        
//        return annotationView;
//    }
//    
//    return nil;
//}

//- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
//{
//    Station *station = (Station*)view.annotation;
//    
//    NSDictionary *launchOptions = @{MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving};
//    [location.mapItem openInMapsWithLaunchOptions:launchOptions];
//}

#pragma mark -
#pragma mark KVO support

- (void)insertStations:(NSArray *)stations
{
    // this will allow us as an observer to notified (see observeValueForKeyPath)
    // so we can update our UITableView
    //
    [self willChangeValueForKey:@"stationList"];
    [self.stationList addObjectsFromArray:stations];
    [self didChangeValueForKey:@"stationList"];
}

// listen for changes to the station list coming from our app delegate.
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
//    [self.tableView reloadData];
    //TODO: reload map view
//    NSEnumerator *enumerator = [self.stationList enumerateObjectsUsingBlock:<#^(id obj, NSUInteger idx, BOOL *stop)block#>]
//    [self.stationList makeObjectsPerformSelector:<#(SEL)#>]
    [self plotStationPosition:self.stationList];
}

@end
