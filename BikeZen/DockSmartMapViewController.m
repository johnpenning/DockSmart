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
#import "DockSmartLogViewController.h"
#import "DockSmartAppDelegate.h"
#import "MBProgressHUD.h"

// NSNotification name for reporting that refresh was tapped
NSString *kRefreshTappedNotif = @"RefreshTappedNotif";
NSString *kTrackingStartedNotif = @"TrackingStartedNotif";
NSString *kTrackingStoppedNotif = @"TrackingStoppedNotif";
NSString *kStationList = @"stationList";

// Key noting if user has seen the intro screen/alert
NSString *kHasSeenIntro = @"has_seen_intro";

// Region monitoring identifiers:
NSString *kRegionMonitorTwoThirdsToGo = @"RegionMonitorTwoThirdsToGo";
NSString *kRegionMonitorOneThirdToGo = @"RegionMonitorOneThirdToGo";
NSString *kRegionMonitorStation1 = @"RegionMonitorStation1";
NSString *kRegionMonitorStation2 = @"RegionMonitorStation2";
NSString *kRegionMonitorStation3 = @"RegionMonitorStation3";

// Restoration IDs for custom objects:
static NSString *SourceStationID = @"SourceStationID";
static NSString *FinalDestinationID = @"FinalDestinationID";
static NSString *CurrentDestinationStationID = @"CurrentDestinationStationID";
static NSString *IdealDestinationStationID = @"IdealDestinationStationID";
static NSString *ClosestStationsToDestinationID = @"ClosestStationsToDestinationID";
static NSString *MapCenterAddressID = @"MapCenterAddressID";

// NSNotification userInfo key for obtaining command to refresh the station list
//NSString *kRefreshStationsKey = @"RefreshStationsKey";

@interface DockSmartMapViewController ()
- (IBAction)refeshTapped:(id)sender;
- (IBAction)cancelTapped:(id)sender;
- (IBAction)startStopTapped:(id)sender;
- (IBAction)bikesDocksToggled:(id)sender;
- (IBAction)updateLocationTapped:(id)sender;

//@property (weak, nonatomic) IBOutlet UIBarButtonItem *startStopButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *startStopButton;
@property (weak, nonatomic) IBOutlet UILabel *destinationDetailLabel;
@property (weak, nonatomic) IBOutlet UIImageView *bikeCrosshairImage;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;
@property (weak, nonatomic) IBOutlet UISegmentedControl *bikesDocksControl;

//location property for the center of the map:
@property (nonatomic) Address* mapCenterAddress;

//keep track of the station we're getting the bike from:
@property (nonatomic) Station* sourceStation;
//keep track of where we're going:
@property (nonatomic) MyLocation* finalDestination;
@property (nonatomic) Station* currentDestinationStation;
@property (nonatomic) Station* idealDestinationStation;
@property (nonatomic/*, strong*/) NSMutableArray *closestStationsToDestination;
@property (nonatomic) NSMutableArray *regionIdentifierQueue;
//the action sheet to show when making a user confirm their station destination
@property (nonatomic, readwrite) UIActionSheet *navSheet;
@property (nonatomic) MyLocation *selectedLocation;


//timer to refresh data:
@property (nonatomic) NSTimer* minuteTimer;

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
                                             selector:@selector(stationError:)
                                                 name:kStationErrorNotif
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(prepareNewBikeRoute:)
                                                 name:kStartBikingNotif
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateLocation:)
                                                 name:kLocationUpdateNotif
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(regionEntered:)
                                                 name:kRegionEntryNotif
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(regionExited:)
                                                 name:kRegionExitNotif
                                               object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    //iOS7 compatibility: allow us to programmatically attach the toolbar to the status bar
    [self.topMapToolbar setDelegate:self];
    
    self.dataController = [[LocationDataController alloc] init];
    self.mapCenterAddress = [[Address alloc] init];
    self.closestStationsToDestination = [[NSMutableArray alloc] initWithCapacity:3];
    self.sourceStation = [[Station alloc] init];
    self.finalDestination = [[MyLocation alloc] init];
    self.currentDestinationStation = [[Station alloc] init];
    self.idealDestinationStation = [[Station alloc] init];
    self.regionIdentifierQueue = [[NSMutableArray alloc] init];
    
    // KVO: listen for changes to our station data source for map view updates
    [self addObserver:self forKeyPath:kStationList options:0 context:NULL];
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(addStations:)
//                                                 name:kAddStationsNotif
//                                               object:nil];
    
    //initialize states
    [self setBikingState:BikingStateInactive];
    
    //Define the initial zoom location (Dupont Circle for now)
    //TODO: change this to current user location, wherever that may be
    CLLocationCoordinate2D zoomLocation = CLLocationCoordinate2DMake((CLLocationDegrees)DUPONT_LAT, (CLLocationDegrees)DUPONT_LONG);
    
//    zoomLocation.latitude = DUPONT_LAT;
//    zoomLocation.longitude = DUPONT_LONG;
    
    //define the initial view region -> about the size of the neighborhood:
//    MKCoordinateRegion viewRegion = [self.mapView regionThatFits:MKCoordinateRegionMakeWithDistance(zoomLocation, 2*METERS_PER_MILE, 2*METERS_PER_MILE)];
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(zoomLocation, 2*METERS_PER_MILE, 2*METERS_PER_MILE);
    
    [self.mapView setRegion:viewRegion animated:YES];
    
    //Show the license agreement alert if this is the first time the app has been opened:
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults boolForKey:kHasSeenIntro])
    {
        [defaults setBool:YES forKey:kHasSeenIntro];
        [defaults synchronize];
        
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Welcome to DockSmart!"
                                                     message:@"By using this app, you agree to be legally bound by all the terms of the License Agreement located by exiting the app and selecting Settings -> DockSmart -> License Agreement.\n\nDon't use the app while biking, and ride safely!"
                                                    delegate:nil
                                           cancelButtonTitle:@"OK"
                                           otherButtonTitles:nil];
        [av show];
    }

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    //Make sure the user has enabled location services before attempting to get the location
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied ||
        [CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted ||
        [CLLocationManager locationServicesEnabled] == NO)
    {
        [self.updateLocationButton setEnabled:NO];
    }
    else
    {
        [self.updateLocationButton setEnabled:YES];
        [[LocationController sharedInstance] startUpdatingCurrentLocation];
    }

    [super viewWillAppear:animated];
}

