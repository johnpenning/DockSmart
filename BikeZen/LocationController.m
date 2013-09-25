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

NSString *kLocationUpdateNotif = @"LocationUpdateNotif";
NSString *kNewLocationKey = @"NewLocationKey";
NSString *kRegionUpdateNotif = @"RegionUpdateNotif";
NSString *kNewRegionKey = @"NewRegionKey";

@implementation LocationController

- (id)init
{
    self = [super init];
    if (self != nil) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
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
    NSLog(@"%@",logText);
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
    //        _locationManager.purpose = @"This will be used as part of the hint region for forward geocoding.";
    
    [_locationManager startUpdatingLocation];
    
    //    [self showCurrentLocationSpinner:YES];
}

- (void)stopUpdatingCurrentLocation
{
    NSString* logText = [NSString stringWithFormat:@"stopUpdatingCurrentLocation"];
    NSLog(@"%@",logText);
    [[NSNotificationCenter defaultCenter] postNotificationName:kLogToTextViewNotif
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:logText
                                                                                           forKey:kLogTextKey]];
    
    [_locationManager stopUpdatingLocation];
    //    [self showCurrentLocationSpinner:NO];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    //TODO: make current location button inactive on mapview
}

//- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
//{
//    // if the location is older than 30s ignore
//    if (fabs([newLocation.timestamp timeIntervalSinceDate:[NSDate date]]) > 30)
//    {
//        return;
//    }
//
//    _selectedCoordinate = [newLocation coordinate];
//
//    // update the current location cells detail label with these coords
//    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]];
//    cell.detailTextLabel.text = [NSString stringWithFormat:@"φ:%.4F, λ:%.4F", _selectedCoordinate.latitude, _selectedCoordinate.longitude];
//
//    // after recieving a location, stop updating
//    [self stopUpdatingCurrentLocation];
//}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    // If it's a relatively recent event, turn off updates to save power
    CLLocation* location = [locations lastObject];
    NSDate* eventDate = location.timestamp;
    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
    
    NSString* logText = [NSString stringWithFormat:@"didUpdateLocations: location: %@", location];
    NSLog(@"%@",logText);
    [[NSNotificationCenter defaultCenter] postNotificationName:kLogToTextViewNotif
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:logText
                                                                                           forKey:kLogTextKey]];
    
    if (abs(howRecent) < 15.0)
    {
        // If the event is recent, do something with it.
        
//        _userCoordinate = [location coordinate];
        
        NSLog(@"New location: %@", location);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kLocationUpdateNotif
                                                            object:self
                                                          userInfo:[NSDictionary dictionaryWithObject:location forKey:kNewLocationKey]];
        
//        [self.delegate locationUpdate:location];
        
        //If we're not actively biking, stop updating location to save battery
//        DockSmartMapViewController *controller = /*(UIViewController*)*/self.window.rootViewController.childViewControllers[0];
//        if (controller.bikingState != BikingStateActive)
//        {
//            [self stopUpdatingCurrentLocation];
//        }
    }
}

#if 0
- (void)locationManagerDidPauseLocationUpdates:(CLLocationManager *)manager
{
    //For testing: local notification
    UILocalNotification *locationUpdatesPausedNotification = [[UILocalNotification alloc] init];
    [locationUpdatesPausedNotification setAlertBody:[NSString stringWithFormat:@"Location updates paused: %f, %f %@", _userCoordinate.latitude, _userCoordinate.longitude, [NSDate date]]];
    [locationUpdatesPausedNotification setFireDate:[NSDate date]];
    [[UIApplication sharedApplication] presentLocalNotificationNow:locationUpdatesPausedNotification];
}

