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
#import "AFNetworkActivityIndicatorManager.h"

NSString *kAutoCityPreference = @"auto_city_preference";
NSString *kCityPreference = @"city_preference";
NSString *kDisplayedVersion = @"displayed_version";

const NSString *stationErrorMessage = @"Information might not be up-to-date.";

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
- (NSString *)closestBikeshareNetworkToLocation:(CLLocation *)location withData:(NSDictionary *)networkData;
- (void)loadJSONBikeDataForCityWithUrl:(NSString *)url;
- (void)parseLiveData:(NSDictionary *)data;
//- (void)loadJSONData;
- (void)refreshStationData:(NSNotification *)notif;
//- (void)stationError:(NSNotification *)notif;
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
    [[LocationController sharedInstance] startUpdatingCurrentLocation];
    
    //Begin tracking network activity and showing the indicator in the status bar when appropriate
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];

//    self.parseQueue = [NSOperationQueue new];
    
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
    
    // Register default NSUserDefaults:
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *defaultDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], kAutoCityPreference, CITY_URL_DC, kCityPreference, version, kDisplayedVersion, nil];
    [defaults registerDefaults:defaultDictionary];
    
    //Automatically update the value for displayed_version with the bundle version instead of doing it by manually updating a string here
    [defaults setObject:version forKey:kDisplayedVersion];
    
    [defaults synchronize];
    
    // Recall current city URL from NSUserDefaults:
    self.currentCityUrl = [defaults stringForKey:kCityPreference];
    
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
    DLog(@"%@",logText);
    [[NSNotificationCenter defaultCenter] postNotificationName:kLogToTextViewNotif
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:logText
                                                                                           forKey:kLogTextKey]];
    
    return YES;
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    NSString* logText = [NSString stringWithFormat:@"applicationDidReceiveLocalNotification: applicationState: %d", [application applicationState]];
    DLog(@"%@",logText);
    [[NSNotificationCenter defaultCenter] postNotificationName:kLogToTextViewNotif
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:logText
                                                                                           forKey:kLogTextKey]];
    
    NSString *notificationMessage = [notification alertBody];
    UIAlertView *alertView =
    [[UIAlertView alloc] initWithTitle:
     NSLocalizedString(@"Station Update",
                       @"Title for alert displayed when bike destination change message appears.")
                               message:notificationMessage
                              delegate:nil
                     cancelButtonTitle:@"OK"
                     otherButtonTitles:nil];
    
    if ([application applicationState] == UIApplicationStateActive)
    {
        //If we aren't entering the app from a local notification that already played an alert sound and vibrated:
        //Play the alert sound
        SystemSoundID soundFileObject;
        CFBundleRef mainBundle = CFBundleGetMainBundle();
        CFURLRef soundFileURLRef = CFBundleCopyResourceURL(mainBundle, CFSTR("bicycle_bell"), CFSTR("wav"), NULL);
        AudioServicesCreateSystemSoundID(soundFileURLRef, &soundFileObject);
        AudioServicesPlaySystemSound(soundFileObject);
        
        //Vibrate the phone
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    }
    
    //Show the alert
    [alertView show];
    
    //TODO: Reload mapView w/ new icon colors

}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    NSString* logText = [NSString stringWithFormat:@"applicationWillResignActive: applicationState: %d", [application applicationState]];
    DLog(@"%@",logText);
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
    DLog(@"%@",logText);
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
    DLog(@"%@",logText);
    [[NSNotificationCenter defaultCenter] postNotificationName:kLogToTextViewNotif
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:logText
                                                                                           forKey:kLogTextKey]];

    
    //TODO: get rid of this and just keep significant location changes?  We don't need standard location service when we're in the foreground, since we have the minute timer running then.
    // Stop significant location change updates
//    DockSmartMapViewController *controller = /*(UIViewController*)*/self.window.rootViewController.childViewControllers[0];
//    if (controller.bikingState == BikingStateActive)
//    {
//        [[LocationController sharedInstance].locationManager stopMonitoringSignificantLocationChanges];
//        // Start standard location service
//        [[LocationController sharedInstance].locationManager startUpdatingLocation];
//    }
    
    //Start standard location service
    [[LocationController sharedInstance] startUpdatingCurrentLocation];

}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    NSString* logText = [NSString stringWithFormat:@"applicationDidBecomeActive: applicationState: %d", [application applicationState]];
    DLog(@"%@",logText);
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
    
    //Start standard location service
    [[LocationController sharedInstance] startUpdatingCurrentLocation];

    // Recall current city URL from NSUserDefaults:
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults synchronize];
    self.currentCityUrl = [defaults stringForKey:kCityPreference];

