//
//  DockSmartAppDelegate.m
//  DockSmart
//
//  Created by John Penning on 4/30/13.
//  Copyright (c) 2013 John Penning. All rights reserved.
//

#import "DockSmartAppDelegate.h"
#import "AFNetworkActivityIndicatorManager.h"
#import "DockSmartLogViewController.h"
#import "DockSmartMapViewController.h"
#import "LocationDataController.h"
#import "NSDictionary+CityBikesAPI.h"
#import "Station.h"
#import "define.h"

/* Notification keys */
// NSNotification name for sending station data to the map view
NSString *const kAddStationsNotif = @"AddStationsNotif";
// NSNotification userInfo key for obtaining the station data
NSString *const kStationResultsKey = @"StationResultsKey";
// NSNotification name for reporting errors
NSString *const kStationErrorNotif = @"StationErrorNotif";
// NSNotification userInfo key for obtaining the error message
NSString *const kStationsMsgErrorKey = @"StationsMsgErrorKey";

// defaults keys
NSString *const kAutoCityPreference = @"AutoCityPreference";
NSString *const kCityPreference = @"CityPreference";
NSString *const kDisplayedVersion = @"DisplayedVersion";

/* Local static keys */
// Message to appear in AFNetworking error AlertView
static NSString *const stationErrorMessage = @"Information might not be up-to-date.";

#pragma mark DockSmartAppDelegate ()

// forward declarations
@interface DockSmartAppDelegate ()

// Flag that tells us if a data load is in process
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

/*
 Is called immediately before launch finishes.  Switched from using
 application:didFinishLaunchingWithOptions: for state restoration purposes.
 */
- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.

    // In case significant change location services were on from the last time we
    // terminated, turn them off:
    [[LocationController sharedInstance] stopMonitoringSignificantLocationChanges];
    // Begin standard location service:
    [[LocationController sharedInstance] startUpdatingCurrentLocation];

    // Begin tracking network activity and showing the indicator in the status bar
    // when appropriate
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshStationData:)
                                                 name:kRefreshDataNotif
                                               object:nil];

    // Register default NSUserDefaults:
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *defaultDictionary =
        [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], kAutoCityPreference, CITY_URL_DC,
                                                   kCityPreference, version, kDisplayedVersion, nil];
    [defaults registerDefaults:defaultDictionary];

    // Automatically update the value for displayed_version with the bundle
    // version instead of doing it by manually updating a string here
    [defaults setObject:version forKey:kDisplayedVersion];

    [defaults synchronize];

    // Recall current city URL from NSUserDefaults:
    self.currentCityUrl = [defaults stringForKey:kCityPreference];

    NSNumber *startLocation = [launchOptions objectForKey:UIApplicationLaunchOptionsLocationKey];
    UILocalNotification *triggeredNotification =
        [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];

    NSString *logText =
        [NSString stringWithFormat:@"willFinishLaunchingWithOptions: startLocation %@ "
                                   @"triggeredNotification %@ applicationState: %ld",
                                   startLocation, [triggeredNotification alertBody], [application applicationState]];
    DLog(@"%@", logText);
    return YES;
}

/*
 Called when the app receives a local notification, if the app is running.
 */
- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    NSString *logText = [NSString stringWithFormat:@"applicationDidReceiveLocalNotification: applicationState: %ld",
                                                   [application applicationState]];
    DLog(@"%@", logText);

    NSString *notificationMessage = [notification alertBody];
    UIAlertController *alertView = [UIAlertController
        alertControllerWithTitle:NSLocalizedString(@"Station Update", @"Title for alert displayed when "
                                                                      @"bike destination change message "
                                                                      @"appears.")
                         message:notificationMessage
                  preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alertView addAction:defaultAction];

    if ([application applicationState] == UIApplicationStateActive) {
        // If we aren't entering the app from a local notification that already
        // played an alert sound and vibrated:
        // Play the alert sound
        SystemSoundID soundFileObject;
        CFBundleRef mainBundle = CFBundleGetMainBundle();
        CFURLRef soundFileURLRef = CFBundleCopyResourceURL(mainBundle, CFSTR("bicycle_bell"), CFSTR("wav"), NULL);
        AudioServicesCreateSystemSoundID(soundFileURLRef, &soundFileObject);
        AudioServicesPlaySystemSound(soundFileObject);

        // Vibrate the phone
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    }

    // Show the alert
    [self.window.rootViewController presentViewController:alertView animated:YES completion:nil];

    // TODO: Reload mapView w/ new icon colors
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state.
    // This can occur for certain types of temporary interruptions (such as an
    // incoming phone call or SMS message) or when the user quits the application
    // and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down
    // OpenGL ES frame rates. Games should use this method to pause the game.
    NSString *logText = [NSString
        stringWithFormat:@"applicationWillResignActive: applicationState: %ld", [application applicationState]];
    DLog(@"%@", logText);
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate
    // timers, and store enough application state information to restore your
    // application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called
    // instead of applicationWillTerminate: when the user quits.

    NSString *logText = [NSString
        stringWithFormat:@"applicationDidEnterBackground: applicationState: %ld", [application applicationState]];
    DLog(@"%@", logText);

    // Continue using standard location services if we are currently station
    // tracking, else stop
    DockSmartMapViewController *controller = self.window.rootViewController.childViewControllers[0];
    if (controller.bikingState != BikingStateActive) {
        [[LocationController sharedInstance] stopUpdatingCurrentLocation];
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state;
    // here you can undo many of the changes made on entering the background.

    NSString *logText = [NSString
        stringWithFormat:@"applicationWillEnterForeground: applicationState: %ld", [application applicationState]];
    DLog(@"%@", logText);

    // Start standard location service
    [[LocationController sharedInstance] startUpdatingCurrentLocation];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the
    // application was inactive. If the application was previously in the
    // background, optionally refresh the user interface.

    NSString *logText = [NSString
        stringWithFormat:@"applicationDidBecomeActive: applicationState: %ld", [application applicationState]];
    DLog(@"%@", logText);

    // Start standard location service
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
    // Called when the application is about to terminate. Save data if
    // appropriate. See also applicationDidEnterBackground:.
    NSString *logText =
        [NSString stringWithFormat:@"applicationWillTerminate: applicationState: %ld", [application applicationState]];
    DLog(@"%@", logText);

    // Switch to significant change location service:
    DockSmartMapViewController *controller = self.window.rootViewController.childViewControllers[0];
    if (controller.bikingState == BikingStateActive) {
        [[LocationController sharedInstance] startMonitoringSignificantLocationChanges];
    }
}

#pragma mark - State Restoration

- (BOOL)application:(UIApplication *)application shouldSaveApplicationState:(NSCoder *)coder
{
    return YES;
}

- (BOOL)application:(UIApplication *)application shouldRestoreApplicationState:(NSCoder *)coder
{
    // TODO: remember to change this to NO for the first session after an app
    // update, if the state restoration scheme changes
    return YES;
}

#pragma mark - JSON Methods

/*
 Loads a list of bikeshare networks from the CityBikes API, if needed.
 */
