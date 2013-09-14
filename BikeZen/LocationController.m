//
//  LocationController.m
//  DockSmart
//
//  Created by John Penning on 9/14/13.
//  Copyright (c) 2013 John Penning. All rights reserved.
//  (With help from http://jinru.wordpress.com/2010/08/15/singletons-in-objective-c-an-example-of-cllocationmanager/ )
//

#import "LocationController.h"

//static LocationController* sharedCLDelegate = nil;

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
    [[NSNotificationCenter defaultCenter] postNotificationName:kLogToTextViewNotif
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:logText
                                                                                           forKey:kLogTextKey]];
    
    if (abs(howRecent) < 15.0)
    {
        // If the event is recent, do something with it.
        
//        _userCoordinate = [location coordinate];
        
        NSLog(@"New location: %@", location);
        
//        [[NSNotificationCenter defaultCenter] postNotificationName:kLocationUpdateNotif
//                                                            object:self
//                                                          userInfo:[NSDictionary dictionaryWithObject:[[CLLocation alloc] initWithLatitude:self.userCoordinate.latitude longitude:self.userCoordinate.longitude] forKey:kNewLocationKey]];
        
        [self.delegate locationUpdate:location];
        
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

@end
