//
//  DockSmartAppDelegate.m
//  DockSmart
//
//  Created by John Penning on 4/30/13.
//  Copyright (c) 2013 John Penning. All rights reserved.
//

#import "DockSmartAppDelegate.h"
#import "define.h"
#import "Station.h"
#import "ParseOperation.h"
#import "DockSmartMapViewController.h"
#import "LocationDataController.h"
#import "DockSmartLogViewController.h"
#import "NSDictionary+CityBikesAPI.h"

NSString *kCurrentCityUrl = @"currentCityUrl";

#pragma mark DockSmartAppDelegate ()

// forward declarations
@interface DockSmartAppDelegate ()

//@property (strong, nonatomic) NSURLConnection *earthquakeFeedConnection;
@property (strong, nonatomic) NSMutableData *stationXMLData;    // the data returned from the NSURLConnection (or from initDataWithURL)
@property (strong, nonatomic) NSOperationQueue *parseQueue;     // the queue that manages our NSOperation for parsing station data

//- (void)addStationsToList:(NSArray *)stations;
- (void)handleError:(NSError *)error;
- (void)loadXMLData;
- (void)loadJSONCityData;
- (NSString *)closestBikeshareNetworkToLocation:(CLLocation*)location withData:(NSDictionary*)networkData;
- (void)loadJSONBikeDataForCityWithUrl:(NSString *)url;
- (void)parseLiveData:(NSDictionary*)data;
//- (void)loadJSONData;
- (void)refreshStationData:(NSNotification *)notif;
- (void)stationError:(NSNotification *)notif;
@end


#pragma mark -
#pragma mark DockSmartAppDelegate

@implementation DockSmartAppDelegate

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    //Begin location service
//    _userCoordinate = kCLLocationCoordinate2DInvalid;
    
//    [[LocationController sharedInstance] init];
    
    //Make sure the user has enabled location services before attempting to get the location
    [[LocationController sharedInstance] startUpdatingCurrentLocation];
    
//    self.parseQueue = [NSOperationQueue new];
    
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(addStations:)
//                                                 name:kAddStationsNotif
//                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(stationError:)
                                                 name:kStationErrorNotif
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshStationData:)
                                                 name:kRefreshTappedNotif
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(trackingDidStart:)
                                                 name:kTrackingStartedNotif
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(trackingDidStop:)
                                                 name:kTrackingStoppedNotif
                                               object:nil];
    
    // Recall current city URL from NSUserDefaults:
    self.currentCityUrl = [[NSUserDefaults standardUserDefaults] stringForKey:kCurrentCityUrl];
    if (!self.currentCityUrl)
    {
        self.currentCityUrl = CITY_URL_DC;
    }
    
    // Spawn an NSOperation to parse the earthquake data so that the UI is not blocked while the
    // application parses the XML data.
    //
    // IMPORTANT! - Don't access or affect UIKit objects on secondary threads.
    //
//    ParseOperation *parseOperation = [[ParseOperation alloc] init];
//    [self.parseQueue addOperation:parseOperation];
//    
//    // stationXMLData will be retained by the NSOperation until it has finished executing,
//    // so we no longer need a reference to it in the main thread.
//    self.stationXMLData = nil;
    
//    [self loadXMLData];
//    [self loadJSONData]; //taken care of in ApplicationDidBecomeActive:
    
    NSNumber *startLocation = [launchOptions objectForKey:UIApplicationLaunchOptionsLocationKey];
    UILocalNotification *triggeredNotification = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
    
    
    NSString* logText = [NSString stringWithFormat:@"didFinishLaunchingWithOptions: startLocation %@ triggeredNotification %@ applicationState: %d", startLocation, [triggeredNotification alertBody], [application applicationState]];
    NSLog(@"%@",logText);
    [[NSNotificationCenter defaultCenter] postNotificationName:kLogToTextViewNotif
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:logText
                                                                                           forKey:kLogTextKey]];
    
    return YES;
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    NSString *notificationMessage = [notification alertBody];
    UIAlertView *alertView =
    [[UIAlertView alloc] initWithTitle:
     NSLocalizedString(@"Notification Title",
                       @"Title for alert displayed when bike destination change message appears.")
                               message:notificationMessage
                              delegate:nil
                     cancelButtonTitle:@"OK"
                     otherButtonTitles:nil];
    [alertView show];
    
    //TODO: Reload mapView w/ new icon colors

}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    NSString* logText = [NSString stringWithFormat:@"applicationWillResignActive: applicationState: %d", [application applicationState]];
    NSLog(@"%@",logText);
    [[NSNotificationCenter defaultCenter] postNotificationName:kLogToTextViewNotif
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:logText
                                                                                           forKey:kLogTextKey]];

}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    NSString* logText = [NSString stringWithFormat:@"applicationDidEnterBackground: applicationState: %d", [application applicationState]];
    NSLog(@"%@",logText);
    [[NSNotificationCenter defaultCenter] postNotificationName:kLogToTextViewNotif
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:logText
                                                                                           forKey:kLogTextKey]];
    //Stop standard location service:
    [[LocationController sharedInstance] stopUpdatingCurrentLocation];
    //Switch to significant change location service:
    //TODO: Change to use notifications/KVO?
    DockSmartMapViewController *controller = /*(UIViewController*)*/self.window.rootViewController.childViewControllers[0];
    if (controller.bikingState == BikingStateActive)
    {
        [[LocationController sharedInstance].locationManager startMonitoringSignificantLocationChanges];
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.

    NSString* logText = [NSString stringWithFormat:@"applicationWillEnterForeground: applicationState: %d", [application applicationState]];
    NSLog(@"%@",logText);
    [[NSNotificationCenter defaultCenter] postNotificationName:kLogToTextViewNotif
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:logText
                                                                                           forKey:kLogTextKey]];

    
    //TODO: get rid of this and just keep significant location changes?  We don't need standard location service when we're in the foreground, since we have the minute timer running then.
    // Stop significant location change updates
    DockSmartMapViewController *controller = /*(UIViewController*)*/self.window.rootViewController.childViewControllers[0];
    if (controller.bikingState == BikingStateActive)
    {
        [[LocationController sharedInstance].locationManager stopMonitoringSignificantLocationChanges];
        // Start standard location service
        [[LocationController sharedInstance].locationManager startUpdatingLocation];
    }

    // TODO: Reload the station data?