- (void)viewDidUnload {
//    [self setBikeDockViewSwitch:nil];
//    [self setRefreshButtonTapped:nil];
    [self setStartStopButton:nil];
    [self setDestinationDetailLabel:nil];
    [self setBikeCrosshairImage:nil];
    [self setCancelButton:nil];
    [self setBikesDocksControl:nil];
    [self setUpdateLocationButton:nil];
//    [self setClosestStationsToDestination:nil];
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


#pragma mark - State Restoration

static NSString *BikesDocksControlKey = @"BikesDocksControlKey";
static NSString *BikesDocksControlHiddenKey = @"BikesDocksControlHiddenKey";
static NSString *BikingStateKey = @"BikingStateKey";
static NSString *DataControllerKey = @"DataControllerKey";
static NSString *SourceStationKey = @"SourceStationKey";
static NSString *FinalDestinationKey = @"FinalDestinationKey";
static NSString *CurrentDestinationStationKey = @"CurrentDestinationStationKey";
static NSString *IdealDestinationStationKey = @"IdealDestinationStationKey";
static NSString *ClosestStationsToDestinationKey = @"ClosestStationsToDestinationKey";
static NSString *MinuteTimerValidKey = @"MinuteTimerValidKey";
static NSString *StartStopButtonTitleKey = @"StartStopButtonTitleKey";
static NSString *StartStopButtonTintColorKey = @"StartStopButtonTintColorKey";
static NSString *StartStopButtonEnabledKey = @"StartStopButtonEnabledKey";
static NSString *DestinationDetailLabelKey = @"DestinationDetailLabelKey";
static NSString *BikeCrosshairImageKey = @"BikeCrosshairImageKey";
static NSString *CancelButtonKey = @"CancelButtonKey";
static NSString *MapCenterAddressKey = @"MapCenterAddressKey";
static NSString *RegionCenterLatKey = @"RegionCenterLatKey";
static NSString *RegionCenterLongKey = @"RegionCenterLongKey";
static NSString *RegionSpanLatKey = @"RegionSpanLatKey";
static NSString *RegionSpanLongKey = @"RegionSpanLongKey";
static NSString *RegionIdentifierKey = @"RegionIdentifierKey";
static NSString *UpdateLocationButtonEnabledKey = @"UpdateLocationButtonEnabledKey";

- (void) encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super encodeRestorableStateWithCoder:coder];
    
    //Register custom objects for state restoration:
    //    if (self.sourceStation)
    //        [UIApplication registerObjectForStateRestoration:self.sourceStation restorationIdentifier:SourceStationID];
    //    if (self.finalDestination)
    //        [UIApplication registerObjectForStateRestoration:self.finalDestination restorationIdentifier:FinalDestinationID];
    //    if (self.currentDestinationStation)
    //        [UIApplication registerObjectForStateRestoration:self.currentDestinationStation restorationIdentifier:CurrentDestinationStationID];
    //    if (self.idealDestinationStation)
    //        [UIApplication registerObjectForStateRestoration:self.idealDestinationStation restorationIdentifier:IdealDestinationStationID];
    
    //Encode objects:
    [coder encodeInteger:self.bikesDocksControl.selectedSegmentIndex forKey:BikesDocksControlKey];
    [coder encodeBool:self.bikesDocksControl.hidden forKey:BikesDocksControlHiddenKey];
//    [coder encodeInteger:self.bikingState forKey:BikingStateKey];
    
//    //    [coder encodeObject:self.dataController forKey:DataControllerKey];
//    [coder encodeObject:self.sourceStation forKey:SourceStationKey];
//    [coder encodeObject:self.finalDestination forKey:FinalDestinationKey];
//    [coder encodeObject:self.currentDestinationStation forKey:CurrentDestinationStationKey];
//    [coder encodeObject:self.idealDestinationStation forKey:IdealDestinationStationKey];
//    //    [coder encodeObject:self.closestStationsToDestination forKey:ClosestStationsToDestinationKey];
//    NSUInteger idx = 0;
//    for (Station *station in self.closestStationsToDestination)
//    {
//        [coder encodeObject:station forKey:[NSString stringWithFormat:@"%@%d", ClosestStationsToDestinationKey, idx]];
//        idx++;
//    }
//    [coder encodeObject:self.mapCenterAddress forKey:MapCenterAddressKey];

    [coder encodeBool:self.minuteTimer.isValid forKey:MinuteTimerValidKey];
    [coder encodeObject:self.startStopButton.title forKey:StartStopButtonTitleKey];
    [coder encodeObject:self.startStopButton.tintColor forKey:StartStopButtonTintColorKey];
    [coder encodeBool:self.startStopButton.enabled forKey:StartStopButtonEnabledKey];
    [coder encodeObject:self.destinationDetailLabel.text forKey:DestinationDetailLabelKey];
//    [coder encodeBool:self.bikeCrosshairImage.hidden forKey:BikeCrosshairImageKey];
    [coder encodeBool:self.cancelButton.enabled forKey:CancelButtonKey];
    [coder encodeDouble:[self.mapView region].center.latitude forKey:RegionCenterLatKey];
    [coder encodeDouble:[self.mapView region].center.longitude forKey:RegionCenterLongKey];
    [coder encodeDouble:[self.mapView region].span.latitudeDelta forKey:RegionSpanLatKey];
    [coder encodeDouble:[self.mapView region].span.longitudeDelta forKey:RegionSpanLongKey];
    
    NSMutableData *data = [NSMutableData data];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];

    [archiver encodeInteger:self.bikingState forKey:BikingStateKey];
    [archiver encodeObject:self.dataController.stationList forKey:DataControllerKey];
    [archiver encodeObject:self.sourceStation forKey:SourceStationKey];
    [archiver encodeObject:self.finalDestination forKey:FinalDestinationKey];
    [archiver encodeObject:self.currentDestinationStation forKey:CurrentDestinationStationKey];
    [archiver encodeObject:self.idealDestinationStation forKey:IdealDestinationStationKey];
    [archiver encodeObject:self.closestStationsToDestination forKey:ClosestStationsToDestinationKey];
//    NSUInteger idx = 0;
//    for (Station *station in self.closestStationsToDestination)
//    {
//        [archiver encodeObject:station forKey:[NSString stringWithFormat:@"%@%d", ClosestStationsToDestinationKey, idx]];
//        idx++;
//    }
    [archiver encodeObject:self.mapCenterAddress forKey:MapCenterAddressKey];
    [archiver encodeBool:self.bikeCrosshairImage.hidden forKey:BikeCrosshairImageKey];
    [archiver encodeObject:self.regionIdentifierQueue forKey:RegionIdentifierKey];
    [archiver encodeBool:self.updateLocationButton.enabled forKey:UpdateLocationButtonEnabledKey];
    [archiver finishEncoding];
    
//    NSString *filename = @"stationData.txt";
    NSString *applicationDocumentsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *path = [applicationDocumentsDir stringByAppendingPathComponent:@"stationData.txt"];
    
    NSError *error;
#ifdef DEBUG
    BOOL result = [data writeToFile:path options:NSDataWritingAtomic error:&error];
    DLog(@"Map view archive result = %d, %@", result, error);
#else
    [data writeToFile:path options:NSDataWritingAtomic error:&error];
#endif
    
}


- (void) decodeRestorableStateWithCoder:(NSCoder *)coder
{
    NSString* logText = [NSString stringWithFormat:@"mapViewController decodeRestorableStateWithCoder called"];
    DLog(@"%@",logText);
    [[NSNotificationCenter defaultCenter] postNotificationName:kLogToTextViewNotif
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:logText
                                                                                           forKey:kLogTextKey]];

    [super decodeRestorableStateWithCoder:coder];
    
    //    //Register custom objects for state restoration:
    //    [UIApplication registerObjectForStateRestoration:self.sourceStation restorationIdentifier:SourceStationID];
    //    [UIApplication registerObjectForStateRestoration:self.finalDestination restorationIdentifier:FinalDestinationID];
    //    [UIApplication registerObjectForStateRestoration:self.currentDestinationStation restorationIdentifier:CurrentDestinationStationID];
    //    [UIApplication registerObjectForStateRestoration:self.idealDestinationStation restorationIdentifier:IdealDestinationStationID];
    
    self.bikesDocksControl.selectedSegmentIndex = [coder decodeIntegerForKey:BikesDocksControlKey];
    self.bikesDocksControl.hidden = [coder decodeBoolForKey:BikesDocksControlHiddenKey];
