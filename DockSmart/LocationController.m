//
//  LocationController.m
//  DockSmart
//
//  Singleton CLLocationManagerDelegate class.
//
//  Created by John Penning on 9/14/13.
//  Copyright (c) 2013 John Penning. All rights reserved.
//  (With help from Jinru Liu:
//  http://jinru.wordpress.com/2010/08/15/singletons-in-objective-c-an-example-of-cllocationmanager/ )
//

#import "LocationController.h"

// Notification key for location updates
NSString *const kLocationUpdateNotif = @"LocationUpdateNotif";
// userInfo key for new location data
NSString *const kNewLocationKey = @"NewLocationKey";
// Notification key for geofence entry
NSString *const kRegionEntryNotif = @"RegionEntryNotif";
// Notification key for geofence exit
NSString *const kRegionExitNotif = @"RegionExitNotif";
// userInfo key for geofence data
NSString *const kNewRegionKey = @"NewRegionKey";


@interface LocationController ()

// CLLocationManager object
@property(nonatomic, strong) CLLocationManager *locationManager;

@end

@implementation LocationController

- (id)init
{
    self = [super init];
    if (self != nil) {
        if (!_locationManager) {
            _locationManager = [[CLLocationManager alloc] init];
        }
        _locationManager.delegate = self;
        _locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
        _locationManager.pausesLocationUpdatesAutomatically = NO;
        _locationManager.activityType = CLActivityTypeFitness;
        _locationManager.distanceFilter = 5;
    }
    return self;
}

#pragma mark - Singleton implementation in ARC

+ (LocationController *)sharedInstance
{
    static LocationController *sharedLocationControllerInstance = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        sharedLocationControllerInstance = [[self alloc] init];
    });
    return sharedLocationControllerInstance;
}

#pragma mark - Location interface

// Starts location updates
- (void)startUpdatingCurrentLocation
{
    CLAuthorizationStatus status = [self requestAlwaysAuthorization];
    // if location services are restricted do nothing
    if (status == kCLAuthorizationStatusDenied || status == kCLAuthorizationStatusRestricted ||
        [CLLocationManager locationServicesEnabled] == NO) {
        return;
    }

    DLog(@"startUpdatingCurrentLocation");
    [_locationManager startUpdatingLocation];
}

// Stops location updates
- (void)stopUpdatingCurrentLocation
{
    DLog(@"stopUpdatingCurrentLocation");
    [_locationManager stopUpdatingLocation];
}

- (void)startMonitoringSignificantLocationChanges
{
    [_locationManager startMonitoringSignificantLocationChanges];
}

- (void)stopMonitoringSignificantLocationChanges
{
    [_locationManager stopMonitoringSignificantLocationChanges];
}

#pragma mark - Location Authorization

- (CLAuthorizationStatus)requestWhenInUseAuthorization
{
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    if (status == kCLAuthorizationStatusNotDetermined) {
        [_locationManager requestWhenInUseAuthorization];
    }
    return status;
}

- (CLAuthorizationStatus)requestAlwaysAuthorization
{
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    if (status == kCLAuthorizationStatusNotDetermined ||
        (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"11.0") && status == kCLAuthorizationStatusAuthorizedWhenInUse)) {
        [_locationManager requestAlwaysAuthorization];
    }
    return status;
}

#pragma mark - CLLocationManagerDelegate

// delegate method that informs us if the location services authorization for this app has changed
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    // Make current location button inactive on mapview if location services are disabled
    DockSmartMapViewController *controller =
        [[[[UIApplication sharedApplication] delegate] window] rootViewController].childViewControllers[0];
    if (status == kCLAuthorizationStatusDenied || status == kCLAuthorizationStatusRestricted ||
        [CLLocationManager locationServicesEnabled] == NO) {
        [controller.updateLocationButton setEnabled:NO];
    } else {
        [controller.updateLocationButton setEnabled:YES];
        [self startUpdatingCurrentLocation];
    }
}

// delegate method that informs us if the CLLocationManager updated the user location
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    // If it's a relatively recent event, turn off updates to save power
    CLLocation *location = [locations lastObject];
    NSDate *eventDate = location.timestamp;
    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];

    DLog(@"didUpdateLocations: location: %@", location);

    if (fabs(howRecent) < 15.0) {
        // If the event is recent, do something with it.

        // store it in the singleton's location property
        self.location = location;

        // post notification
        [[NSNotificationCenter defaultCenter]
            postNotificationName:kLocationUpdateNotif
                          object:self
                        userInfo:[NSDictionary dictionaryWithObject:location forKey:kNewLocationKey]];
    }
}

// delegate method that informs us that the location update failed
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    DLog(@"%@", error);
    DLog(@"locationManagerDidFailWithError: %@", [error localizedDescription]);
}

// delegate method that informs us that geofence monitoring failed for a particular region
- (void)locationManager:(CLLocationManager *)manager
    monitoringDidFailForRegion:(CLRegion *)region
                     withError:(NSError *)error
{
    DLog(@"monitoringDidFailForRegion: %@ withError: %@", region.identifier,
         [error localizedDescription]);
}

// delegate method that informs us that we entered a geofence
- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    DLog(@"didEnterRegion: %@", region.identifier);

    [[NSNotificationCenter defaultCenter]
        postNotificationName:kRegionEntryNotif
                      object:self
                    userInfo:[NSDictionary dictionaryWithObject:region forKey:kNewRegionKey]];
}

// delegate method that informs us that we exited a geofence
- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    DLog(@"didExitRegion: %@", region.identifier);

    [[NSNotificationCenter defaultCenter]
        postNotificationName:kRegionExitNotif
                      object:self
                    userInfo:[NSDictionary dictionaryWithObject:region forKey:kNewRegionKey]];
}

#pragma mark - Region monitoring support

// Register a geofence
- (BOOL)registerRegionWithCoordinate:(CLLocationCoordinate2D)coordinate
                              radius:(CLLocationDistance)radius
                          identifier:(NSString *)identifier
                            accuracy:(CLLocationAccuracy)accuracy
{
    // Check the authorization status
    if (([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorizedAlways) &&
        ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusNotDetermined))
        return NO;

    // Clear out any old regions to prevent buildup.
    if ([self.locationManager.monitoredRegions count] > 5) {
        for (id obj in self.locationManager.monitoredRegions) {
            DLog(@"Removing geofence %@", [obj identifier]);
            [self.locationManager stopMonitoringForRegion:obj];
        }
    }

    // If the overlay's radius is too large, registration fails automatically,
    // so clamp the radius to the max value.
    if (radius > self.locationManager.maximumRegionMonitoringDistance) {
        radius = self.locationManager.maximumRegionMonitoringDistance;
    }

    // Create the region to be monitored.
    CLCircularRegion *circularRegion =
        [[CLCircularRegion alloc] initWithCenter:coordinate radius:radius identifier:identifier];

    [self.locationManager startMonitoringForRegion:circularRegion];
    return YES;
}

// Turn off all geofences
- (void)stopAllRegionMonitoring
{
    // Clear out all old regions when we are done monitoring them.
    for (id obj in self.locationManager.monitoredRegions)
        [self.locationManager stopMonitoringForRegion:obj];
}

@end
