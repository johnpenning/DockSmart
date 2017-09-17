
//
//  DockSmartMapViewController.m
//  DockSmart
//
//  Created by John Penning on 4/30/13.
//  Copyright (c) 2013 John Penning. All rights reserved.
//

#import "DockSmartMapViewController.h"
#import "Address.h"
#import "DockSmartAppDelegate.h"
#import "DockSmartDestinationsMasterViewController.h"
#import "DockSmartLogViewController.h"
#import "LocationDataController.h"
#import "MBProgressHUD.h"
#import "Station.h"
#import "define.h"

#pragma mark - Key Definitions

// Global keys

// NSNotification name for reporting that refresh was tapped
NSString *const kRefreshDataNotif = @"RefreshDataNotif";
// userInfo key for stationList data
NSString *const kStationList = @"stationList";

// Key noting if user has seen the intro screen/alert
NSString *const kHasSeenIntro = @"hasSeenIntro";

// Region monitoring identifiers:
NSString *const kRegionMonitorTwoThirdsToGo = @"RegionMonitorTwoThirdsToGo";
NSString *const kRegionMonitorOneThirdToGo = @"RegionMonitorOneThirdToGo";
NSString *const kRegionMonitorStation1 = @"RegionMonitorStation1";
NSString *const kRegionMonitorStation2 = @"RegionMonitorStation2";
NSString *const kRegionMonitorStation3 = @"RegionMonitorStation3";

#pragma mark - Interface

@interface DockSmartMapViewController ()
- (IBAction)refreshTapped:(id)sender;
- (IBAction)cancelTapped:(id)sender;
- (IBAction)startStopTapped:(id)sender;
- (IBAction)bikesDocksToggled:(id)sender;
- (IBAction)updateLocationTapped:(id)sender;

// Button to set destination, start and stop station tracking
@property(weak, nonatomic) IBOutlet UIBarButtonItem *startStopButton;
// Label that shows the address of the destination and details about start/end
// stations
@property(weak, nonatomic) IBOutlet UILabel *destinationDetailLabel;
// Image at center of map that points to where the user wants to set their
// destination
@property(weak, nonatomic) IBOutlet UIImageView *bikeCrosshairImage;
// Button to cancel out of the current route
@property(weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;
// Toggle switch to alternate between showing the number of bikes and docks on
// the annotationView for each station
@property(weak, nonatomic) IBOutlet UISegmentedControl *bikesDocksControl;

// location property for the center of the map:
@property(nonatomic) Address *mapCenterAddress;
// bool flag to determine if we need to pan to the user location once it's
// acquired:
@property(nonatomic) BOOL needsNewCenter;

// keep track of the station we're getting the bike from:
@property(nonatomic) Station *sourceStation;
// keep track of where we're going:
@property(nonatomic) MyLocation *finalDestination;
@property(nonatomic) Station *currentDestinationStation;
@property(nonatomic) Station *idealDestinationStation;
@property(nonatomic) NSMutableArray *closestStationsToDestination;
// Keep track of all geofences we've entered that we haven't processed yet:
@property(nonatomic) NSMutableArray *regionIdentifierQueue;
// the action sheet to show when making a user confirm their station destination
@property(nonatomic, readwrite) UIActionSheet *navSheet;
// The station that the user selected that they need to confirm in the navSheet
@property(nonatomic) MyLocation *selectedLocation;

// timer to refresh data:
@property(nonatomic) NSTimer *minuteTimer;
// last time the data was updated:
@property(nonatomic) NSDate *lastDataUpdateTime;

@end

#pragma mark - Implementation

@implementation DockSmartMapViewController

- (void)awakeFromNib
{
    [super awakeFromNib];

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
    DLog(@"viewDidLoad");

    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    // iOS7 compatibility: allow us to programmatically attach the toolbar to the
    // status bar
    [self.topMapToolbar setDelegate:self];

    self.dataController = [[LocationDataController alloc] init];
    self.mapCenterAddress = [[Address alloc] init];
    self.closestStationsToDestination = [[NSMutableArray alloc] initWithCapacity:3];
    self.regionIdentifierQueue = [[NSMutableArray alloc] init];

    // KVO: listen for changes to our station data source for map view updates
    [self addObserver:self forKeyPath:kStationList options:0 context:NULL];

    // initialize states
    [self setBikingState:BikingStateInactive];

    // Define the initial zoom location
    CLLocationCoordinate2D zoomLocation;
    // If we have a mapView.userLocation.location != nil, use that as the center
    // here. Else use a default location, set a flag, wait for it to update and
    // then pan/zoom when we have the new location. If there's a location saved in
    // state restoration, just use that one instead. Perform reverse geocode after
    // settling on wherever we end up.
    if (self.mapView.userLocation.location) {
        zoomLocation = self.mapView.userLocation.location.coordinate;
    } else {
        // Default location = center of Dupont Circle (sure, why not?)
        zoomLocation = CLLocationCoordinate2DMake((CLLocationDegrees)DUPONT_LAT, (CLLocationDegrees)DUPONT_LONG);
        self.needsNewCenter = YES;
    }

    [self.mapView setCenterCoordinate:zoomLocation animated:YES];

    // Show the license agreement alert if this is the first time the app has been
    // opened:
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults boolForKey:kHasSeenIntro]) {
        [defaults setBool:YES forKey:kHasSeenIntro];
        [defaults synchronize];

        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Welcome to DockSmart!"
                                                     message:@"By using this app, you agree to be legally bound "
                                                             @"by all the terms of the License Agreement located "
                                                             @"by exiting the app and selecting Settings -> "
                                                             @"DockSmart -> License Agreement.\n\nDon't use the "
                                                             @"app while biking, and ride safely!"
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
    DLog(@"viewWillAppear");

    // Make sure the user has enabled location services before attempting to get
    // the location
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied ||
        [CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted ||
        [CLLocationManager locationServicesEnabled] == NO) {
        [self.updateLocationButton setEnabled:NO];
    } else {
        [self.updateLocationButton setEnabled:YES];
        [[LocationController sharedInstance] startUpdatingCurrentLocation];
    }

    [super viewWillAppear:animated];
}

- (void)viewDidUnload
{
    [self setStartStopButton:nil];
    [self setDestinationDetailLabel:nil];
    [self setBikeCrosshairImage:nil];
    [self setCancelButton:nil];
    [self setBikesDocksControl:nil];
    [self setUpdateLocationButton:nil];
    [super viewDidUnload];
}

- (void)dealloc
{
    self.dataController.stationList = nil;

    [self unregisterFromKVO];
}

#pragma mark - State Restoration