//    self.bikingState = [coder decodeIntegerForKey:BikingStateKey];
    //    self.dataController = [coder decodeObjectForKey:DataControllerKey];
//    self.sourceStation = [coder decodeObjectForKey:SourceStationKey];
//    self.finalDestination = [coder decodeObjectForKey:FinalDestinationKey];
//    self.currentDestinationStation = [coder decodeObjectForKey:CurrentDestinationStationKey];
//    self.idealDestinationStation = [coder decodeObjectForKey:IdealDestinationStationKey];
    //    self.closestStationsToDestination = [coder decodeObjectForKey:ClosestStationsToDestinationKey];
//    NSUInteger idx = 0;
//    for (idx = 0; idx < [self.closestStationsToDestination count]; idx++)
//    {
//        //        [coder encodeObject:station forKey:[NSString stringWithFormat:@"%@%d", ClosestStationsToDestinationKey, idx]];
//        [self.closestStationsToDestination setObject:[coder decodeObjectForKey:[NSString stringWithFormat:@"%@%d", ClosestStationsToDestinationKey, idx] ] atIndexedSubscript:idx];
//    }
    //    self.mapCenterAddress = [coder decodeObjectForKey:MapCenterAddressKey];

    
    if ([coder decodeBoolForKey:MinuteTimerValidKey])
    {
        self.minuteTimer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(refreshWasTapped) userInfo:nil repeats:YES];
    }
    self.startStopButton.title = [coder decodeObjectForKey:StartStopButtonTitleKey];
    self.startStopButton.tintColor = [coder decodeObjectForKey:StartStopButtonTintColorKey];
    self.startStopButton.enabled = [coder decodeBoolForKey:StartStopButtonEnabledKey];
    self.destinationDetailLabel.text = [coder decodeObjectForKey:DestinationDetailLabelKey];
    //set hidden state in archiver? is not hidden when app launches in background
//    self.bikeCrosshairImage.hidden = [coder decodeBoolForKey:BikeCrosshairImageKey];
    self.cancelButton.enabled = [coder decodeBoolForKey:CancelButtonKey];
    [self.mapView setRegion:MKCoordinateRegionMake(
                                                   CLLocationCoordinate2DMake([coder decodeDoubleForKey:RegionCenterLatKey], [coder decodeDoubleForKey:RegionCenterLongKey]),
                                                   MKCoordinateSpanMake([coder decodeDoubleForKey:RegionSpanLatKey], [coder decodeDoubleForKey:RegionSpanLongKey])
                                                   ) animated:YES];
    
    NSString *applicationDocumentsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *path = [applicationDocumentsDir stringByAppendingPathComponent:@"stationData.txt"];

    NSData *data = [NSData dataWithContentsOfFile:path];
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    
    self.bikingState = [unarchiver decodeIntegerForKey:BikingStateKey];
    self.dataController.stationList = [unarchiver decodeObjectForKey:DataControllerKey];
    self.sourceStation = [unarchiver decodeObjectForKey:SourceStationKey];
    self.finalDestination = [unarchiver decodeObjectForKey:FinalDestinationKey];
    self.currentDestinationStation = [unarchiver decodeObjectForKey:CurrentDestinationStationKey];
    self.idealDestinationStation = [unarchiver decodeObjectForKey:IdealDestinationStationKey];
    self.closestStationsToDestination = [unarchiver decodeObjectForKey:ClosestStationsToDestinationKey];
//    NSUInteger idx = 0;
//    for (idx = 0; idx < [self.closestStationsToDestination count]; idx++)
//    {
//        [self.closestStationsToDestination setObject:[unarchiver decodeObjectForKey:[NSString stringWithFormat:@"%@%d", ClosestStationsToDestinationKey, idx] ] atIndexedSubscript:idx];
//    }
    self.mapCenterAddress = [unarchiver decodeObjectForKey:MapCenterAddressKey];
    self.bikeCrosshairImage.hidden = [unarchiver decodeBoolForKey:BikeCrosshairImageKey];
    self.regionIdentifierQueue = [unarchiver decodeObjectForKey:RegionIdentifierKey];
    self.updateLocationButton.enabled = [unarchiver decodeBoolForKey:UpdateLocationButtonEnabledKey];
    [unarchiver finishDecoding];
}

//+ (Station *)makeStationWithRestorationIdentifier:(NSString *)identifier
//{
//    Station* station = [Station new];
//    [UIApplication registerObjectForStateRestoration:station restorationIdentifier:identifier];
////    station.objectRestorationClass = self;
//    
//    return station;
//}
//
//+ (Address *)makeAddressWithRestorationIdentifier:(NSString *)identifier
//{
//    Address* address = [Address new];
//    [UIApplication registerObjectForStateRestoration:address restorationIdentifier:identifier];
////    address.objectRestorationClass = self;
//    
//    return address;
//}
//
//+ (MyLocation *)makeMyLocationWithRestorationIdentifier:(NSString *)identifier
//{
//    MyLocation* myLocation = [MyLocation new];
//    [UIApplication registerObjectForStateRestoration:myLocation restorationIdentifier:identifier];
////    myLocation.objectRestorationClass = self;
//    
//    return myLocation;
//}
//
//+ (id<UIStateRestoring>) objectWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder
//{
//    NSString *lastIdentifier = [identifierComponents lastObject];
//    
////    if ([[identifierComponents lastObject] isEqualToString:SourceStationID])
////    {
//////        return [[UIApplication sharedApplication] delegate] ;
////    }
//    if ([lastIdentifier isEqualToString:FinalDestinationID])
//        return [self makeMyLocationWithRestorationIdentifier:lastIdentifier];
////    else if ([[identifierComponents lastObject] isEqualToString:CurrentDestinationStationID])
////    {
////        
////    }
////    else if ([[identifierComponents lastObject] isEqualToString:IdealDestinationStationID])
////    {
////        
////    }
//    else if ([lastIdentifier isEqualToString:MapCenterAddressID])
//        return [self makeAddressWithRestorationIdentifier:lastIdentifier];
////    else
////    {
////        NSUInteger idx = 0;
////        for (idx = 0; idx < [self.closestStationsToDestination count]; idx++)
////        {
////            if ([[identifierComponents lastObject] isEqualToString:SourceStationID])
////            {
////                
////            }
////        }
////    }
//    else
//        return [self makeStationWithRestorationIdentifier:lastIdentifier];
//}

- (void)applicationFinishedRestoringState
{
    //Called on restored view controllers after other object decoding is complete.
    NSString* logText = [NSString stringWithFormat:@"finished restoring MapViewController"];
    DLog(@"%@",logText);
    [[NSNotificationCenter defaultCenter] postNotificationName:kLogToTextViewNotif
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:logText
                                                                                           forKey:kLogTextKey]];

    [self refreshWasTapped];
}


#pragma mark - Getting New Bike Data

- (void)refreshWasTapped
{
//    assert([NSThread isMainThread]);
    //Start HUD if we're not just refreshing during active biking:
    if (self.bikingState != BikingStateActive)
    {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.labelText = @"Loading stations...";
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:kRefreshTappedNotif
                                                        object:self
                                                      userInfo:nil];
}