//    [self loadXMLData];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    NSString* logText = [NSString stringWithFormat:@"applicationDidBecomeActive: applicationState: %d", [application applicationState]];
    NSLog(@"%@",logText);
    [[NSNotificationCenter defaultCenter] postNotificationName:kLogToTextViewNotif
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:logText
                                                                                           forKey:kLogTextKey]];

//    // Stop significant location change updates
//    DockSmartMapViewController *controller = /*(UIViewController*)*/self.window.rootViewController.childViewControllers[0];
//    if (controller.bikingState == BikingStateActive)
//    {
//        [self.locationManager stopMonitoringSignificantLocationChanges];
//        // Start standard location service
//        [self.locationManager startUpdatingLocation];
//    }
    
//    // TODO: Reload the station data?
//    [self loadXMLData];
//    [self loadJSONData];
    [self loadJSONCityData];

}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    NSString* logText = [NSString stringWithFormat:@"applicationWillTerminate: applicationState: %d", [application applicationState]];
    NSLog(@"%@",logText);
    [[NSNotificationCenter defaultCenter] postNotificationName:kLogToTextViewNotif
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:logText
                                                                                           forKey:kLogTextKey]];

}

#pragma mark - State Restoration

-(BOOL)application:(UIApplication *)application shouldSaveApplicationState:(NSCoder *)coder
{
    return YES;
}

-(BOOL)application:(UIApplication *)application shouldRestoreApplicationState:(NSCoder *)coder
{
    //TODO: remember to change this to NO for the first session after an app update
    return YES;
}

#pragma mark - NSXMLParser Methods

// Handle errors in the download by showing an alert to the user. This is a very
// simple way of handling the error, partly because this application does not have any offline
// functionality for the user. Most real applications should handle the error in a less obtrusive
// way and provide offline functionality to the user.
//
- (void)handleError:(NSError *)error {
//    NSString *errorMessage = [error localizedDescription];
//    UIAlertView *alertView =
//    [[UIAlertView alloc] initWithTitle:
//     NSLocalizedString(@"Error Title",
//                       @"Title for alert displayed when download or parse error occurs.")
//                               message:errorMessage
//                              delegate:nil
//                     cancelButtonTitle:@"OK"
//                     otherButtonTitles:nil];
//    [alertView show];
    NSString* logText = [NSString stringWithFormat:@"NSXMLParser error: %@", [error localizedDescription]];
    NSLog(@"%@",logText);
    [[NSNotificationCenter defaultCenter] postNotificationName:kLogToTextViewNotif
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:logText
                                                                                           forKey:kLogTextKey]];

}

// Our NSNotification callback from the running NSOperation to add the earthquakes
//
#if 0
- (void)addStations:(NSNotification *)notif {
    assert([NSThread isMainThread]);
    
    [self addStationsToList:[[notif userInfo] valueForKey:kStationResultsKey]];
}
#endif

// Our NSNotification callback from the running NSOperation when a parsing error has occurred
//
- (void)stationError:(NSNotification *)notif {
//    assert([NSThread isMainThread]);
    
    [self handleError:[[notif userInfo] valueForKey:kStationsMsgErrorKey]];
}