// Archive file name:
static NSString *const kStationDataFile = @"stationData.txt";
// Keys:
static NSString *const BikesDocksControlKey = @"BikesDocksControlKey";
static NSString *const BikesDocksControlHiddenKey = @"BikesDocksControlHiddenKey";
static NSString *const BikingStateKey = @"BikingStateKey";
static NSString *const DataControllerKey = @"DataControllerKey";
static NSString *const SourceStationKey = @"SourceStationKey";
static NSString *const FinalDestinationKey = @"FinalDestinationKey";
static NSString *const CurrentDestinationStationKey = @"CurrentDestinationStationKey";
static NSString *const IdealDestinationStationKey = @"IdealDestinationStationKey";
static NSString *const ClosestStationsToDestinationKey = @"ClosestStationsToDestinationKey";
static NSString *const MinuteTimerValidKey = @"MinuteTimerValidKey";
static NSString *const MinuteTimerFireDateKey = @"MinuteTimerFireDateKey";
static NSString *const StartStopButtonTitleKey = @"StartStopButtonTitleKey";
static NSString *const StartStopButtonTintColorKey = @"StartStopButtonTintColorKey";
static NSString *const StartStopButtonEnabledKey = @"StartStopButtonEnabledKey";
static NSString *const DestinationDetailLabelKey = @"DestinationDetailLabelKey";
static NSString *const BikeCrosshairImageKey = @"BikeCrosshairImageKey";
static NSString *const CancelButtonKey = @"CancelButtonKey";
static NSString *const MapCenterAddressKey = @"MapCenterAddressKey";
static NSString *const RegionCenterLatKey = @"RegionCenterLatKey";
static NSString *const RegionCenterLongKey = @"RegionCenterLongKey";
static NSString *const RegionSpanLatKey = @"RegionSpanLatKey";
static NSString *const RegionSpanLongKey = @"RegionSpanLongKey";
static NSString *const RegionIdentifierKey = @"RegionIdentifierKey";
static NSString *const UpdateLocationButtonEnabledKey = @"UpdateLocationButtonEnabledKey";
static NSString *const LastDataUpdateTimeKey = @"LastDataUpdateTimeKey";

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super encodeRestorableStateWithCoder:coder];

    // Encode view-related objects:
    [coder encodeInteger:self.bikesDocksControl.selectedSegmentIndex forKey:BikesDocksControlKey];
    [coder encodeBool:self.bikesDocksControl.hidden forKey:BikesDocksControlHiddenKey];
    [coder encodeBool:self.minuteTimer.isValid forKey:MinuteTimerValidKey];
    [coder encodeObject:self.startStopButton.title forKey:StartStopButtonTitleKey];
    [coder encodeObject:self.startStopButton.tintColor forKey:StartStopButtonTintColorKey];
    [coder encodeBool:self.startStopButton.enabled forKey:StartStopButtonEnabledKey];
    [coder encodeObject:self.destinationDetailLabel.text forKey:DestinationDetailLabelKey];
    [coder encodeBool:self.cancelButton.enabled forKey:CancelButtonKey];
    [coder encodeBool:self.updateLocationButton.enabled forKey:UpdateLocationButtonEnabledKey];
    [coder encodeDouble:[self.mapView region].center.latitude forKey:RegionCenterLatKey];
    [coder encodeDouble:[self.mapView region].center.longitude forKey:RegionCenterLongKey];
    [coder encodeDouble:[self.mapView region].span.latitudeDelta forKey:RegionSpanLatKey];
    [coder encodeDouble:[self.mapView region].span.longitudeDelta forKey:RegionSpanLongKey];

    // Archive the state of the view controller:

    NSMutableData *data = [NSMutableData data];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];

    [archiver encodeInteger:self.bikingState forKey:BikingStateKey];
    [archiver encodeObject:self.minuteTimer.fireDate forKey:MinuteTimerFireDateKey];
    [archiver encodeObject:self.lastDataUpdateTime forKey:LastDataUpdateTimeKey];
    [archiver encodeObject:self.dataController.stationList forKey:DataControllerKey];
    [archiver encodeObject:self.sourceStation forKey:SourceStationKey];
    [archiver encodeObject:self.finalDestination forKey:FinalDestinationKey];
    [archiver encodeObject:self.currentDestinationStation forKey:CurrentDestinationStationKey];
    [archiver encodeObject:self.idealDestinationStation forKey:IdealDestinationStationKey];
    [archiver encodeObject:self.closestStationsToDestination forKey:ClosestStationsToDestinationKey];
    [archiver encodeObject:self.mapCenterAddress forKey:MapCenterAddressKey];
    [archiver encodeBool:self.bikeCrosshairImage.hidden forKey:BikeCrosshairImageKey];
    [archiver encodeObject:self.regionIdentifierQueue forKey:RegionIdentifierKey];
    [archiver finishEncoding];

    NSString *applicationDocumentsDir =
        [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *path = [applicationDocumentsDir stringByAppendingPathComponent:kStationDataFile];

    NSError *error;
#ifdef DEBUG
    BOOL result = [data writeToFile:path options:NSDataWritingAtomic error:&error];
    DLog(@"Map view archive result = %d, %@", result, error);
#else
    [data writeToFile:path options:NSDataWritingAtomic error:&error];
#endif
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    NSString *logText = [NSString stringWithFormat:@"mapViewController decodeRestorableStateWithCoder called"];
    DLog(@"%@", logText);
    [[NSNotificationCenter defaultCenter]
        postNotificationName:kLogToTextViewNotif
                      object:self
                    userInfo:[NSDictionary dictionaryWithObject:logText forKey:kLogTextKey]];

    [super decodeRestorableStateWithCoder:coder];

    DLog("Bundle version %@ at last state save",
         [coder decodeObjectForKey:UIApplicationStateRestorationBundleVersionKey]);

    // Decode view-related objects:

    self.bikesDocksControl.selectedSegmentIndex = [coder decodeIntegerForKey:BikesDocksControlKey];
    self.bikesDocksControl.hidden = [coder decodeBoolForKey:BikesDocksControlHiddenKey];
    self.startStopButton.title = [coder decodeObjectForKey:StartStopButtonTitleKey];
    self.startStopButton.tintColor = [coder decodeObjectForKey:StartStopButtonTintColorKey];
    self.startStopButton.enabled = [coder decodeBoolForKey:StartStopButtonEnabledKey];
    self.destinationDetailLabel.text = [coder decodeObjectForKey:DestinationDetailLabelKey];
    self.cancelButton.enabled = [coder decodeBoolForKey:CancelButtonKey];
    self.updateLocationButton.enabled = [coder decodeBoolForKey:UpdateLocationButtonEnabledKey];

    // Unpack the state of the view controller:

    NSString *applicationDocumentsDir =
        [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *path = [applicationDocumentsDir stringByAppendingPathComponent:kStationDataFile];

    NSData *data = [NSData dataWithContentsOfFile:path];
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];

    self.bikingState = [unarchiver decodeIntegerForKey:BikingStateKey];
    self.dataController.stationList = [unarchiver decodeObjectForKey:DataControllerKey];
    self.sourceStation = [unarchiver decodeObjectForKey:SourceStationKey];
    self.finalDestination = [unarchiver decodeObjectForKey:FinalDestinationKey];
    self.currentDestinationStation = [unarchiver decodeObjectForKey:CurrentDestinationStationKey];
    self.idealDestinationStation = [unarchiver decodeObjectForKey:IdealDestinationStationKey];
    self.closestStationsToDestination = [unarchiver decodeObjectForKey:ClosestStationsToDestinationKey];
    self.mapCenterAddress = [unarchiver decodeObjectForKey:MapCenterAddressKey];
    self.bikeCrosshairImage.hidden = [unarchiver decodeBoolForKey:BikeCrosshairImageKey];
    self.regionIdentifierQueue = [unarchiver decodeObjectForKey:RegionIdentifierKey];
    self.lastDataUpdateTime = [unarchiver decodeObjectForKey:LastDataUpdateTimeKey];
    // restart timer or fire timer now, depending on what the fire date was
    if ([coder decodeBoolForKey:MinuteTimerValidKey]) {
        self.minuteTimer = [NSTimer scheduledTimerWithTimeInterval:60
                                                            target:self
                                                          selector:@selector(minuteTimerDidFire:)
                                                          userInfo:nil
                                                           repeats:YES];

        // If the timer was supposed to fire at some point while
        // suspended/terminated, fire now
        if ([(NSDate *)[unarchiver decodeObjectForKey:MinuteTimerFireDateKey] timeIntervalSinceNow] < 0) {
            [self.minuteTimer fire];
        }
    }

    // Set map region (has to be done after bikingState is unarchived so we don't
    // unintentionally reverse geocode)
    [self.mapView
        setRegion:MKCoordinateRegionMake(CLLocationCoordinate2DMake([coder decodeDoubleForKey:RegionCenterLatKey],
                                                                    [coder decodeDoubleForKey:RegionCenterLongKey]),
                                         MKCoordinateSpanMake([coder decodeDoubleForKey:RegionSpanLatKey],
                                                              [coder decodeDoubleForKey:RegionSpanLongKey]))
         animated:YES];
    self.needsNewCenter = NO; // Don't center on the user location once it's acquired

    [unarchiver finishDecoding];
}