- (void)loadJSONCityData
{
    DockSmartMapViewController *controller = self.window.rootViewController.childViewControllers[0];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSString *logText = [NSString stringWithFormat:@"Auto city: %d", [defaults boolForKey:kAutoCityPreference]];
    DLog(@"%@", logText);

    // Set a flag saying we are currently loading data:
    self.isHTTPRequestInProcess = YES;

    /*
     If auto city detection is off, or if we're already on a bike route, or we don't have a current location, do not
     load the list of networks to determine which city we're in. Just load the current city's data.
     */
    if ((controller.bikingState != BikingStateInactive) || ([defaults boolForKey:kAutoCityPreference] == NO) ||
        ([[LocationController sharedInstance] location] == nil)) {
        NSString *logText = [NSString stringWithFormat:@"Skipping auto city detection"];
        DLog(@"%@", logText);

        [self loadJSONBikeDataForCityWithUrl:self.currentCityUrl];
        return;
    }

    /* Otherwise continue with auto city detection. Load the full list of
     * bikeshare networks. */

    [[DSHTTPSessionManager sharedInstance] GET:[NSString stringWithFormat:@"https://api.citybik.es/networks.json"]
        parameters:nil
        progress:nil
        success:^(NSURLSessionTask *task, id responseObject) {

            NSDictionary *networkData = (NSDictionary *)responseObject;

            // Find the closest network to the current user location, if we have
            // determined a location:
            if ([[LocationController sharedInstance] location]) {
                self.currentCityUrl =
                    [self closestBikeshareNetworkToLocation:[[LocationController sharedInstance] location]
                                                   withData:networkData];

                // Save the URL for the current city in NSUserDefaults:
                [defaults setObject:self.currentCityUrl forKey:kCityPreference];
                [defaults synchronize];
            }

            // Load this city's bike data:
            [self loadJSONBikeDataForCityWithUrl:self.currentCityUrl];

            // Note: We do not reset the isHTTPRequestInProcess flag here, since we
            // immediately start another request for the current city's station
            // data.
        }
        failure:^(NSURLSessionTask *task, NSError *error) {

            // Reset flag
            self.isHTTPRequestInProcess = NO;

            // Let the app know that we had trouble getting data.
            [[NSNotificationCenter defaultCenter]
                postNotificationName:kStationErrorNotif
                              object:self
                            userInfo:[NSDictionary dictionaryWithObject:error forKey:kStationsMsgErrorKey]];

            // We don't need to alert the user if this happens in the background, it
            // just means they have to wait for the next time we refresh the data
            if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
#ifdef DEBUG
                UIAlertController *alertView =
                    [UIAlertController alertControllerWithTitle:@"Error Retrieving Network Data"
                                                        message:[NSString stringWithFormat:@"%@", error]
                                                 preferredStyle:UIAlertControllerStyleAlert];

#else
                UIAlertController *alertView =
                    [UIAlertController alertControllerWithTitle:@"Error Retrieving Network Data"
                                                        message:stationErrorMessage
                                                 preferredStyle:UIAlertControllerStyleAlert];

#endif
                UIAlertAction *defaultAction =
                    [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
                [alertView addAction:defaultAction];

                [self.window.rootViewController presentViewController:alertView animated:YES completion:nil];
            }
        }];
}

// Returns the URL pointing towards the data for the closest network to a
// location, using the location of all the networks as listed in the networkData
// NSDictionary.
- (NSString *)closestBikeshareNetworkToLocation:(CLLocation *)location withData:(NSDictionary *)networkData
{
    // Find the distance from location to each network center and add that
    // distance to new key-value pair in NSDictionary
    NSMutableArray *newCityData = [[NSMutableArray alloc] init];
    CLLocationDistance distanceToUser;
    static NSString *const kUrl = @"url";
    static NSString *const kDistance = @"distance";

    for (id item in networkData) {
        distanceToUser =
            MKMetersBetweenMapPoints(MKMapPointForCoordinate([location coordinate]),
                                     MKMapPointForCoordinate(CLLocationCoordinate2DMake([item lat], [item lng])));
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        [dict setObject:[item url] forKey:kUrl];
        [dict setObject:[NSNumber numberWithDouble:distanceToUser] forKey:kDistance];
        [newCityData addObject:dict];
    }

    // Sort newCityData using new key-value pair
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:kDistance ascending:YES];

    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    NSArray *sortedArray = [newCityData sortedArrayUsingDescriptors:sortDescriptors];

    // Grab the top one and return the URL pointing towards the data for that
    // network.
    return [[sortedArray objectAtIndex:0] valueForKey:kUrl];
}

