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
#import "DockSmartMapViewController.h"
#import "LocationDataController.h"
#import "DockSmartLogViewController.h"
#import "NSDictionary+CityBikesAPI.h"
#import "AFNetworkActivityIndicatorManager.h"

// NSNotification name for sending station data to the map view
NSString *kAddStationsNotif = @"AddStationsNotif";
// NSNotification userInfo key for obtaining the station data
NSString *kStationResultsKey = @"StationResultsKey";
// NSNotification name for reporting errors
NSString *kStationErrorNotif = @"StationErrorNotif";
// NSNotification userInfo key for obtaining the error message
NSString *kStationsMsgErrorKey = @"StationsMsgErrorKey";

NSString *kAutoCityPreference = @"auto_city_preference";
NSString *kCityPreference = @"city_preference";
NSString *kDisplayedVersion = @"displayed_version";

const NSString *stationErrorMessage = @"Information might not be up-to-date.";

#pragma mark DockSmartAppDelegate ()

// forward declarations
@interface DockSmartAppDelegate ()

//Flag that tells us if a data load is in process
@property BOOL isHTTPRequestInProcess;

- (void)loadJSONCityData;
- (NSString *)closestBikeshareNetworkToLocation:(CLLocation *)location withData:(NSDictionary *)networkData;
- (void)loadJSONBikeDataForCityWithUrl:(NSString *)url;
- (void)parseLiveData:(NSDictionary *)data;
- (void)refreshStationData:(NSNotification *)notif;

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
    
    //In case significant change location services were on from the last time we terminated, turn them off:
    [[LocationController sharedInstance].locationManager stopMonitoringSignificantLocationChanges];
    //Begin standard location service:
    [[LocationController sharedInstance] startUpdatingCurrentLocation];
    
    //Begin tracking network activity and showing the indicator in the status bar when appropriate
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshStationData:)
                                                 name:kRefreshDataNotif
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
    
    //Continue using standard location services if we are currently station tracking, else stop
    DockSmartMapViewController *controller = self.window.rootViewController.childViewControllers[0];
    if (controller.bikingState != BikingStateActive)
    {
        [[LocationController sharedInstance] stopUpdatingCurrentLocation];
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
    
    //Start standard location service
    [[LocationController sharedInstance] startUpdatingCurrentLocation];

    // Recall current city URL from NSUserDefaults:
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults synchronize];
    self.currentCityUrl = [defaults stringForKey:kCityPreference];

    // Reload the station data
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

    //Switch to significant change location service:
    DockSmartMapViewController *controller = self.window.rootViewController.childViewControllers[0];
    if (controller.bikingState == BikingStateActive)
    {
        [[LocationController sharedInstance].locationManager startMonitoringSignificantLocationChanges];
    }

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


- (void)loadJSONCityData
{
    DockSmartMapViewController *controller = /*(UIViewController*)*/self.window.rootViewController.childViewControllers[0];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString* logText = [NSString stringWithFormat:@"Auto city: %d city value: %@", [defaults boolForKey:kAutoCityPreference], [defaults valueForKey:kCityPreference]];
    DLog(@"%@",logText);
    [[NSNotificationCenter defaultCenter] postNotificationName:kLogToTextViewNotif
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:logText
                                                                                           forKey:kLogTextKey]];

    //Set a flag saying we are currently loading data:
    self.isHTTPRequestInProcess = YES;
    
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
    
    [[DSHTTPSessionManager sharedInstance] GET:[NSString stringWithFormat:@"http://api.citybik.es/networks.json"]
      parameters:nil
         success:^(NSURLSessionTask *task, id responseObject) {
             
             NSDictionary *networkData = (NSDictionary *)responseObject;
             
             //Find the closest network to the current user location:
             self.currentCityUrl = [self closestBikeshareNetworkToLocation:[[LocationController sharedInstance] location] withData:networkData];
             
             //Save the URL for the current city in NSUserDefaults:
             [defaults setObject:self.currentCityUrl forKey:kCityPreference];
             [defaults synchronize];
             
             //Load this city's bike data:
             [self loadJSONBikeDataForCityWithUrl:self.currentCityUrl];
             
             //Note: We do not reset the isHTTPRequestInProcess flag here, since we immediately start another request for the current city's station data.
         }
         failure:^(NSURLSessionTask *task, NSError *error) {
             
             //Reset flag
             self.isHTTPRequestInProcess = NO;
             
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
    NSMutableArray *newCityData = [[NSMutableArray alloc] init];
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
    [[DSHTTPSessionManager sharedInstance] GET:url
      parameters:nil
         success:^(NSURLSessionTask *task, id responseObject) {
             
             //Reset flag
             self.isHTTPRequestInProcess = NO;

             NSDictionary *liveData = (NSDictionary *)responseObject;
             //Parse the new data:
             [self parseLiveData:liveData];
         }
         failure:^(NSURLSessionTask *task, NSError *error) {
             
             //Reset flag
             self.isHTTPRequestInProcess = NO;
             
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
    //if data is currently loading, don't try to load it again
    if (self.isHTTPRequestInProcess)
    {
        NSString* logText = [NSString stringWithFormat:@"HTTP request in process, overlapping request blocked"];
        DLog(@"%@",logText);
        [[NSNotificationCenter defaultCenter] postNotificationName:kLogToTextViewNotif
                                                            object:self
                                                          userInfo:[NSDictionary dictionaryWithObject:logText
                                                                                               forKey:kLogTextKey]];
        return;
    }
    //Start loading
    [self loadJSONCityData];
}

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