- (void)applicationFinishedRestoringState
{
    // Called on restored view controllers after other object decoding is
    // complete.
    NSString *logText = [NSString stringWithFormat:@"finished restoring MapViewController"];
    DLog(@"%@", logText);
    [[NSNotificationCenter defaultCenter]
        postNotificationName:kLogToTextViewNotif
                      object:self
                    userInfo:[NSDictionary dictionaryWithObject:logText forKey:kLogTextKey]];

    [self refreshBikeDataWithForce:NO];
}

#pragma mark - Timer Handling

/*
 Callback function when the minute timer fires. Refreshes the bike data if a
 refresh is needed.
 */
- (void)minuteTimerDidFire:(NSTimer *)timer
{
    NSString *logText = [NSString stringWithFormat:@"Timer fired"];
    DLog(@"%@", logText);
    [[NSNotificationCenter defaultCenter]
        postNotificationName:kLogToTextViewNotif
                      object:self
                    userInfo:[NSDictionary dictionaryWithObject:logText forKey:kLogTextKey]];

    [self refreshBikeDataWithForce:NO];
}

#pragma mark - Getting New Bike Data

/*
 If force is YES or if the data hasn't been updated in over 30 seconds, starts
 the station refresh process. Shows HUD when not actively biking.
 */
- (void)refreshBikeDataWithForce:(BOOL)force
{
    if (!force && self.lastDataUpdateTime && (fabs([self.lastDataUpdateTime timeIntervalSinceNow]) < 30.0)) {
        // We are not forcing a refresh, and the last data received exists and is
        // most likely the most recent data available, so we don't need new data
        // yet.
        NSString *logText = [NSString stringWithFormat:@"Unforced data refresh blocked, last data was %f seconds ago",
                                                       fabs([self.lastDataUpdateTime timeIntervalSinceNow])];
        DLog(@"%@", logText);
        [[NSNotificationCenter defaultCenter]
            postNotificationName:kLogToTextViewNotif
                          object:self
                        userInfo:[NSDictionary dictionaryWithObject:logText forKey:kLogTextKey]];
        return;
    }

    // Start HUD if we're not just refreshing during active biking:
    if (self.bikingState != BikingStateActive) {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.labelText = @"Loading stations...";
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:kRefreshDataNotif object:self userInfo:nil];
}

/*
 Clears the current station annotations and replaces them with the new ones
 representing the Stations in stationList.
 */
- (void)plotStationPosition:(NSArray *)stationList
{
    for (id<MKAnnotation> annotation in self.mapView.annotations) {
        if (![annotation isKindOfClass:[MKUserLocation class]])
            [self.mapView removeAnnotation:annotation];
    }

    for (Station *station in stationList) {
        // TODO: if we should show this... (i.e., if it's public: write a method to
        // determine this. gray it out if it's locked?)
        // add to the map
        [self.mapView addAnnotation:station];
    }
}

#pragma mark -
#pragma mark MKMapViewDelegate

/*
 Returns the view associated with the specified annotation object.
 */
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    // TODO: place annotations on top of center bike image, if possible?

    static NSString *identifier = @"Station";

    // use default annotation view for current user location
    if ([annotation isKindOfClass:[MKUserLocation class]])
        return nil;

    // custom annotations for stations and addresses:
    if ([annotation isKindOfClass:[MyLocation class]]) {
        MKAnnotationView *annotationView;
        // Use a generic MKAnnotationView instead of a pin view so we can use our
        // custom image
        annotationView = [self.mapView dequeueReusableAnnotationViewWithIdentifier:identifier];

        if (annotationView == nil) {
            annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
            annotationView.enabled = YES;
            annotationView.canShowCallout = YES;
            annotationView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        } else {
            annotationView.annotation = annotation;
        }

        // Make sure that we're looking at a Station object
        if ([annotation isKindOfClass:[Station class]]) {
            Station *station = (Station *)annotation;

            if (self.sourceStation && (station.stationID == self.sourceStation.stationID)) {
                // Use green icons to denote a starting point, and show the number of
                // bikes in the start station:
                annotationView.image = [UIImage
                    imageNamed:[NSString stringWithFormat:@"station_pin_green_%02ld.png",
                                                          (long)(station.nbBikes <= 99 ? station.nbBikes : 99)]];
            } else if (self.currentDestinationStation &&
                       (station.stationID == self.currentDestinationStation.stationID)) {
                // Use red icons to denote destinations, and show the number of empty
                // docks:
                annotationView.image = [UIImage
                    imageNamed:[NSString
                                   stringWithFormat:@"station_pin_red_%02ld.png",
                                                    (long)(station.nbEmptyDocks <= 99 ? station.nbEmptyDocks : 99)]];
            } else {
                BOOL isClosestStation = NO;
                for (Station *closeStation in self.closestStationsToDestination) {
                    if (station.stationID == closeStation.stationID) {
                        // Use blue icons to denote alternate stations:
                        annotationView.image =
                            [UIImage imageNamed:[NSString stringWithFormat:@"station_pin_blue_%02ld.png",
                                                                           (long)(station.nbEmptyDocks <= 99
                                                                                      ? station.nbEmptyDocks
                                                                                      : 99)]];
                        isClosestStation = YES;
                        break;
                    }
                }
                if (!isClosestStation) {
                    // Use blue icons for generic stations in Inactive state as well, but
                    // switch between showing the number of bikes or docks based on the
                    // toggle control:
                    NSInteger numberToShow =
                        ([self.bikesDocksControl selectedSegmentIndex] == 0) ? station.nbBikes : station.nbEmptyDocks;
                    annotationView.image =
                        [UIImage imageNamed:[NSString stringWithFormat:@"station_pin_blue_%02ld.png",
                                                                       (long)(numberToShow <= 99 ? numberToShow : 99)]];
                }
            }
            // move the centerOffset up so the "point" of the image is pointed at the
            // station location, instead of the image being centered directly over it:
            annotationView.centerOffset = CGPointMake(1, -16);
        } else if ([annotation isKindOfClass:[Address class]]) {
            Address *address = (Address *)annotation;
            // TODO: get rid of annotationIdentifier property and change this if
            // statement to check if the station id is the same as
            // currentDestinationStation.stationID?
            if ([address.annotationIdentifier isEqualToString:kDestinationLocation]) {
                // do not show a separate destination annotation if it's the station the
                // user is actually about to bike to
                if (address.coordinate.latitude == self.currentDestinationStation.coordinate.latitude &&
                    address.coordinate.longitude == self.currentDestinationStation.coordinate.longitude) {
                    return nil;
                }
                annotationView.image = [UIImage imageNamed:@"bikepointer3.png"];
                annotationView.centerOffset = CGPointMake(0, 0);
            }
        }

        return annotationView;
    }

    return nil;
}

