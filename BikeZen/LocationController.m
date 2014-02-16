//
//  LocationController.m
//  DockSmart
//
//  Created by John Penning on 9/14/13.
//  Copyright (c) 2013 John Penning. All rights reserved.
//  (With help from Jinru Liu: http://jinru.wordpress.com/2010/08/15/singletons-in-objective-c-an-example-of-cllocationmanager/ )
//

#import "LocationController.h"

//static LocationController* sharedCLDelegate = nil;

NSString * const kLocationUpdateNotif = @"LocationUpdateNotif";
NSString * const kNewLocationKey = @"NewLocationKey";
NSString * const kRegionEntryNotif = @"RegionEntryNotif";
NSString * const kRegionExitNotif = @"RegionExitNotif";
NSString * const kNewRegionKey = @"NewRegionKey";

@implementation LocationController

- (id)init
{
    self = [super init];
    if (self != nil) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
        self.locationManager.pausesLocationUpdatesAutomatically = NO;
        self.locationManager.activityType = CLActivityTypeFitness;

    }
    return self;
}

#pragma mark - CLLocationManagerDelegate

- (void)startUpdatingCurrentLocation
{
    // if location services are restricted do nothing
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied ||
        [CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted ||
        [CLLocationManager locationServicesEnabled] == NO)
    {
        return;
    }
    
    NSString* logText = [NSString stringWithFormat:@"startUpdatingCurrentLocation"];
    DLog(@"%@",logText);
    [[NSNotificationCenter defaultCenter] postNotificationName:kLogToTextViewNotif
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:logText
                                                                                           forKey:kLogTextKey]];
    
    
    // if locationManager does not currently exist, create it
    if (!_locationManager)
    {
        _locationManager = [[CLLocationManager alloc] init];
    }
    
    [_locationManager setDelegate:self];
    
    _locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    _locationManager.distanceFilter = 5; //10.0f; // we don't need to be any more accurate than 10m
    _locationManager.activityType = CLActivityTypeFitness;
    
    [_locationManager startUpdatingLocation];
}

- (void)stopUpdatingCurrentLocation
{
    NSString* logText = [NSString stringWithFormat:@"stopUpdatingCurrentLocation"];
    DLog(@"%@",logText);
    [[NSNotificationCenter defaultCenter] postNotificationName:kLogToTextViewNotif
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:logText
                                                                                           forKey:kLogTextKey]];
    
    [_locationManager stopUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    //Make current location button inactive on mapview if location services are disabled
    DockSmartMapViewController *controller = [[[[UIApplication sharedApplication] delegate] window] rootViewController].childViewControllers[0];
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied ||
        [CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted ||
        [CLLocationManager locationServicesEnabled] == NO)
    {
        [controller.updateLocationButton setEnabled:NO];
    }
    else
    {
        [controller.updateLocationButton setEnabled:YES];
    }
    
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    // If it's a relatively recent event, turn off updates to save power
    CLLocation* location = [locations lastObject];
    NSDate* eventDate = location.timestamp;
    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
    
    NSString* logText = [NSString stringWithFormat:@"didUpdateLocations: location: %@", location];
    DLog(@"%@",logText);
    [[NSNotificationCenter defaultCenter] postNotificationName:kLogToTextViewNotif
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:logText
                                                                                           forKey:kLogTextKey]];
    
    if (abs(howRecent) < 15.0)
    {
        // If the event is recent, do something with it.
        
        //store it in the singleton's location property
        self.location = location;
        
        //post notification
        [[NSNotificationCenter defaultCenter] postNotificationName:kLocationUpdateNotif
                                                            object:self
                                                          userInfo:[NSDictionary dictionaryWithObject:location forKey:kNewLocationKey]];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    DLog(@"%@", error);
    
    NSString* logText = [NSString stringWithFormat:@"locationManagerDidFailWithError: %@", [error localizedDescription]];
    DLog(@"%@",logText);
    [[NSNotificationCenter defaultCenter] postNotificationName:kLogToTextViewNotif
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:logText
                                                                                           forKey:kLogTextKey]];
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    NSString* logText = [NSString stringWithFormat:@"monitoringDidFailForRegion: %@ withError: %@", region.identifier, [error localizedDescription]];
    DLog(@"%@",logText);
    [[NSNotificationCenter defaultCenter] postNotificationName:kLogToTextViewNotif
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:logText
                                                                                           forKey:kLogTextKey]];

}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    NSString* logText = [NSString stringWithFormat:@"didEnterRegion: %@", region.identifier];
    DLog(@"%@",logText);
    [[NSNotificationCenter defaultCenter] postNotificationName:kLogToTextViewNotif
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:logText
                                                                                           forKey:kLogTextKey]];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kRegionEntryNotif
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:region forKey:kNewRegionKey]];
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    NSString* logText = [NSString stringWithFormat:@"didExitRegion: %@", region.identifier];
    DLog(@"%@",logText);
    [[NSNotificationCenter defaultCenter] postNotificationName:kLogToTextViewNotif
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:logText
                                                                                           forKey:kLogTextKey]];

    [[NSNotificationCenter defaultCenter] postNotificationName:kRegionExitNotif
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:region forKey:kNewRegionKey]];
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

#pragma mark - Region monitoring support

- (BOOL)registerRegionWithCoordinate:(CLLocationCoordinate2D)coordinate radius:(CLLocationDistance)radius identifier:(NSString*)identifier accuracy:(CLLocationAccuracy)accuracy
{
    // Check the authorization status
    if (([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorized) &&
        ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusNotDetermined))
        return NO;
    
    // Clear out any old regions to prevent buildup.
    if ([self.locationManager.monitoredRegions count] > 5) {
        for (id obj in self.locationManager.monitoredRegions)
        {
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
    CLCircularRegion* circularRegion = [[CLCircularRegion alloc] initWithCenter:coordinate radius:radius identifier:identifier];

    [self.locationManager startMonitoringForRegion:circularRegion];
    return YES;
}

- (void)stopAllRegionMonitoring
{
    // Clear out all old regions when we are done monitoring them.
    for (id obj in self.locationManager.monitoredRegions)
        [self.locationManager stopMonitoringForRegion:obj];
}

@end