// The NSOperation "ParseOperation" calls addStations: via NSNotification, on the main thread
// which in turn calls this method, with batches of parsed objects.
// The batch size is set via the kSizeOfEarthquakeBatch constant.
//
#if 0
- (void)addStationsToList:(NSArray *)stations {
    
    // insert the earthquakes into our mapViewController's data source (for KVO purposes)
//    [self.rootViewController insertEarthquakes:earthquakes];
    
    //Insert stations in .plist file for displaying in the Destinations view later.
//    NSString* plistPath = nil;
//    NSFileManager* manager = [NSFileManager defaultManager];
//    if ((plistPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Supporting Files/stationData.plist"]))
//    {
//        if ([manager isWritableFileAtPath:plistPath])
//        {
//            NSMutableDictionary* infoDict = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
//            [infoDict setObject:@"foo object" forKey:@"fookey"];
//            [infoDict writeToFile:plistPath atomically:NO];
//            [manager setAttributes:[NSDictionary dictionaryWithObject:[NSDate date] forKey:NSFileModificationDate] ofItemAtPath:[[NSBundle mainBundle] bundlePath] error:nil];
//        }
//    }
    
    //This will in turn add the stations to the map.
    UIViewController *controller = (UIViewController*)self.window.rootViewController;
    //TODO: the following line is super dangerous and dumb as implemented.  Please change! (use Notifs?)
    [controller.childViewControllers[0] insertStations:stations];
//    DockSmartMapViewController *mapViewController = (DockSmartMapViewController *)self.window.rootViewController.childViewControllers[0];
//    [mapViewController.dataController addStationListObjectsFromArray:stations];
    
//    [[NSNotificationCenter defaultCenter] postNotificationName:kAddStationsNotif
//                                                        object:self
//                                                      userInfo:[NSDictionary dictionaryWithObject:stations
//                                                                                           forKey:kStationResultsKey]];

    
}
#endif

- (void)loadXMLData //TODO: do this multiple times without adding duplicate stations (done, test)
{
    //log the new parse operation
    NSString* logText = [NSString stringWithFormat:@"XML parse operation started"];
    NSLog(@"%@",logText);
    [[NSNotificationCenter defaultCenter] postNotificationName:kLogToTextViewNotif
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:logText
                                                                                           forKey:kLogTextKey]];

    self.parseQueue = [NSOperationQueue new];
    
    ParseOperation *parseOperation = [[ParseOperation alloc] initWithData:self.stationXMLData];
    [self.parseQueue addOperation:parseOperation];
    
    // stationXMLData will be retained by the NSOperation until it has finished executing,
    // so we no longer need a reference to it in the main thread.
    self.stationXMLData = nil;
}

- (void)loadJSONCityData
{
    DockSmartMapViewController *controller = /*(UIViewController*)*/self.window.rootViewController.childViewControllers[0];
    if (controller.bikingState != BikingStateInactive)
    {
        [self loadJSONBikeDataForCityWithUrl:self.currentCityUrl];
        return;
    }
    
    //Start spinning the network activity indicator:
    [self setNetworkActivityIndicatorVisible:YES];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager GET:[NSString stringWithFormat:@"http://api.citybik.es/networks.json"]
      parameters:nil
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             
             //Stop spinning the network activity indicator:
             [self setNetworkActivityIndicatorVisible:NO];
             
             NSDictionary *networkData = (NSDictionary *)responseObject;
             
             //Find the closest network to the current user location:
             self.currentCityUrl = [self closestBikeshareNetworkToLocation:[[LocationController sharedInstance] location] withData:networkData];
             
             //Save the URL for the current city in NSUserDefaults:
             [[NSUserDefaults standardUserDefaults] setObject:self.currentCityUrl forKey:kCurrentCityUrl];
             [[NSUserDefaults standardUserDefaults] synchronize];
             
             //Load this city's bike data:
             [self loadJSONBikeDataForCityWithUrl:self.currentCityUrl];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             
             //Stop spinning the network activity indicator:
             [self setNetworkActivityIndicatorVisible:NO];
             
             UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Error Retrieving Network Data" message:[NSString stringWithFormat:@"%@", error] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
             [av show];
         }];
}