/*
 Called if the region displayed by the map view is about to change.
 */
- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated
{
    if (animated == YES) {
        if (self.bikingState == BikingStateInactive) {
            [self.destinationDetailLabel setText:nil];
        }
        [self.startStopButton setEnabled:NO];
    }
}

/*
 Called when the region displayed by the map view just changed.
 */
- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    [self.startStopButton setEnabled:YES];

    [self reverseGeocodeMapCenter];
}

/*
 Reverse geocodes the coordinate at the center of the current map view, sets the
 mapCenterAddress object to this location, and shows the address of the location
 in destinationDetailLabel.
 */
- (void)reverseGeocodeMapCenter
{
    if ((self.bikingState != BikingStateInactive) || self.needsNewCenter) {
        // we only want to do this when the biking state is inactive and once we
        // have a starting center location
        return;
    }

    // re-display center bike pointer image
    [self.bikeCrosshairImage setHidden:NO];

    // geocode new location, then create a new MyLocation object
    CLLocationCoordinate2D centerCoord = self.mapView.centerCoordinate;
    CLLocation *centerLocation =
        [[CLLocation alloc] initWithLatitude:centerCoord.latitude longitude:centerCoord.longitude];
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];

    [self.mapCenterAddress initCoordinateWithLatitude:centerCoord.latitude longitude:centerCoord.longitude];

    [geocoder reverseGeocodeLocation:centerLocation
                   completionHandler:^(NSArray *placemarks, NSError *error) {

                       if (error) {
                           DLog(@"Reverse geocode failed with error: %@", error);
                           // still use the center coordinate for mapCenterAddress
                           return;
                       }

                       [self.mapCenterAddress
                           setNameAndCoordinateWithPlacemark:[placemarks objectAtIndex:0]
                                            distanceFromUser:MKMetersBetweenMapPoints(
                                                                 MKMapPointForCoordinate(centerCoord),
                                                                 MKMapPointForCoordinate(
                                                                     self.dataController.userCoordinate))];

                       [self.destinationDetailLabel setText:[self.mapCenterAddress name]];

                   }];
}

/*
 Tells the delegate that the user tapped one of the annotation view’s accessory
 buttons.
 */
- (void)mapView:(MKMapView *)mapView
                   annotationView:(MKAnnotationView *)view
    calloutAccessoryControlTapped:(UIControl *)control
{
    MyLocation *location = (MyLocation *)view.annotation;

    // Use this location as our final destination, same as selecting it from the
    // Destinations tableView

    // make the user confirm the new destination in an action sheet
    self.selectedLocation = location;
    [self showNavigateActions:self.selectedLocation.name];
}

#pragma mark -
#pragma mark UIActionSheet implementation

- (void)showNavigateActions:(NSString *)title
{
    NSString *cancelButtonTitle = NSLocalizedString(@"Cancel", @"Cancel button title");
    NSString *navigateHereTitle = NSLocalizedString(@"Navigate Here", @"Navigate Here button title");

    // If the user taps a destination to navigate to, present an action sheet to
    // confirm.
    // TODO: Present more options here (to add/delete to/from Favorites, for
    // example).
    self.navSheet = [[UIActionSheet alloc] initWithTitle:title
                                                delegate:self
                                       cancelButtonTitle:cancelButtonTitle
                                  destructiveButtonTitle:nil
                                       otherButtonTitles:navigateHereTitle, nil];
    [self.navSheet showFromTabBar:self.tabBarController.tabBar];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        /*
     Inform the map view that the user chose to navigate to this destination.
     */
        [[NSNotificationCenter defaultCenter]
            postNotificationName:kStartBikingNotif
                          object:self
                        userInfo:[NSDictionary dictionaryWithObject:self.selectedLocation forKey:kBikeDestinationKey]];
    }
    // else cancel was pressed, just go back to the mapView

    self.selectedLocation = nil;
    self.navSheet = nil;
}

#pragma mark -
#pragma mark KVO support

/*
 Notification callback that is received when we have new station data to add to
 the list
 */
- (void)addStations:(NSNotification *)notif
{
    // Transfer the notif data into the method that adds the stations to the
    // stationList array
    [self insertStations:[[notif userInfo] valueForKey:kStationResultsKey]];
}

/*
 There was an error in loading station data.  Handle it appropriately, usually
 just by using the last known data.
 */