- (void)plotStationPosition:(NSArray *)stationList {
    for (id<MKAnnotation> annotation in self.mapView.annotations) {
        if(![annotation isKindOfClass: [MKUserLocation class]])
            [self.mapView removeAnnotation:annotation];
    }
    
    for (Station* station in stationList)
    {
        //TODO: if we should show this... (i.e., if it's public: write a method to determine this. gray it out if it's locked?)
        //add to the map
        [self.mapView addAnnotation:station];
    }
}

#pragma mark -
#pragma mark MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    //TODO: place annotations on top of center bike image, if possible?
    
    static NSString *identifier = @"Station";
    
    if([annotation isKindOfClass: [MKUserLocation class]])
        return nil;
    
    if ([annotation isKindOfClass:[MyLocation class]]) {
//        MyLocation* location = (MyLocation*)annotation;
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
        annotationView = [self.mapView dequeueReusableAnnotationViewWithIdentifier:identifier]; //location.annotationIdentifier];
        
        if (annotationView == nil)
        {
            annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];// location.annotationIdentifier];
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
            
            //            if ([location.annotationIdentifier isEqualToString:kSourceStation])
//            if ([station isEqual:self.sourceStation])
            if (self.sourceStation && (station.stationID == self.sourceStation.stationID))
            {
                //Use green icons to denote a starting point, and show the number of bikes in the start station:
                annotationView.image = [UIImage imageNamed:[NSString stringWithFormat:@"station_pin_green_%02d.png", (station.nbBikes <= 99 ? station.nbBikes : 99)]];
            }
            //            else if ([location.annotationIdentifier isEqualToString:kDestinationStation])
//            else if ([station isEqual:self.currentDestinationStation])
            else if (self.currentDestinationStation && (station.stationID == self.currentDestinationStation.stationID))
            {
                //Use red icons to denote destinations, and show the number of empty docks:
                annotationView.image = [UIImage imageNamed:[NSString stringWithFormat:@"station_pin_red_%02d.png", (station.nbEmptyDocks <= 99 ? station.nbEmptyDocks : 99)]];
            }
            //            else if ([location.annotationIdentifier isEqualToString:kAlternateStation])
            else
            {
                BOOL isClosestStation = NO;
                for (Station *closeStation in self.closestStationsToDestination)
                {
//                    if ([closeStation isEqual:station])
                    if (station.stationID == closeStation.stationID)
                    {
                        //Use blue icons to denote alternate stations:
                        annotationView.image = [UIImage imageNamed:[NSString stringWithFormat:@"station_pin_blue_%02d.png", (station.nbEmptyDocks <= 99 ? station.nbEmptyDocks : 99)]];
                        isClosestStation = YES;
                        break;
                    }
                    //            }
                    //            else if ([location.annotationIdentifier isEqualToString:kStation])
                    //            {
                }
                if (!isClosestStation)
                {
                    //Use blue icons for generic stations in Inactive state as well, but switch between showing the number of bikes or docks based on the toggle control:
                    NSInteger numberToShow = ([self.bikesDocksControl selectedSegmentIndex] == 0) ? station.nbBikes : station.nbEmptyDocks;
                    annotationView.image = [UIImage imageNamed:[NSString stringWithFormat:@"station_pin_blue_%02d.png", (numberToShow <= 99 ? numberToShow : 99)]];
                }
                
            }
            //move the centerOffset up so the "point" of the image is pointed at the station location, instead of the image being centered directly over it:
            annotationView.centerOffset = CGPointMake(1, -16);
        }
        else if ([annotation isKindOfClass:[Address class]])
        {
            Address* address = (Address*)annotation;
            //TODO: get rid of annotationIdentifier property and change this if statement to check if the station id is the same as currentDestinationStation.stationID?
            if ([address.annotationIdentifier isEqualToString:kDestinationLocation])
            {
                //do not show a separate destination annotation if it's the station the user is actually about to bike to
                if (address.coordinate.latitude == self.currentDestinationStation.coordinate.latitude && address.coordinate.longitude == self.currentDestinationStation.coordinate.longitude)
                {
                    return nil;
                }
                annotationView.image = [UIImage imageNamed:@"bikepointer3.png"];
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
        if (self.bikingState == BikingStateInactive)
        {
            [self.destinationDetailLabel setText:nil];
        }
//        [self.destinationDetailLabel setAlpha:0.5];
        [self.startStopButton setEnabled:NO];
    }
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    [self.startStopButton setEnabled:YES];
    
    if (self.bikingState == BikingStateInactive)
    {
        //re-display center bike pointer image
        [self.bikeCrosshairImage setHidden:NO];
        
        //geocode new location, then create a new MyLocation object
        CLLocationCoordinate2D centerCoord = self.mapView.centerCoordinate;
        CLLocation *centerLocation = [[CLLocation alloc] initWithLatitude:centerCoord.latitude longitude:centerCoord.longitude];
        CLGeocoder *geocoder = [[CLGeocoder alloc] init];
        
        [self.mapCenterAddress initCoordinateWithLatitude:centerCoord.latitude longitude:centerCoord.longitude];
        
        //Start spinning the network activity indicator:
//        [(DockSmartAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:YES];

        [geocoder reverseGeocodeLocation:centerLocation completionHandler:^(NSArray *placemarks, NSError *error) {
            
            //Stop spinning the network activity indicator:
//            [(DockSmartAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO];

            if (error)
            {
                DLog(@"Reverse geocode failed with error: %@", error);
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
    
    //Use this location as our final destination, same as selecting it from the Destinations tableView
    //TODO: add action sheet later for adding this location to favorites
    
    //make the user confirm the new destination in an action sheet
    self.selectedLocation = location;
    [self showNavigateActions:self.selectedLocation.name];
}

#pragma mark -
#pragma mark UIActionSheet implementation

- (void)showNavigateActions:(NSString *)title {
    
    NSString *cancelButtonTitle = NSLocalizedString(@"Cancel", @"Cancel button title");
    NSString *navigateHereTitle = NSLocalizedString(@"Navigate Here", @"Navigate Here button title");
    
    // If the user taps a destination to navigate to, present an action sheet to confirm.
    //TODO: Present more options here (to add/delete to/from Favorites, for example).
    self.navSheet = [[UIActionSheet alloc] initWithTitle:title delegate:self cancelButtonTitle:cancelButtonTitle destructiveButtonTitle:nil otherButtonTitles:navigateHereTitle, nil];
    //    [self.navSheet showInView:self.view];
    [self.navSheet showFromTabBar:self.tabBarController.tabBar];
}


- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (buttonIndex == 0)
    {
        /*
         Inform the map view that the user chose to navigate to this destination.
         */
        [[NSNotificationCenter defaultCenter] postNotificationName:kStartBikingNotif
                                                            object:self
                                                          userInfo:[NSDictionary dictionaryWithObject:self.selectedLocation
                                                                                               forKey:kBikeDestinationKey]];
    }
    //else cancel was pressed, just go back to the mapView

    self.selectedLocation = nil;
    self.navSheet = nil;
}

#pragma mark -
#pragma mark KVO support

- (void)addStations:(NSNotification *)notif
{
//    assert([NSThread isMainThread]);
    
    [self insertStations:[[notif userInfo] valueForKey:kStationResultsKey]];
}

- (void)stationError:(NSNotification*)notif
{
    switch (self.bikingState) {
        case BikingStateInactive:
            //Reload map view with the full set of station annotations from the last time we were able to get station data:
            [self plotStationPosition:self.dataController.stationList];
            break;
            
        case BikingStatePreparingToBike:
            //Set up new route with old data, so user can at least see where they need to go, even if the data is old:
            [self updateActiveBikingViewWithNewDestination:YES];
            break;
            
        case BikingStateActive:
            //do nothing, the user will just keep biking and we'll get new data the next time we connect
            //Pretend there's new data in case we just entered a geofence and we want to tell a user to dock
            [self willChangeValueForKey:kStationList];
            [self didChangeValueForKey:kStationList];
            break;
            
        case BikingStateTrackingDidStop:
            //Show route setup screen again, using the last available data:
            [self updateActiveBikingViewWithNewDestination:NO];
            break;
        default:
            break;
    }
    //Hide the HUD
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

- (void)insertStations:(NSArray *)stations
{
    // this will allow us as an observer to notified (see observeValueForKeyPath)
    // so we can update our MapView
    //
    [self willChangeValueForKey:kStationList];

    //Clear out current stations:
    [self.dataController.stationList removeAllObjects];
    //Add new stations:
    [self.dataController addLocationObjectsFromArray:stations toList:self.dataController.stationList];

    [self didChangeValueForKey:kStationList];
}

- (void)prepareNewBikeRoute:(NSNotification *)notif
{
//    assert([NSThread isMainThread]);
    
    //Set up a new route:
    [self prepareBikeRouteWithDestination:[[notif userInfo] valueForKey:kBikeDestinationKey] newDestination:YES];
}

- (void)prepareBikeRouteWithDestination:(MyLocation *)dest newDestination:(BOOL)newDest
{
    //Get ready to bike, set the new state and the final destination location
    self.bikingState = (newDest) ? BikingStatePreparingToBike : BikingStateTrackingDidStop;
    self.finalDestination = [dest copy];

    //Start tracking user location
    [[LocationController sharedInstance] startUpdatingCurrentLocation];
    
    //Disable the bikes/docks toggle:
    [self.bikesDocksControl setHidden:YES];
    //Disable the start/stop button until the data is refreshed:
    [self.startStopButton setEnabled:NO];
    
    //TODO: just call refreshWasTapped: here?
    //Start HUD:
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = @"Loading stations...";

    //Refresh all station data to get the absolute latest nbBikes and nbEmptyDocks counts.
    //Equivalent to hitting Refresh:
    [[NSNotificationCenter defaultCenter] postNotificationName:kRefreshTappedNotif
                                                        object:self
                                                      userInfo:nil];
}

#if 0
- (void)prepareBikeRouteCallback
{
    [self updateActiveBikingViewWithNewDestination:YES];
}
#endif

- (void)clearBikeRouteWithRefresh:(BOOL)refresh
{
    if (refresh)
    {
        //Refresh all station data to get the absolute latest nbBikes and nbEmptyDocks counts.
        
        //TODO: just call refreshWasTapped: here?
        //Start HUD:
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.labelText = @"Loading stations...";

        //Equivalent to hitting Refresh:
        [[NSNotificationCenter defaultCenter] postNotificationName:kRefreshTappedNotif
                                                            object:self
                                                          userInfo:nil];
    }
    
    //re-center map on previous final destination
    [self.mapView setCenterCoordinate:self.finalDestination.coordinate animated:YES];
    
    //re-display center bike pointer image (done in mapView:regionDidChangeAnimated: once the map stops moving)
    
    //re-enable the bikes/docks toggle:
    [self.bikesDocksControl setHidden:NO];
    
    //Change buttons and label:
    [self.destinationDetailLabel setText:[self.finalDestination name]];
//    [self.startStopButton setBackgroundColor:[UIColor whiteColor]];
    
    /* iOS6 : pre-toolbar */
//    [self.startStopButton setTitleColor:[UIColor colorWithRed:.196 green:0.3098 blue:0.52 alpha:1.0] forState:UIControlStateNormal];
//    [self.startStopButton setTitle:@"Set Destination" forState:UIControlStateNormal];
    /* iOS7 : with toolbar */
    [self.startStopButton setEnabled:YES];
    [self.startStopButton setTintColor: nil];
    [self.startStopButton setTitle:@"Set Destination"];
    
    //hide cancel button
    /* iOS6 : pre-toolbar */
//    [self.cancelButton setHidden:YES];
    /* iOS7 : with toolbar */
    [self.cancelButton setEnabled:NO];
    
    //Return to idle/inactive state
    self.bikingState = BikingStateInactive;
    self.finalDestination = nil;
    self.sourceStation = nil;
    self.currentDestinationStation = nil;
    self.idealDestinationStation = nil;
    self.closestStationsToDestination = nil;
}

- (void)updateActiveBikingViewWithNewDestination:(BOOL)newDest
{
    //Calculate and store the distances from the destination to each station:
    for (Station *station in self.dataController.stationList)
    {
        station.distanceFromDestination = MKMetersBetweenMapPoints(MKMapPointForCoordinate(station.coordinate), MKMapPointForCoordinate(self.finalDestination.coordinate));
    }
    
    //Figure out the three closest stations to the destination:
    //First sort by distance from destination:
    [self.dataController setSortedStationList:[self.dataController sortLocationList:[self.dataController stationList] byMethod:LocationDataSortByDistanceFromDestination]];
    //Then grab the top 3:
    self.closestStationsToDestination = [[self.dataController.sortedStationList objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 3)]] mutableCopy];
    
    //Figure out the closest station to the user with at least one bike
    //First sort by distance from user:
    [self.dataController setSortedStationList:[self.dataController sortLocationList:[self.dataController stationList] byMethod:LocationDataSortByDistanceFromUser]];
    //Then grab the top one with a bike:
    for (Station *station in self.dataController.sortedStationList)
    {
        if ([station nbBikes] >= 1)
        {
            if (self.sourceStation && (self.sourceStation.stationID != station.stationID))
            {
                //TODO if we previously had a different non-nil sourceStation, should we alert the user that the closest station with a bike has changed?
            }
            self.sourceStation = station;
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
    annotationPoint = MKMapPointForCoordinate(self.sourceStation.coordinate);
    MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0.1, 0.1);
    zoomRect = MKMapRectUnion(zoomRect, pointRect);
    //Then add the destination:
    annotationPoint = MKMapPointForCoordinate(self.finalDestination.coordinate);
    pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0.1, 0.1);
    zoomRect = MKMapRectUnion(zoomRect, pointRect);
    //Then add the closest stations to the destination:
    for (Station* station in self.closestStationsToDestination)
    {
        annotationPoint = MKMapPointForCoordinate(station.coordinate);
        pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0.1, 0.1);
        zoomRect = MKMapRectUnion(zoomRect, pointRect);
    }
    //increased edge padding so all relevant markers are visible
    [self.mapView setVisibleMapRect:zoomRect edgePadding:UIEdgeInsetsMake(104, 15, 104, 15) animated:YES];
    
    //Change the annotation identifiers for the Station/MyLocation objects we want to view as annotations on the map:
    //i.e. change the pin color (other attributes?) for start, end and backup end stations
    self.sourceStation.annotationIdentifier = kSourceStation;
    self.finalDestination.annotationIdentifier = kDestinationLocation;
    //Label the closest destination to the finalDestination as the idealDestinationStation, so if it's full we can check to see if a dock opens up there later.
    self.idealDestinationStation = [self.closestStationsToDestination objectAtIndex:0];
    //Destination stations: label the closest one with at least one empty dock as the current destination and the rest as "alternates."
    BOOL destinationFound = NO;
    for (Station* station in self.closestStationsToDestination)
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

    //TODO: If there is no station in closestStationsToDestination with >0 nbEmptyDocks, do we warn the user or just keep going down the list?

    /* JUST WALK ALERTS:
     If the closest station to the destination is also the closest one to the user, perhaps it's best to just tell the user to walk.
     (Do not use sourceStation in case there is one closer with no bikes... use the top of the sorted station list instead)
     ALSO: Show this alert as well if the destination station is different but
     (dist(user to sourceStation) + dist(destinationStation to finalDestination) >= dist(user to finalDestination)), 
     otherwise the user is walking an equal or longer distance (to the closest station with a bike, plus from the station nearest to 
     their destination with a dock) as well as biking, which is foolish
     */
    if ((self.idealDestinationStation.stationID == [[self.dataController.sortedStationList objectAtIndex:0] stationID]) ||
        ((self.sourceStation.distanceFromUser + self.currentDestinationStation.distanceFromDestination) >= self.finalDestination.distanceFromUser))
    {
        //Only show an alertView popup if newDest == YES (so we don't show a Just Walk alert if the app stops tracking, either manually or automatically, when the user gets to their destination)
        if (newDest)
        {
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Walk to your destination!"
                                                        message:nil
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
            if (self.idealDestinationStation.stationID == [[self.dataController.sortedStationList objectAtIndex:0] stationID])
            {
                [av setMessage:@"The destination station is also the closest one to your current location. Perhaps it's best to just walk."];
            }
            else
            {
                [av setMessage:@"The best stations to start and finish your route are both out of the way. Perhaps it's best to just walk."];
            }
            [av show];
            
            //return to idle
            [self clearBikeRouteWithRefresh:NO];
            [self plotStationPosition:self.dataController.stationList];
            
            return;
        }
        else
        {
            //If our final destination isn't the station itself, change label to show where to walk:
            if (self.finalDestination.coordinate.latitude != self.currentDestinationStation.coordinate.latitude && self.finalDestination.coordinate.longitude != self.currentDestinationStation.coordinate.longitude)
            {
                [self.destinationDetailLabel setText:[NSString stringWithFormat:@"Walk to %@", self.finalDestination.name]];
            }
            else //We've reached our final destination (which is either the idealDestinationStation or a non-station Address)
            {
                [self.destinationDetailLabel setText:@"You have arrived!"];
            }
        }
    }
    else
    {
        //Change label to show where to pick up and drop off your bike:
        [self.destinationDetailLabel setText:[NSString stringWithFormat:@"Pick up bike at %@ - %d bike%@ available\nBike to %@ - %d empty dock%@", self.sourceStation.name, self.sourceStation.nbBikes, (self.sourceStation.nbBikes > 1) ? @"s" : @"", self.currentDestinationStation.name, self.currentDestinationStation.nbEmptyDocks, (self.currentDestinationStation.nbEmptyDocks > 1) ? @"s" : @""]];
    }
    
    //Hide the annotations for all other stations.
//    [self.mapView removeAnnotations:self.mapView.annotations];
    for (id<MKAnnotation> annotation in self.mapView.annotations) {
        if(![annotation isKindOfClass: [MKUserLocation class]])
            [self.mapView removeAnnotation:annotation];
    }
    //Hide center bike pointer image
    [self.bikeCrosshairImage setHidden:YES];
    
    //Change buttons:
    /* iOS6 : pre-toolbar */
    //        [self.startStopButton setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
    //        [self.startStopButton setTitle:@"Start Station Tracking" forState:UIControlStateNormal];
    //        [self.cancelButton setHidden:NO];
    /* iOS7 : with toolbar */
    [self.startStopButton setTintColor:[UIColor greenColor]];
    [self.startStopButton setTitle:@"Start Station Tracking"];
    [self.startStopButton setEnabled:YES];
    [self.cancelButton setEnabled:YES];
    
    //Add new annotations.
    //TODO: update distanceFromUser, etc (other properties) in local MyLocation objects (finalDestination, etc) here? instead of in startStationTracking for example?
    [self.mapView addAnnotation:self.sourceStation];
    
    if (self.finalDestination.coordinate.latitude != self.currentDestinationStation.coordinate.latitude && self.finalDestination.coordinate.longitude != self.currentDestinationStation.coordinate.longitude)
        [self.mapView addAnnotation:self.finalDestination];
    
    for (Station* station in self.closestStationsToDestination)
    {
        [self.mapView addAnnotation:station];
    }
}

- (void)startStationTracking
{

    //Create regions to monitor via geofencing app wakeups:
    //Concentric circles, getting closer to the final destination:
    
    [self.finalDestination setDistanceFromUser:MKMetersBetweenMapPoints(MKMapPointForCoordinate(self.dataController.userCoordinate), MKMapPointForCoordinate(self.finalDestination.coordinate))];
    
    
    [[LocationController sharedInstance] registerRegionWithCoordinate:self.finalDestination.coordinate 
                                                               radius:(self.finalDestination.distanceFromUser*0.67f)
                                                           identifier:kRegionMonitorTwoThirdsToGo
                                                             accuracy:kCLLocationAccuracyNearestTenMeters];
    [[LocationController sharedInstance] registerRegionWithCoordinate:self.finalDestination.coordinate 
                                                               radius:(self.finalDestination.distanceFromUser*0.33f)
                                                           identifier:kRegionMonitorOneThirdToGo
                                                             accuracy:kCLLocationAccuracyNearestTenMeters];
    
    //One more region for each of the three closest stations to the final destination:
//    for (Station* station in self.closestStationsToDestination)
//    {
    [[LocationController sharedInstance] registerRegionWithCoordinate:((Station*)[self.closestStationsToDestination objectAtIndex:0]).coordinate radius:10 identifier:kRegionMonitorStation1 accuracy:kCLLocationAccuracyBest];
    [[LocationController sharedInstance] registerRegionWithCoordinate:((Station*)[self.closestStationsToDestination objectAtIndex:1]).coordinate radius:10 identifier:kRegionMonitorStation2 accuracy:kCLLocationAccuracyBest];
    [[LocationController sharedInstance] registerRegionWithCoordinate:((Station*)[self.closestStationsToDestination objectAtIndex:2]).coordinate radius:10 identifier:kRegionMonitorStation3 accuracy:kCLLocationAccuracyBest];

//    }
    
    //TODO: Start the rental timer, if we have one
    
    //Start minute timer:
    
    NSString* logText = [NSString stringWithFormat:@"Starting minute timer"];
    DLog(@"%@",logText);
    [[NSNotificationCenter defaultCenter] postNotificationName:kLogToTextViewNotif
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:logText
                                                                                           forKey:kLogTextKey]];
    
    self.minuteTimer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(refreshWasTapped) userInfo:nil repeats:YES];
    
    //Change the state to active:
    self.bikingState = BikingStateActive;
}