//    // Reload the station data
//    [self loadXMLData];
    [self loadJSONCityData];

}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    NSString* logText = [NSString stringWithFormat:@"applicationWillTerminate: applicationState: %d", [application applicationState]];
    DLog(@"%@",logText);
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
    DLog(@"%@",logText);
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
    DLog(@"%@",logText);
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
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    DLog(@"Auto city: %d city value: %@", [defaults boolForKey:kAutoCityPreference], [defaults valueForKey:kCityPreference]);
    
    /*
     If auto city detection is off, or if we're already on a bike route, do not load the list of networks to determine which city we're in.
     Just load the current city's data.
     */
    if ((controller.bikingState != BikingStateInactive) || ([defaults boolForKey:kAutoCityPreference] == NO))
    {
        [self loadJSONBikeDataForCityWithUrl:self.currentCityUrl];
        return;
    }
    
    /* Otherwise continue with auto city detection. Load the full list of bikeshare networks. */
    
    //Start spinning the network activity indicator:
//    [self setNetworkActivityIndicatorVisible:YES];
    
    [[DSHTTPSessionManager sharedInstance] GET:[NSString stringWithFormat:@"http://api.citybik.es/networks.json"]
      parameters:nil
         success:^(NSURLSessionTask *task, id responseObject) {
             
             //Stop spinning the network activity indicator:
//             [self setNetworkActivityIndicatorVisible:NO];
             
             NSDictionary *networkData = (NSDictionary *)responseObject;
             
             //Find the closest network to the current user location:
             self.currentCityUrl = [self closestBikeshareNetworkToLocation:[[LocationController sharedInstance] location] withData:networkData];
             
             //Save the URL for the current city in NSUserDefaults:
             [defaults setObject:self.currentCityUrl forKey:kCityPreference];
             [defaults synchronize];
             
             //Load this city's bike data:
             [self loadJSONBikeDataForCityWithUrl:self.currentCityUrl];
         }
         failure:^(NSURLSessionTask *task, NSError *error) {
             
             //Stop spinning the network activity indicator:
//             [self setNetworkActivityIndicatorVisible:NO];
             
             //Let the app know that we had trouble getting data.
             [[NSNotificationCenter defaultCenter] postNotificationName:kStationErrorNotif
                                                                 object:self
                                                               userInfo:[NSDictionary dictionaryWithObject:error
                                                                                                    forKey:kStationsMsgErrorKey]];
             
             //We don't need to alert the user if this happens in the background, it just means they have to wait for the next time we refresh the data
             if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive)
             {
#ifdef DEBUG
                 UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Error Retrieving Network Data" message:[NSString stringWithFormat:@"%@", error] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
#else
                 UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Error Retrieving Network Data" message:(NSString *)stationErrorMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
#endif
                 [av show];
             }
         }];
}

//Returns the URL pointing towards the data for the closest network to a location, using the location of all the networks as listed in the networkData NSDictionary.
- (NSString *)closestBikeshareNetworkToLocation:(CLLocation *)location withData:(NSDictionary *)networkData
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
//    [self setNetworkActivityIndicatorVisible:YES];
    //TODO: use built-in activity indicator in AFNetworking?
    
    [[DSHTTPSessionManager sharedInstance] GET:url
      parameters:nil
         success:^(NSURLSessionTask *task, id responseObject) {

             //Stop spinning the network activity indicator:
//             [self setNetworkActivityIndicatorVisible:NO];

             NSDictionary *liveData = (NSDictionary *)responseObject;
             //Parse the new data:
             [self parseLiveData:liveData];
         }
         failure:^(NSURLSessionTask *task, NSError *error) {

             //Stop spinning the network activity indicator:
//             [self setNetworkActivityIndicatorVisible:NO];
             
             //Let the app know that we had trouble getting data.
             [[NSNotificationCenter defaultCenter] postNotificationName:kStationErrorNotif
                                                                 object:self
                                                               userInfo:[NSDictionary dictionaryWithObject:error
                                                                                                    forKey:kStationsMsgErrorKey]];

             //We don't need to alert the user if this happens in the background, it just means they have to wait for the next time we refresh the data
             if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive)
             {
#ifdef DEBUG
                 UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Error Retrieving Station Data" message:[NSString stringWithFormat:@"%@", error] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
#else
                 UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Error Retrieving Station Data" message:(NSString *)stationErrorMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
#endif
                 [av show];
             }
         }];
}

- (void)refreshStationData:(NSNotification *)notif
{
//    assert([NSThread isMainThread]);
    
//    [self loadXMLData];
//    [self loadJSONData];
    [self loadJSONCityData];

}

#if 0
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
#endif

- (void)parseLiveData:(NSDictionary*)data
{
    NSMutableArray *stations = [NSMutableArray array];
    
    for (id item in data)
    {
        Station *tempStation = [[Station alloc] init];
        
        tempStation.stationID = [item stationID];
//        DLog(@"StationID: %d", tempStation.stationID);
        tempStation.name = [item name];
        tempStation.latitude = [item lat];
        tempStation.longitude = [item lng];
        tempStation.nbBikes = [item bikes];
        tempStation.nbEmptyDocks = [item free];
        tempStation.lastStationUpdate = [(NSDictionary*)item timestamp];
//        DLog(@"lastStationUpdate: %@", tempStation.lastStationUpdate);
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

@end