/*
 Loads station data from url.
 */
- (void)loadJSONBikeDataForCityWithUrl:(NSString *)url
{
    NSString *logText = [NSString stringWithFormat:@"loadJSONBikeDataForCityWithUrl: %@", url];
    DLog(@"%@", logText);

    [[DSHTTPSessionManager sharedInstance] GET:url
        parameters:nil
        progress:nil
        success:^(NSURLSessionTask *task, id responseObject) {

            // Reset flag
            self.isHTTPRequestInProcess = NO;

            NSDictionary *liveData = (NSDictionary *)responseObject;
            // Parse the new data:
            [self parseLiveData:liveData];
        }
        failure:^(NSURLSessionTask *task, NSError *error) {

            // Reset flag
            self.isHTTPRequestInProcess = NO;

            // Let the app know that we had trouble getting data.
            [[NSNotificationCenter defaultCenter]
                postNotificationName:kStationErrorNotif
                              object:self
                            userInfo:[NSDictionary dictionaryWithObject:error forKey:kStationsMsgErrorKey]];

            // We don't need to alert the user if this happens in the background, it
            // just means they have to wait for the next time we refresh the data
            if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
#ifdef DEBUG
                UIAlertController *alertView =
                    [UIAlertController alertControllerWithTitle:@"Error Retrieving Network Data"
                                                        message:[NSString stringWithFormat:@"%@", error]
                                                 preferredStyle:UIAlertControllerStyleAlert];

#else
                UIAlertController *alertView =
                    [UIAlertController alertControllerWithTitle:@"Error Retrieving Network Data"
                                                        message:stationErrorMessage
                                                 preferredStyle:UIAlertControllerStyleAlert];

#endif
                UIAlertAction *defaultAction =
                    [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
                [alertView addAction:defaultAction];

                [self.window.rootViewController presentViewController:alertView animated:YES completion:nil];
            }
        }];
}

/*
 NSNotificationCenter callback to tell us to reload the station data.
 */
- (void)refreshStationData:(NSNotification *)notif
{
    // if data is currently loading, don't try to load it again
    if (self.isHTTPRequestInProcess) {
        NSString *logText = [NSString stringWithFormat:@"HTTP request in process, overlapping request blocked"];
        DLog(@"%@", logText);
        return;
    }
    // Start loading
    [self loadJSONCityData];
}

/*
 Parses the AFNetworking output data into an array of Station objects.
 */
- (void)parseLiveData:(NSDictionary *)data
{
    NSMutableArray *stations = [NSMutableArray array];

    for (id item in data) {
        Station *tempStation = [[Station alloc] init];

        tempStation.stationID = [item stationID];
        //        DLog(@"StationID: %d", tempStation.stationID);
        tempStation.name = [item name];
        tempStation.latitude = [item lat];
        tempStation.longitude = [item lng];
        tempStation.nbBikes = [item bikes];
        tempStation.nbEmptyDocks = [item free];
        tempStation.lastStationUpdate = [(NSDictionary *)item timestamp];
        //        DLog(@"lastStationUpdate: %@", tempStation.lastStationUpdate);
        tempStation.installed = [item installed];
        tempStation.locked = [item locked];

        [tempStation initCoordinateWithLatitude:tempStation.latitude longitude:tempStation.longitude];

        if (CLLocationCoordinate2DIsValid(tempStation.coordinate)) {
            // add the Station object to the array if its coordinate is valid
            [stations addObject:tempStation];
        } else {
            // otherwise just log an error and go to the next station
            DLog(@"Invalid station coordinate: stationID %ld, %@, coord %f, %f", (long)tempStation.stationID,
                 tempStation.name, tempStation.latitude, tempStation.longitude);
        }
    }

    [[NSNotificationCenter defaultCenter]
        postNotificationName:kAddStationsNotif
                      object:self
                    userInfo:[NSDictionary dictionaryWithObject:stations forKey:kStationResultsKey]];
}

@end