- (void)locationManagerDidResumeLocationUpdates:(CLLocationManager *)manager
{
    //For testing: local notification
    UILocalNotification *locationUpdatesResumedNotification = [[UILocalNotification alloc] init];
    [locationUpdatesResumedNotification setAlertBody:[NSString stringWithFormat:@"Location updates resumed: %f, %f %@", _userCoordinate.latitude, _userCoordinate.longitude, [NSDate date]]];
    [locationUpdatesResumedNotification setFireDate:[NSDate date]];
    [[UIApplication sharedApplication] presentLocalNotificationNow:locationUpdatesResumedNotification];
}
#endif

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"%@", error);
    
    NSString* logText = [NSString stringWithFormat:@"locationManagerDidFailWithError: %@", [error localizedDescription]];
    NSLog(@"%@",logText);
    [[NSNotificationCenter defaultCenter] postNotificationName:kLogToTextViewNotif
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:logText
                                                                                           forKey:kLogTextKey]];
    
    
    // stop updating
    [self stopUpdatingCurrentLocation];
    
    // since we got an error, set selected location to invalid location
//    _userCoordinate = kCLLocationCoordinate2DInvalid;
    
    // show the error alert
    //    UIAlertView *alert = [[UIAlertView alloc] init];
    //    alert.title = @"Error obtaining location";
    //    alert.message = [error localizedDescription];
    //    [alert addButtonWithTitle:@"OK"];
    //    [alert show];
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    NSString* logText = [NSString stringWithFormat:@"monitoringDidFailForRegion: %@ %f, %f withError: %@", region.identifier, region.center.latitude, region.center.longitude, [error localizedDescription]];
    NSLog(@"%@",logText);
    [[NSNotificationCenter defaultCenter] postNotificationName:kLogToTextViewNotif
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:logText
                                                                                           forKey:kLogTextKey]];

}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    NSString* logText = [NSString stringWithFormat:@"didEnterRegion: %@ %f, %f", region.identifier, region.center.latitude, region.center.longitude];
    NSLog(@"%@",logText);
    [[NSNotificationCenter defaultCenter] postNotificationName:kLogToTextViewNotif
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:logText
                                                                                           forKey:kLogTextKey]];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kRegionUpdateNotif
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:region forKey:kNewRegionKey]];

//    if([self.delegate respondsToSelector: @selector(regionUpdate:)])
//    {
//        [self.delegate regionUpdate:region];
//    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    NSString* logText = [NSString stringWithFormat:@"didExitRegion: %@ %f, %f", region.identifier, region.center.latitude, region.center.longitude];
    NSLog(@"%@",logText);
    [[NSNotificationCenter defaultCenter] postNotificationName:kLogToTextViewNotif
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:logText
                                                                                           forKey:kLogTextKey]];

    [[NSNotificationCenter defaultCenter] postNotificationName:kRegionUpdateNotif
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:region forKey:kNewRegionKey]];

//    if([self.delegate respondsToSelector: @selector(regionUpdate:)])
//    {
//        [self.delegate regionUpdate:region];
//    }
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
    // Do not create regions if support is unavailable or disabled
    if ( ![CLLocationManager regionMonitoringAvailable])
        return NO;
    
    // Check the authorization status
    if (([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorized) &&
        ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusNotDetermined))
        return NO;
    
    // Clear out any old regions to prevent buildup.
    if ([self.locationManager.monitoredRegions count] > 5) {
        for (id obj in self.locationManager.monitoredRegions)
            [self.locationManager stopMonitoringForRegion:obj];
    }
    
    // If the overlay's radius is too large, registration fails automatically,
    // so clamp the radius to the max value.
    if (radius > self.locationManager.maximumRegionMonitoringDistance) {
        radius = self.locationManager.maximumRegionMonitoringDistance;
    }
    
    // Create the region to be monitored.
    CLRegion* region = [[CLRegion alloc] initCircularRegionWithCenter:coordinate
                                                               radius:radius identifier:identifier];
    [self.locationManager startMonitoringForRegion:region];// desiredAccuracy:accuracy];
    return YES;
}

- (void)stopAllRegionMonitoring
{
    // Clear out all old regions when we are done monitoring them.
    for (id obj in self.locationManager.monitoredRegions)
        [self.locationManager stopMonitoringForRegion:obj];
}

@end