- (void)stopStationTracking
{
    //Stop timer:
    [self.minuteTimer invalidate];
    self.minuteTimer = nil;
    
    //Turn off geofencing:
    [[LocationController sharedInstance] stopAllRegionMonitoring];
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
    NSString* logText = [NSString stringWithFormat:@"NEW STATION DATA: bikingState: %d", self.bikingState];
    DLog(@"%@",logText);
    [[NSNotificationCenter defaultCenter] postNotificationName:kLogToTextViewNotif
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:logText
                                                                                           forKey:kLogTextKey]];

    switch (self.bikingState) {
        case BikingStateInactive:
            //Reload map view
//            if (![NSThread isMainThread]) {
//                [self performSelectorOnMainThread:@selector(plotStationPosition:) withObject:self.dataController.stationList waitUntilDone:NO];
//            }
//            else
//            {
                [self plotStationPosition:self.dataController.stationList];
//            }
            break;
        case BikingStatePreparingToBike:
            //Do not reload the map view yet, just go to the callback to finish the setup to start biking:
            [self updateActiveBikingViewWithNewDestination:YES];
            break;
        case BikingStateActive:
        {
            BOOL notifSent = NO;
            BOOL endTracking = NO;
            NSString *newlyFullStationName = nil;
            
            //Do not reload the map view at all, unless the app is coming back into the foreground.  Just check to see if we need to send a notification based on nbEmptyDocks for our current goal station
            for (Station *station in self.dataController.stationList)
            {
                if (station.stationID == self.sourceStation.stationID)
                {
                    self.sourceStation = station;
                }
                
                NSUInteger stationIndex = [self.closestStationsToDestination indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                    Station *stationObj = (Station *)obj;
                    return (stationObj.stationID == station.stationID);
                }];
                
                if (stationIndex != NSNotFound)
                {
//                    DLog(@"stationIndex = %d", stationIndex);
//                    DLog(@"station.stationID = %d", station.stationID);
//                    DLog(@"station.name = %@", station.name);
//                    DLog(@"station = %08x", (unsigned int)station);
//                    DLog(@"closeststations = %08x %08x %08x", (unsigned int)[self.closestStationsToDestination objectAtIndex:0], (unsigned int)[self.closestStationsToDestination objectAtIndex:1], (unsigned int)[self.closestStationsToDestination objectAtIndex:2]);
                    [self.closestStationsToDestination replaceObjectAtIndex:stationIndex withObject:station];
                }
                
                //reassign class pointers to new data:
                if (station.stationID == self.idealDestinationStation.stationID)
                {
                    //check to see if we're at the ideal station with a dock available:
                    for (NSString *identifier in self.regionIdentifierQueue)
                    {
                        if ([identifier isEqualToString:kRegionMonitorStation1] && (station.nbEmptyDocks > 0))
                        {
                            //if there's a dock available now, it doesn't matter if we thought we were going somewhere else before, just tell the user to stop here:
                            self.currentDestinationStation.annotationIdentifier = kAlternateStation;
                            self.currentDestinationStation = station;
                            self.currentDestinationStation.annotationIdentifier = kDestinationStation;
                            
                            UILocalNotification *stopAtIdealStationNotification = [[UILocalNotification alloc] init];
                            [stopAtIdealStationNotification setAlertBody:[NSString stringWithFormat:@"Dock here! You have reached the station closest to your destination, %@. Station tracking will end.", self.idealDestinationStation.name]];
                            stopAtIdealStationNotification.soundName = @"bicycle_bell.wav";
                            [stopAtIdealStationNotification setFireDate:[NSDate date]];
                            [[UIApplication sharedApplication] scheduleLocalNotification:stopAtIdealStationNotification];
                            
                            notifSent = YES;
                            endTracking = YES;
                            break;
                        }
                    }
                    //otherwise, if we're heading to a non-ideal station, check to see if a dock at the ideal station has opened up.
                    if (!endTracking && (self.currentDestinationStation.stationID != station.stationID) && (station.nbEmptyDocks > 0) && (self.idealDestinationStation.nbEmptyDocks == 0))
                    {
//                      NSString *cancelButtonTitle = NSLocalizedString(@"Cancel", @"Cancel button title");
                        
                        //Alert the user to bike to the idealDestinationStation instead!
                        self.currentDestinationStation.annotationIdentifier = kAlternateStation;
                        self.currentDestinationStation = station;
                        self.currentDestinationStation.annotationIdentifier = kDestinationStation;
                        
                        UILocalNotification *bikeToIdealStationNotification = [[UILocalNotification alloc] init];
                        [bikeToIdealStationNotification setAlertBody:[NSString stringWithFormat:@"A dock has opened up at %@! Bike there instead!", self.currentDestinationStation.name]];
                        bikeToIdealStationNotification.soundName = @"bicycle_bell.wav";
                        [bikeToIdealStationNotification setFireDate:[NSDate date]];
                        [[UIApplication sharedApplication] scheduleLocalNotification:bikeToIdealStationNotification];
                        
                        notifSent = YES;
                    }
                    //update this pointer... will always continue to be the same stationID
                    self.idealDestinationStation = station;
                }
                if (station.stationID == self.currentDestinationStation.stationID)
                {
                    //the ideal non-current station did not empty out... but check if the currentDestinationStation filled up:
                    if (self.currentDestinationStation.nbEmptyDocks > 0 && station.nbEmptyDocks == 0)
                    {
                        //it filled up... alert the user to go to the next non-empty station
                        //re-sort station list with the distance from the destination
//                        [self.dataController setSortedStationList:[self.dataController sortLocationList:self.dataController.stationList byMethod:LocationDataSortByDistanceFromDestination]];
                        for (Station *newStation in self.closestStationsToDestination)
                        {
                            if (newStation.nbEmptyDocks > 0)
                            {
                                self.currentDestinationStation.annotationIdentifier = kAlternateStation;
                                self.currentDestinationStation = newStation;
                                self.currentDestinationStation.annotationIdentifier = kDestinationStation;
                                
                                newlyFullStationName = station.name;
//                                UILocalNotification *bikeToNextBestStationNotification = [[UILocalNotification alloc] init];
//                                [bikeToNextBestStationNotification setAlertBody:[NSString stringWithFormat:@"The station at %@ has filled up. Bike to %@ instead.", station.name, self.currentDestinationStation.name]];
//                                bikeToNextBestStationNotification.soundName = @"bicycle_bell.wav";
//                                [bikeToNextBestStationNotification setFireDate:[NSDate date]];
//                                [[UIApplication sharedApplication] scheduleLocalNotification:bikeToNextBestStationNotification];
//                                notifSent = YES;
                                
                                break;
                            }
                        }
                    }
                    else
                    {
                        self.currentDestinationStation = station;
                    }
                }
                
                //else, the user should just keep biking to the currentDestinationStation...
            }
            //...unless they're already there
            for (NSString *identifier in self.regionIdentifierQueue)
            {
                
                if (!notifSent &&
                    (   ((self.currentDestinationStation.stationID == [[self.closestStationsToDestination objectAtIndex:1] stationID])
                         && [identifier isEqualToString:kRegionMonitorStation2])
                     || ((self.currentDestinationStation.stationID == [[self.closestStationsToDestination objectAtIndex:2] stationID])
                         && [identifier isEqualToString:kRegionMonitorStation3])
                     ))
                {
                    //We've reached an alternate station. if we've reached this point, no docks have opened up at the ideal station, so just dock here and walk the rest of the way
                    UILocalNotification *stopAtCurrentStationNotification = [[UILocalNotification alloc] init];
                    [stopAtCurrentStationNotification setAlertBody:[NSString stringWithFormat:@"Dock here! You have reached the station closest to your destination with an empty dock, %@. Station tracking will end.", self.currentDestinationStation.name]];
                    stopAtCurrentStationNotification.soundName = @"bicycle_bell.wav";
                    [stopAtCurrentStationNotification setFireDate:[NSDate date]];
                    [[UIApplication sharedApplication] scheduleLocalNotification:stopAtCurrentStationNotification];
                    
                    endTracking = YES;
                    break;
                }
            }
            if (!endTracking && newlyFullStationName != nil)
            {
                UILocalNotification *bikeToNextBestStationNotification = [[UILocalNotification alloc] init];
                [bikeToNextBestStationNotification setAlertBody:[NSString stringWithFormat:@"The station at %@ has filled up. Bike to %@ instead.", newlyFullStationName, self.currentDestinationStation.name]];
                bikeToNextBestStationNotification.soundName = @"bicycle_bell.wav";
                [bikeToNextBestStationNotification setFireDate:[NSDate date]];
                [[UIApplication sharedApplication] scheduleLocalNotification:bikeToNextBestStationNotification];
            }
            
            if (!endTracking)
            {
                //reload annotations
                //          [self updateActiveBikingViewWithNewDestination:NO];
                
                //Hide the annotations for all other stations.
                //          [self.mapView removeAnnotations:self.mapView.annotations];
                for (id<MKAnnotation> annotation in self.mapView.annotations) {
                    if(![annotation isKindOfClass: [MKUserLocation class]])
                        [self.mapView removeAnnotation:annotation];
                }
                
                //Change buttons and label:
                [self.destinationDetailLabel setText:[NSString stringWithFormat:@"Pick up bike at %@ - %d bike%@ available\nBike to %@ - %d empty dock%@", self.sourceStation.name, self.sourceStation.nbBikes, (self.sourceStation.nbBikes > 1) ? @"s" : @"", self.currentDestinationStation.name, self.currentDestinationStation.nbEmptyDocks, (self.currentDestinationStation.nbEmptyDocks > 1) ? @"s" : @""]];
                
                //Add new annotations.
                //TODO: pull this into its own method for code reuse
                //if final destination and current destination station are the same object, only show the station object
                [self.mapView addAnnotation:self.sourceStation];
                if (self.finalDestination.coordinate.latitude != self.currentDestinationStation.coordinate.latitude && self.finalDestination.coordinate.longitude != self.currentDestinationStation.coordinate.longitude)
                    [self.mapView addAnnotation:self.finalDestination];
                for (Station* station in self.closestStationsToDestination)
                {
                    [self.mapView addAnnotation:station];
                }
            }
            else
            {
                //Stop tracking stations:
                [self stopStationTracking];
                //Show the route setup screen again:
                [self prepareBikeRouteWithDestination:self.finalDestination newDestination:NO];
            }
            
            //clear out the region identifier queue so we don't alert at the wrong time
            [self.regionIdentifierQueue removeAllObjects];
            
        }
            break;
        case BikingStateTrackingDidStop:
            //Allow the user to restart the same route, but don't give them a "Just walk" alert if they're close to their destination:
            [self updateActiveBikingViewWithNewDestination:NO];
            break;
        default:
            break;
    }
    
    //Hide the HUD
    [MBProgressHUD hideHUDForView:self.view animated:YES];

}