- (void)stationError:(NSNotification *)notif
{
    switch (self.bikingState) {
        case BikingStateInactive:
            // Reload map view with the full set of station annotations from the last
            // time we were able to get station data:
            [self plotStationPosition:self.dataController.stationList];
            break;

        case BikingStatePreparingToBike:
            // Set up new route with old data, so user can at least see where they
            // need to go, even if the data is old:
            [self updateActiveBikingViewWithNewDestination:YES];
            break;

        case BikingStateActive:
            // do nothing, the user will just keep biking and we'll get new data the
            // next time we connect
            // Pretend there's new data in case we just entered a geofence and we want
            // to tell a user to dock
            [self willChangeValueForKey:kStationList];
            [self didChangeValueForKey:kStationList];
            break;

        case BikingStateTrackingDidStop:
            // Show route setup screen again, using the last available data:
            [self updateActiveBikingViewWithNewDestination:NO];
            break;
        default:
            break;
    }
    // Hide the HUD
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

/*
 Replaces the current stations in the stationList with the new array, and
 performs manual KVO compliance
 */
- (void)insertStations:(NSArray *)stations
{
    // this will allow us as an observer to notified (see observeValueForKeyPath)
    // so we can update our MapView
    [self willChangeValueForKey:kStationList];

    // Clear out current stations:
    [self.dataController.stationList removeAllObjects];
    // Add new stations:
    [self.dataController addLocationObjectsFromArray:stations toList:self.dataController.stationList];

    [self didChangeValueForKey:kStationList];
}

/*
 Notification callback that tells us we need to prepare a new bike route for a
 given destination.
 */
- (void)prepareNewBikeRoute:(NSNotification *)notif
{
    // Set up a new route:
    [self prepareBikeRouteWithDestination:[[notif userInfo] valueForKey:kBikeDestinationKey] newDestination:YES];
}

/*
 Gets the view ready to present a bike route overview.
 */
- (void)prepareBikeRouteWithDestination:(MyLocation *)dest newDestination:(BOOL)newDest
{
    // Get ready to bike, set the new state and the final destination location
    self.bikingState = (newDest) ? BikingStatePreparingToBike : BikingStateTrackingDidStop;
    self.finalDestination = [dest copy];

    // Start tracking user location
    [[LocationController sharedInstance] startUpdatingCurrentLocation];

    // Disable the bikes/docks toggle:
    [self.bikesDocksControl setHidden:YES];
    // Disable the start/stop button until the data is refreshed:
    [self.startStopButton setEnabled:NO];
    // Get new data:
    [self refreshBikeDataWithForce:YES];
}

/*
 Clears out the current bike route and returns the view to idle state,
 optionally refreshing the station data.
 */
- (void)clearBikeRouteWithRefresh:(BOOL)refresh
{
    if (refresh) {
        // Refresh all station data to get the absolute latest nbBikes and
        // nbEmptyDocks counts.
        [self refreshBikeDataWithForce:YES];
    }

    // re-center map on previous final destination
    [self.mapView setCenterCoordinate:self.finalDestination.coordinate animated:YES];

    // re-display center bike pointer image (done in
    // mapView:regionDidChangeAnimated: once the map stops moving)

    // re-enable the bikes/docks toggle:
    [self.bikesDocksControl setHidden:NO];

    // Change buttons and label:
    [self.destinationDetailLabel setText:[self.finalDestination name]];

    /* iOS7 : with toolbar */
    [self.startStopButton setEnabled:YES];
    [self.startStopButton setTintColor:nil];
    [self.startStopButton setTitle:@"Set Destination"];

    // hide cancel button
    /* iOS7 : with toolbar */
    [self.cancelButton setEnabled:NO];

    // Return to idle/inactive state
    self.bikingState = BikingStateInactive;
    self.finalDestination = nil;
    self.sourceStation = nil;
    self.currentDestinationStation = nil;
    self.idealDestinationStation = nil;
    self.closestStationsToDestination = nil;
}

/*
 Uses the newest station data to present the optimal bike route overview.
 */
- (void)updateActiveBikingViewWithNewDestination:(BOOL)newDest
{
    // Calculate and store the distances from the destination to each station:
    for (Station *station in self.dataController.stationList) {
        station.distanceFromDestination = MKMetersBetweenMapPoints(
            MKMapPointForCoordinate(station.coordinate), MKMapPointForCoordinate(self.finalDestination.coordinate));
    }

    // Figure out the three closest stations to the destination:
    // First sort by distance from destination:
    [self.dataController
        setSortedStationList:[self.dataController sortLocationList:[self.dataController stationList]
                                                          byMethod:LocationDataSortByDistanceFromDestination]];
    // Then grab the top 3:
    self.closestStationsToDestination = [[self.dataController.sortedStationList
        objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 3)]] mutableCopy];

    // Figure out the closest station to the user with at least one bike
    // First sort by distance from user:
    [self.dataController
        setSortedStationList:[self.dataController sortLocationList:[self.dataController stationList]
                                                          byMethod:LocationDataSortByDistanceFromUser]];
    // Then grab the top one with a bike:
    for (Station *station in self.dataController.sortedStationList) {
        if ([station nbBikes] >= 1) {
            if (self.sourceStation && (self.sourceStation.stationID != station.stationID)) {
                // TODO if we previously had a different non-nil sourceStation, should
                // we alert the user that the closest station with a bike has changed?
            }
            self.sourceStation = station;
            break;
        }
    }

    /* Change the map view to show the current user location, and the start, end
     * and backup end stations */

    // Really nice code for this adapted from
    // https://gist.github.com/andrewgleave/915374 via
    // http://stackoverflow.com/a/7141612 :
    // Start with the user coordinate:
    MKMapPoint annotationPoint;
    MKMapRect zoomRect;
    if (self.dataController.userCoordinate.latitude && self.dataController.userCoordinate.longitude) {
        annotationPoint = MKMapPointForCoordinate(self.dataController.userCoordinate);
        zoomRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0.1, 0.1);
    } else {
        zoomRect = MKMapRectNull;
    }
    // Then add the closest station to the user:
    annotationPoint = MKMapPointForCoordinate(self.sourceStation.coordinate);
    MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0.1, 0.1);
    zoomRect = MKMapRectUnion(zoomRect, pointRect);
    // Then add the destination:
    annotationPoint = MKMapPointForCoordinate(self.finalDestination.coordinate);
    pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0.1, 0.1);
    zoomRect = MKMapRectUnion(zoomRect, pointRect);
    // Then add the closest stations to the destination:
    for (Station *station in self.closestStationsToDestination) {
        annotationPoint = MKMapPointForCoordinate(station.coordinate);
        pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0.1, 0.1);
        zoomRect = MKMapRectUnion(zoomRect, pointRect);
    }
    // increased edge padding so all relevant markers are visible
    [self.mapView setVisibleMapRect:zoomRect edgePadding:UIEdgeInsetsMake(104, 15, 104, 15) animated:YES];

    /* Determine annotation identifiers */

    // Change the annotation identifiers for the Station/MyLocation objects we
    // want to view as annotations on the map:
    // i.e. change the pin color (other attributes?) for start, end and backup end
    // stations
    self.sourceStation.annotationIdentifier = kSourceStation;
    self.finalDestination.annotationIdentifier = kDestinationLocation;
    // Label the closest destination to the finalDestination as the
    // idealDestinationStation, so if it's full we can check to see if a dock
    // opens up there later.
    self.idealDestinationStation = [self.closestStationsToDestination objectAtIndex:0];
    // Destination stations: label the closest one with at least one empty dock as
    // the current destination and the rest as "alternates."
    BOOL destinationFound = NO;
    for (Station *station in self.closestStationsToDestination) {
        if ((station.nbEmptyDocks > 0) && !destinationFound) {
            station.annotationIdentifier = kDestinationStation;
            self.currentDestinationStation = station;
            destinationFound = YES;
        } else {
            station.annotationIdentifier = kAlternateStation;
        }
    }

    // TODO: If there is no station in closestStationsToDestination with >0
    // nbEmptyDocks, do we warn the user or just keep going down the list?

    /* JUST WALK ALERTS:
   If the closest station to the destination is also the closest one to the
   user, or if the ideal destination station is full but the closest one
   to the destination that isn't full is also the closest one to the user,
   perhaps it's best to just tell the user to walk.
   (Do not use sourceStation in case there is one closer with no bikes... use
   the top of the sorted station list instead)
   ALSO: Show this alert as well if the destination station is different but
   (dist(user to sourceStation) + dist(destinationStation to finalDestination)
   >= dist(user to finalDestination)),
   otherwise the user is walking an equal or longer distance (to the closest
   station with a bike, plus from the station nearest to
   their destination with a dock) as well as biking, which is foolish
   */
    if ((self.idealDestinationStation.stationID ==
         [[self.dataController.sortedStationList objectAtIndex:0] stationID]) ||
        ((self.idealDestinationStation.stationID != self.currentDestinationStation.stationID) &&
         (self.currentDestinationStation.stationID ==
          [[self.dataController.sortedStationList objectAtIndex:0] stationID])) ||
        ((self.sourceStation.distanceFromUser + self.currentDestinationStation.distanceFromDestination) >=
         self.finalDestination.distanceFromUser)) {
        // Only show an alertView popup if newDest == YES (so we don't show a Just
        // Walk alert if the app stops tracking, either manually or automatically,
        // when the user gets to their destination)
        if (newDest) {
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Walk to your destination!"
                                                         message:nil
                                                        delegate:nil
                                               cancelButtonTitle:@"OK"
                                               otherButtonTitles:nil];
            if (self.idealDestinationStation.stationID ==
                [[self.dataController.sortedStationList objectAtIndex:0] stationID]) {
                [av setMessage:@"The destination station is also the closest one to "
                               @"your current location. Perhaps it's best to just "
                               @"walk."];
            } else if ((self.idealDestinationStation.stationID != self.currentDestinationStation.stationID) &&
                       (self.currentDestinationStation.stationID ==
                        [[self.dataController.sortedStationList objectAtIndex:0] stationID])) {
                [av setMessage:@"The closest station to your destination with an empty "
                               @"dock is also the closest one to your current "
                               @"location. Perhaps it's best to just walk."];
            } else {
                [av setMessage:@"The best stations to start and finish your route are "
                               @"both out of the way. Perhaps it's best to just "
                               @"walk."];
            }
            [av show];

            // return to idle
            [self clearBikeRouteWithRefresh:NO];
            [self plotStationPosition:self.dataController.stationList];

            return;
        } else {
            // If our final destination isn't the station itself, change label to show
            // where to walk:
            if (self.finalDestination.coordinate.latitude != self.currentDestinationStation.coordinate.latitude &&
                self.finalDestination.coordinate.longitude != self.currentDestinationStation.coordinate.longitude) {
                [self.destinationDetailLabel
                    setText:[NSString stringWithFormat:@"Walk to %@", self.finalDestination.name]];
            } else // We've reached our final destination (which is either the
                   // idealDestinationStation or a non-station Address)
            {
                [self.destinationDetailLabel setText:@"You have arrived!"];
            }
        }
    } else {
        // Change label to show where to pick up and drop off your bike:
        [self.destinationDetailLabel
            setText:[NSString stringWithFormat:@"Pick up bike at %@ - %ld bike%@ "
                                               @"available\nBike to %@ - %ld empty dock%@",
                                               self.sourceStation.name, (long)self.sourceStation.nbBikes,
                                               (self.sourceStation.nbBikes > 1) ? @"s" : @"",
                                               self.currentDestinationStation.name,
                                               (long)self.currentDestinationStation.nbEmptyDocks,
                                               (self.currentDestinationStation.nbEmptyDocks > 1) ? @"s" : @""]];
    }

    // Hide the annotations for all other stations.
    for (id<MKAnnotation> annotation in self.mapView.annotations) {
        if (![annotation isKindOfClass:[MKUserLocation class]])
            [self.mapView removeAnnotation:annotation];
    }
    // Hide center bike pointer image
    [self.bikeCrosshairImage setHidden:YES];

    // Change buttons:
    /* iOS7 : with toolbar */
    [self.startStopButton setTintColor:[UIColor greenColor]];
    [self.startStopButton setTitle:@"Start Station Tracking"];
    [self.startStopButton setEnabled:YES];
    [self.cancelButton setEnabled:YES];

    // Add new annotations.
    // TODO: update distanceFromUser, etc (other properties) in local MyLocation
    // objects (finalDestination, etc) here? instead of in startStationTracking
    // for example?
    [self.mapView addAnnotation:self.sourceStation];

    if (self.finalDestination.coordinate.latitude != self.currentDestinationStation.coordinate.latitude &&
        self.finalDestination.coordinate.longitude != self.currentDestinationStation.coordinate.longitude)
        [self.mapView addAnnotation:self.finalDestination];

    for (Station *station in self.closestStationsToDestination) {
        [self.mapView addAnnotation:station];
    }
}