//Returns the URL pointing towards the data for the closest network to a location, using the location of all the networks as listed in the networkData NSDictionary.
- (NSString *)closestBikeshareNetworkToLocation:(CLLocation*)location withData:(NSDictionary*)networkData
{
    //Find the distance from location to each network center and add that distance to new key-value pair in NSDictionary
//    NSMutableArray /*NSDictionary*/ *newNetworkDict = [(NSArray*)networkData mutableCopy];
    NSMutableArray *newCityData = [[NSMutableArray alloc] init];//[[NSMutableArray alloc] initWithCapacity:[networkData count]];
    CLLocationDistance distanceToUser;
    
    for (id item in networkData)
    {
        distanceToUser = MKMetersBetweenMapPoints(MKMapPointForCoordinate([location coordinate]), MKMapPointForCoordinate(CLLocationCoordinate2DMake([item lat], [item lng])));
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        [dict setObject:[item url] forKey:@"url"];
        [dict setObject:[NSNumber numberWithDouble:distanceToUser] forKey:@"distance"];
        [newCityData addObject:dict];
    }
    
    //Sort newCityData using new key-value pair
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"distance" ascending:YES];
    
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    NSArray *sortedArray = [newCityData sortedArrayUsingDescriptors:sortDescriptors];
    
    //Grab the top one and return the URL pointing towards the data for that network.
    return [[sortedArray objectAtIndex:0] valueForKey:@"url"];
}

- (void)loadJSONBikeDataForCityWithUrl:(NSString *)url
{
    //Start spinning the network activity indicator:
    [self setNetworkActivityIndicatorVisible:YES];

    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager GET:url /*[NSString stringWithFormat:@"http://api.citybik.es/capitalbikeshare.json"]*/
      parameters:nil
         success:^(AFHTTPRequestOperation *operation, id responseObject) {

             //Stop spinning the network activity indicator:
             [self setNetworkActivityIndicatorVisible:NO];

             NSDictionary *liveData = (NSDictionary *)responseObject;
             //Parse the new data:
             [self parseLiveData:liveData];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {

             //Stop spinning the network activity indicator:
             [self setNetworkActivityIndicatorVisible:NO];

             UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Error Retrieving Station Data" message:[NSString stringWithFormat:@"%@", error] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
             [av show];
         }];
}

- (void)refreshStationData:(NSNotification *)notif
{
//    assert([NSThread isMainThread]);
    
//    [self loadXMLData];
//    [self loadJSONData];
    [self loadJSONCityData];

}

//Manage the network activity indicator (from http://oleb.net/blog/2009/09/managing-the-network-activity-indicator/ )
- (void)setNetworkActivityIndicatorVisible:(BOOL)setVisible {
    static NSInteger NumberOfCallsToSetVisible = 0;
    if (setVisible)
        NumberOfCallsToSetVisible++;
    else
        NumberOfCallsToSetVisible--;
    
    // The assertion helps to find programmer errors in activity indicator management.
    // Since a negative NumberOfCallsToSetVisible is not a fatal error,
    // it should probably be removed from production code.
    NSAssert(NumberOfCallsToSetVisible >= 0, @"Network Activity Indicator was asked to hide more often than shown");
    
    // Display the indicator as long as our static counter is > 0.
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:(NumberOfCallsToSetVisible > 0)];
}

- (void)parseLiveData:(NSDictionary*)data
{
    NSMutableArray *stations = [NSMutableArray array];
    
    for (id item in data)
    {
        Station *tempStation = [[Station alloc] init];
        
        tempStation.stationID = [item stationID];
//        NSLog(@"StationID: %d", tempStation.stationID);
        tempStation.name = [item name];
        tempStation.latitude = [item lat];
        tempStation.longitude = [item lng];
        tempStation.nbBikes = [item bikes];
        tempStation.nbEmptyDocks = [item free];
        tempStation.lastStationUpdate = [(NSDictionary*)item timestamp];
//        NSLog(@"lastStationUpdate: %@", tempStation.lastStationUpdate);
        tempStation.installed = [item installed];
        tempStation.locked = [item locked];
        
        [tempStation initCoordinateWithLatitude:tempStation.latitude longitude:tempStation.longitude];
        
        //add the Station object to the array
        [stations addObject:tempStation];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kAddStationsNotif
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:stations
                                                                                           forKey:kStationResultsKey]];

}

#pragma mark - CLLocationManagerDelegate
#if 0
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

        _userCoordinate = [location coordinate];
        
        NSLog(@"New location: %@", location);
        
//        [[NSNotificationCenter defaultCenter] postNotificationName:kLocationUpdateNotif
//                                                            object:self
//                                                          userInfo:[NSDictionary dictionaryWithObject:[[CLLocation alloc] initWithLatitude:self.userCoordinate.latitude longitude:self.userCoordinate.longitude] forKey:kNewLocationKey]];
        
        //If we're not actively biking, stop updating location to save battery
        DockSmartMapViewController *controller = /*(UIViewController*)*/self.window.rootViewController.childViewControllers[0];
        if (controller.bikingState != BikingStateActive)
        {
            [self stopUpdatingCurrentLocation];
        }
    }
}

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
    _userCoordinate = kCLLocationCoordinate2DInvalid;
    
    // show the error alert
//    UIAlertView *alert = [[UIAlertView alloc] init];
//    alert.title = @"Error obtaining location";
//    alert.message = [error localizedDescription];
//    [alert addButtonWithTitle:@"OK"];
//    [alert show];
}
#endif

@end