- (IBAction)refeshTapped:(id)sender {
//    [self performSelectorOnMainThread:@selector(refreshWasTapped)
//                           withObject:nil
//                        waitUntilDone:NO];
    [self refreshWasTapped];
}

- (IBAction)cancelTapped:(id)sender {
    
    //log it for debugging
    NSString* logText = [NSString stringWithFormat:@"cancelTapped"];
    DLog(@"%@",logText);
    [[NSNotificationCenter defaultCenter] postNotificationName:kLogToTextViewNotif
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:logText
                                                                                           forKey:kLogTextKey]];

    //reset to inactive
    [self clearBikeRouteWithRefresh:YES];
}

- (IBAction)startStopTapped:(UIButton *)sender {
    switch (self.bikingState) {
        case BikingStateInactive:
            //set the final destination to equal the placemark at the center of the crosshairs and prepare a new route to the location
            [self prepareBikeRouteWithDestination:self.mapCenterAddress newDestination:YES];
            break;
        case BikingStatePreparingToBike:
        case BikingStateTrackingDidStop:
            //Change buttons:

            /* iOS6 : pre-toolbar */
//            [self.startStopButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
//            [self.startStopButton setTitle:@"Stop Station Tracking" forState:UIControlStateNormal];
//            [self.cancelButton setHidden:YES];
            
            /* iOS7 : with toolbar */
            [self.startStopButton setTintColor:[UIColor redColor]];
            [self.startStopButton setTitle:@"Stop Station Tracking"];
            [self.cancelButton setEnabled:NO];
            
            //Start station tracking:
            [self startStationTracking];
            
            break;
        case BikingStateActive:
            //stop station tracking and return to the route setup screen
            [self stopStationTracking];
            //setup route screen:
            [self prepareBikeRouteWithDestination:self.finalDestination newDestination:NO];

            break;
        default:
            break;
    }
}