/*
 Begins the process of tracking the destination stations. Creates geofences,
 starts the minute refresh timer, starts location tracking and changes the
 bikingState.
 */
- (void)startStationTracking
{
    // Create regions to monitor via geofencing app wakeups:
    // Concentric circles, getting closer to the final destination:

    [self.finalDestination
        setDistanceFromUser:MKMetersBetweenMapPoints(MKMapPointForCoordinate(self.dataController.userCoordinate),
                                                     MKMapPointForCoordinate(self.finalDestination.coordinate))];

    [[LocationController sharedInstance] registerRegionWithCoordinate:self.finalDestination.coordinate
                                                               radius:(self.finalDestination.distanceFromUser * 0.67f)
                                                           identifier:kRegionMonitorTwoThirdsToGo
                                                             accuracy:kCLLocationAccuracyNearestTenMeters];
    [[LocationController sharedInstance] registerRegionWithCoordinate:self.finalDestination.coordinate
                                                               radius:(self.finalDestination.distanceFromUser * 0.33f)
                                                           identifier:kRegionMonitorOneThirdToGo
                                                             accuracy:kCLLocationAccuracyNearestTenMeters];

    // One more region for each of the three closest stations to the final
    // destination:
    [[LocationController sharedInstance]
        registerRegionWithCoordinate:((Station *)[self.closestStationsToDestination objectAtIndex:0]).coordinate
                              radius:10
                          identifier:kRegionMonitorStation1
                            accuracy:kCLLocationAccuracyBest];
    [[LocationController sharedInstance]
        registerRegionWithCoordinate:((Station *)[self.closestStationsToDestination objectAtIndex:1]).coordinate
                              radius:10
                          identifier:kRegionMonitorStation2
                            accuracy:kCLLocationAccuracyBest];
    [[LocationController sharedInstance]
        registerRegionWithCoordinate:((Station *)[self.closestStationsToDestination objectAtIndex:2]).coordinate
                              radius:10
                          identifier:kRegionMonitorStation3
                            accuracy:kCLLocationAccuracyBest];

    // TODO: Start the rental timer, if we have one

    // Start minute timer:

    NSString *logText = [NSString stringWithFormat:@"Starting minute timer"];
    DLog(@"%@", logText);
    [[NSNotificationCenter defaultCenter]
        postNotificationName:kLogToTextViewNotif
                      object:self
                    userInfo:[NSDictionary dictionaryWithObject:logText forKey:kLogTextKey]];

    self.minuteTimer = [NSTimer scheduledTimerWithTimeInterval:60
                                                        target:self
                                                      selector:@selector(minuteTimerDidFire:)
                                                      userInfo:nil
                                                       repeats:YES];

    // Change the state to active:
    self.bikingState = BikingStateActive;

    // Start tracking user location; since the station tracking is now active, it
    // will continue updating in the background even after it gets the first
    // location
    [[LocationController sharedInstance] startUpdatingCurrentLocation];
}

/*
 Quits out of station tracking. Stops the timer and turns off geofences.
 */
- (void)stopStationTracking
{
    // Stop timer:
    [self.minuteTimer invalidate];
    self.minuteTimer = nil;

    // Turn off geofencing:
    [[LocationController sharedInstance] stopAllRegionMonitoring];
}

/*
 Registers the view controller for KVO
 */
- (void)registerForKVO
{
    for (NSString *keyPath in [self observableKeypaths]) {
        [self addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionNew context:NULL];
    }
}

/*
 Unregisters the view controller from KVO
 */
- (void)unregisterFromKVO
{
    for (NSString *keyPath in [self observableKeypaths]) {
        [self removeObserver:self forKeyPath:keyPath];
    }
}

/*
 Returns the list of keypaths for the view controller to observe
 */
- (NSArray *)observableKeypaths
{
    return [NSArray arrayWithObjects:kAddStationsNotif, kStationList, nil];
}