- (IBAction)bikesDocksToggled:(id)sender {
    //replot the station annotations with either the number of bikes or empty docks at each
    [self plotStationPosition:self.dataController.stationList];
}

- (IBAction)updateLocationTapped:(id)sender {
    [[LocationController sharedInstance] startUpdatingCurrentLocation];
//    MKCoordinateRegion region = [self.mapView region];
//    region.center = [[[LocationController sharedInstance] location] coordinate];
//    region.center = [[self.mapView userLocation] coordinate];
//    [self.mapView setRegion:region animated:YES];
    if ([[self.mapView userLocation] location])
    {
        [self.mapView setCenterCoordinate:self.mapView.userLocation.location.coordinate animated:YES];
    }
        
    //TODO: map sometimes doesn't update? specifically if biking state is active and zoomed in on destination bikes, and/or if wifi is off
}

- (void)updateLocation:(NSNotification *)notif
{
    if (self.bikingState != BikingStateActive)
    {
        [[LocationController sharedInstance] stopUpdatingCurrentLocation];
    }
}

- (void)regionEntered:(NSNotification *)notif
{
    //Mark the region that we just entered:
//    self.regionIdentifier = [(CLRegion *)[[notif userInfo] valueForKey:kNewRegionKey] identifier];
    if (!self.regionIdentifierQueue)
    {
        //allocate for the queue if it is nil
        self.regionIdentifierQueue = [[NSMutableArray alloc] init];
    }
    [self.regionIdentifierQueue addObject:[(CLRegion *)[[notif userInfo] valueForKey:kNewRegionKey] identifier]];

    //We hit a geofence. Get a bike data update
    [self refreshWasTapped];
}

- (void)regionExited:(NSNotification *)notif
{
    //Get another bike data update
    [self refreshWasTapped];
}

#pragma mark - UIBarPositioningDelegate

//iOS7 compatibility: attach toolbar to the status bar instead of overlapping the two
- (UIBarPosition)positionForBar:(id <UIBarPositioning>)bar
{
    return UIBarPositionTopAttached;
}

@end