/*
 Listen for changes to the station list, and act upon them appropriately,
 alerting the user as needed when stations fill up or open up or when they are
 at their destination.
 */
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    NSString *logText = [NSString stringWithFormat:@"NEW STATION DATA: bikingState: %ld", self.bikingState];
    DLog(@"%@", logText);
    [[NSNotificationCenter defaultCenter]
        postNotificationName:kLogToTextViewNotif
                      object:self
                    userInfo:[NSDictionary dictionaryWithObject:logText forKey:kLogTextKey]];
    // Set the last time we got a fresh set of station data
    self.lastDataUpdateTime = [NSDate date];

    switch (self.bikingState) {
        case BikingStateInactive:
            // Reload map view
            [self plotStationPosition:self.dataController.stationList];
            break;
        case BikingStatePreparingToBike:
            // Do not reload the map view yet, just go to the callback to finish the
            // setup to start biking:
            [self updateActiveBikingViewWithNewDestination:YES];
            break;
        case BikingStateActive: {
            BOOL notifSent = NO;
            BOOL endTracking = NO;
            NSString *newlyFullStationName = nil;
            NSMutableArray *regionIdentifiersToCheck = [self.regionIdentifierQueue copy];

            // Loop through all the stations in stationList and determine if we need
            // to send a notification based on its previous and current nbEmptyDocks
            // count, and if a geofence told us that we are actually at that location
            for (Station *station in self.dataController.stationList) {
                if (station.stationID == self.sourceStation.stationID) {
                    // Reassign sourceStation pointer to new Station object that
                    // represents the station we started at
                    self.sourceStation = station;
                }

                // Check to see if this station is one that we determined to be closest
                // to the destination:
                NSUInteger stationIndex = [self.closestStationsToDestination
                    indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                        Station *stationObj = (Station *)obj;
                        return (stationObj.stationID == station.stationID);
                    }];
                // If so, reassign the pointer in the array:
                if (stationIndex != NSNotFound) {
                    // switch out old array objects with the new data
                    [self.closestStationsToDestination replaceObjectAtIndex:stationIndex withObject:station];
                }

                // reassign class pointers to new data:
                if (station.stationID == self.idealDestinationStation.stationID) {
                    // check to see if we're at the ideal station with a dock available:
                    for (NSString *identifier in regionIdentifiersToCheck) {
                        if ([identifier isEqualToString:kRegionMonitorStation1] && (station.nbEmptyDocks > 0)) {
                            // if there's a dock available now, it doesn't matter if we
                            // thought we were going somewhere else before, just tell the user
                            // to stop here:
                            self.currentDestinationStation.annotationIdentifier = kAlternateStation;
                            self.currentDestinationStation = station;
                            self.currentDestinationStation.annotationIdentifier = kDestinationStation;

                            UILocalNotification *stopAtIdealStationNotification = [[UILocalNotification alloc] init];
                            [stopAtIdealStationNotification
                                setAlertBody:[NSString stringWithFormat:@"Dock here! You have reached the "
                                                                        @"station closest to your "
                                                                        @"destination, %@. Station "
                                                                        @"tracking will end.",
                                                                        self.idealDestinationStation.name]];
                            stopAtIdealStationNotification.soundName = @"bicycle_bell.wav";
                            [stopAtIdealStationNotification setFireDate:[NSDate date]];
                            [[UIApplication sharedApplication]
                                scheduleLocalNotification:stopAtIdealStationNotification];

                            // Set flags
                            notifSent = YES;
                            endTracking = YES;
                            break;
                        }
                    }
                    // otherwise, if we're heading to a non-ideal station, check to see if
                    // a dock at the ideal station has opened up.
                    if (!endTracking && (self.currentDestinationStation.stationID != station.stationID) &&
                        (station.nbEmptyDocks > 0) && (self.idealDestinationStation.nbEmptyDocks == 0)) {
                        // Alert the user to bike to the idealDestinationStation instead!
                        self.currentDestinationStation.annotationIdentifier = kAlternateStation;
                        self.currentDestinationStation = station;
                        self.currentDestinationStation.annotationIdentifier = kDestinationStation;

                        UILocalNotification *bikeToIdealStationNotification = [[UILocalNotification alloc] init];
                        [bikeToIdealStationNotification
                            setAlertBody:[NSString stringWithFormat:@"A dock has opened up at %@! Bike there instead!",
                                                                    self.currentDestinationStation.name]];
                        bikeToIdealStationNotification.soundName = @"bicycle_bell.wav";
                        [bikeToIdealStationNotification setFireDate:[NSDate date]];
                        [[UIApplication sharedApplication] scheduleLocalNotification:bikeToIdealStationNotification];

                        notifSent = YES;
                    }
                    // update this pointer... will always continue to be the same
                    // stationID
                    self.idealDestinationStation = station;
                }
                if (station.stationID == self.currentDestinationStation.stationID) // TODO: && !notifSent?? test this
                {
                    // the ideal non-current station did not empty out... but check if the
                    // currentDestinationStation filled up:
                    if (self.currentDestinationStation.nbEmptyDocks > 0 && station.nbEmptyDocks == 0) {
                        // it filled up... alert the user to go to the next non-empty
                        // station
                        for (Station *newStation in self.closestStationsToDestination) {
                            if (newStation.nbEmptyDocks > 0) {
                                // TODO: is this alternate station being assigned incorrectly or
                                // perhaps just doubly executed due to the "bike to
                                // idealDestinationStation instead!" code?
                                self.currentDestinationStation.annotationIdentifier = kAlternateStation;
                                self.currentDestinationStation = newStation;
                                self.currentDestinationStation.annotationIdentifier = kDestinationStation;

                                newlyFullStationName = station.name;
                                break;
                            }
                        }
                    } else {
                        // Just reassign the pointer
                        self.currentDestinationStation = station;
                    }
                }

                // else, the user should just keep biking to the
                // currentDestinationStation...
            }
            //...unless they're already there
            for (NSString *identifier in regionIdentifiersToCheck) {
                if (!notifSent && (((self.currentDestinationStation.stationID ==
                                     [[self.closestStationsToDestination objectAtIndex:1] stationID]) &&
                                    [identifier isEqualToString:kRegionMonitorStation2]) ||
                                   ((self.currentDestinationStation.stationID ==
                                     [[self.closestStationsToDestination objectAtIndex:2] stationID]) &&
                                    [identifier isEqualToString:kRegionMonitorStation3]))) {
                    // We've reached an alternate station. if we've reached this point, no
                    // docks have opened up at the ideal station, so just dock here and
                    // walk the rest of the way
                    UILocalNotification *stopAtCurrentStationNotification = [[UILocalNotification alloc] init];
                    [stopAtCurrentStationNotification
                        setAlertBody:[NSString stringWithFormat:@"Dock here! You have reached "
                                                                @"the station closest to your "
                                                                @"destination with an empty "
                                                                @"dock, %@. Station tracking "
                                                                @"will end.",
                                                                self.currentDestinationStation.name]];
                    stopAtCurrentStationNotification.soundName = @"bicycle_bell.wav";
                    [stopAtCurrentStationNotification setFireDate:[NSDate date]];
                    [[UIApplication sharedApplication] scheduleLocalNotification:stopAtCurrentStationNotification];

                    // Set flag
                    endTracking = YES;
                    break;
                }
            }
            // If we haven't told the user to dock yet, and the
            // currentDestinationStation had just filled up, alert the user
            if (!endTracking && newlyFullStationName != nil) {
                UILocalNotification *bikeToNextBestStationNotification = [[UILocalNotification alloc] init];
                [bikeToNextBestStationNotification
                    setAlertBody:[NSString stringWithFormat:@"The station at %@ has filled up. Bike to %@ instead.",
                                                            newlyFullStationName, self.currentDestinationStation.name]];
                bikeToNextBestStationNotification.soundName = @"bicycle_bell.wav";
                [bikeToNextBestStationNotification setFireDate:[NSDate date]];
                [[UIApplication sharedApplication] scheduleLocalNotification:bikeToNextBestStationNotification];
            }

            // Update the view if we're still biking
            if (!endTracking) {
                for (id<MKAnnotation> annotation in self.mapView.annotations) {
                    if (![annotation isKindOfClass:[MKUserLocation class]])
                        [self.mapView removeAnnotation:annotation];
                }

                // Change buttons and label:
                [self.destinationDetailLabel
                    setText:[NSString stringWithFormat:@"Pick up bike at %@ - %ld bike%@ available\nBike "
                                                       @"to %@ - %ld empty dock%@",
                                                       self.sourceStation.name, (long)self.sourceStation.nbBikes,
                                                       (self.sourceStation.nbBikes > 1) ? @"s" : @"",
                                                       self.currentDestinationStation.name,
                                                       (long)self.currentDestinationStation.nbEmptyDocks,
                                                       (self.currentDestinationStation.nbEmptyDocks > 1) ? @"s" : @""]];

                // Add new annotations.
                // TODO: pull this into its own method for code reuse
                // if final destination and current destination station are the same
                // object, only show the station object
                [self.mapView addAnnotation:self.sourceStation];
                if (self.finalDestination.coordinate.latitude != self.currentDestinationStation.coordinate.latitude &&
                    self.finalDestination.coordinate.longitude != self.currentDestinationStation.coordinate.longitude)
                    [self.mapView addAnnotation:self.finalDestination];
                for (Station *station in self.closestStationsToDestination) {
                    [self.mapView addAnnotation:station];
                }
            } else {
                // Stop tracking stations:
                [self stopStationTracking];
                // Show the route setup screen again:
                [self prepareBikeRouteWithDestination:self.finalDestination newDestination:NO];
            }

            // clear out the region identifiers that we just checked from the queue so
            // we don't alert at the wrong time
            [self.regionIdentifierQueue removeObjectsInArray:regionIdentifiersToCheck];

        } break;
        case BikingStateTrackingDidStop:
            // Allow the user to restart the same route, but don't give them a "Just
            // walk" alert if they're close to their destination:
            [self updateActiveBikingViewWithNewDestination:NO];
            break;
        default:
            break;
    }

    // Hide the HUD
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

- (IBAction)refreshTapped:(id)sender
{
    // Force a refresh of bike data now
    [self refreshBikeDataWithForce:YES];
}

/*
 The user just tapped the cancel button, handle it by resetting the view to idle
 */
- (IBAction)cancelTapped:(id)sender
{
    // log it for debugging
    NSString *logText = [NSString stringWithFormat:@"cancelTapped"];
    DLog(@"%@", logText);
    [[NSNotificationCenter defaultCenter]
        postNotificationName:kLogToTextViewNotif
                      object:self
                    userInfo:[NSDictionary dictionaryWithObject:logText forKey:kLogTextKey]];

    // reset to inactive
    [self clearBikeRouteWithRefresh:YES];
}

/*
 The user just tapped the start/stop button, handle it based on the current
 bikingState
 */
- (IBAction)startStopTapped:(UIButton *)sender
{
    switch (self.bikingState) {
        case BikingStateInactive:
            // set the final destination to equal the placemark at the center of the
            // crosshairs and prepare a new route to the location
            [self prepareBikeRouteWithDestination:self.mapCenterAddress newDestination:YES];
            break;

        case BikingStatePreparingToBike:
        case BikingStateTrackingDidStop:
            // Change buttons:
            /* iOS7 : with toolbar */
            [self.startStopButton setTintColor:[UIColor redColor]];
            [self.startStopButton setTitle:@"Stop Station Tracking"];
            [self.cancelButton setEnabled:NO];

            // Start station tracking:
            [self startStationTracking];

            break;

        case BikingStateActive:
            // stop station tracking and return to the route setup screen
            [self stopStationTracking];
            // setup route screen:
            [self prepareBikeRouteWithDestination:self.finalDestination newDestination:NO];
            break;

        default:
            break;
    }
}

- (IBAction)bikesDocksToggled:(id)sender
{
    // replot the station annotations with either the number of bikes or empty
    // docks at each
    [self plotStationPosition:self.dataController.stationList];
}

// Location button was just tapped. Pan to the current user location on the map
// and update the CLLocationManager location
- (IBAction)updateLocationTapped:(id)sender
{
    [[LocationController sharedInstance] startUpdatingCurrentLocation];

    if ([[self.mapView userLocation] location]) {
        [self.mapView setCenterCoordinate:self.mapView.userLocation.location.coordinate animated:YES];
    }

    // TODO: map sometimes doesn't update? specifically if biking state is active
    // and zoomed in on destination bikes, and/or if wifi is off
}

/*
 Notification callback when the CLLocationManager has updated the current user
 location.
 */
- (void)updateLocation:(NSNotification *)notif
{
    // pan to new user location if we said we needed to when the view loaded
    if (self.needsNewCenter) {
        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(
            [[[LocationController sharedInstance] location] coordinate], 2 * METERS_PER_MILE, 2 * METERS_PER_MILE);

        [self.mapView setRegion:region animated:YES];

        // get new station data for this location if auto city detection is on
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if ([defaults boolForKey:kAutoCityPreference] == YES) {
            [self refreshBikeDataWithForce:YES];
        }

        // clear flag
        self.needsNewCenter = NO;
    }

    if (self.bikingState != BikingStateActive) {
        [[LocationController sharedInstance] stopUpdatingCurrentLocation];
    }
    // TODO: If we're entering a geofence, and we don't just want to force an
    // update at those times, perhaps turn the new stationError: code into a
    // usePresentData: function and call that instead to figure out docking
    // notifications?
}

/*
 Notification callback when the CLLocationManager has determined that we have
 entered a geofence.
 */
- (void)regionEntered:(NSNotification *)notif
{
    // Mark the region that we just entered:
    if (!self.regionIdentifierQueue) {
        // allocate for the queue if it is nil
        self.regionIdentifierQueue = [[NSMutableArray alloc] init];
    }
    [self.regionIdentifierQueue addObject:[(CLRegion *)[[notif userInfo] valueForKey:kNewRegionKey] identifier]];

    // We hit a geofence. Get a bike data update
    [self refreshBikeDataWithForce:YES];
}

/*
 Notification callback when the CLLocationManager has determined that we have
 exited a geofence.
 */
- (void)regionExited:(NSNotification *)notif
{
    // Get another bike data update
    [self refreshBikeDataWithForce:NO];
}

#pragma mark - UIBarPositioningDelegate

// iOS7 compatibility: attach toolbar to the status bar instead of overlapping
// the two
- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar
{
    return UIBarPositionTopAttached;
}

@end
