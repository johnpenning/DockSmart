//
//  BikeZenAppDelegate.m
//  BikeZen
//
//  Created by John Penning on 4/30/13.
//  Copyright (c) 2013 John Penning. All rights reserved.
//

#import "BikeZenAppDelegate.h"
#import "Station.h"
#import "ParseOperation.h"
#import "BikeZenSecondViewController.h"

#pragma mark BikeZenAppDelegate ()

// forward declarations
@interface BikeZenAppDelegate ()

//@property (strong, nonatomic) NSURLConnection *earthquakeFeedConnection;
@property (strong, nonatomic) NSMutableData *stationXMLData;    // the data returned from the NSURLConnection (or from initDataWithURL)
@property (strong, nonatomic) NSOperationQueue *parseQueue;     // the queue that manages our NSOperation for parsing station data

- (void)addStationsToList:(NSArray *)stations;
- (void)handleError:(NSError *)error;
@end


#pragma mark -
#pragma mark BikeZenAppDelegate

@implementation BikeZenAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    self.parseQueue = [NSOperationQueue new];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(addStations:)
                                                 name:kAddStationsNotif
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(stationError:)
                                                 name:kStationErrorNotif
                                               object:nil];
    
    // Spawn an NSOperation to parse the earthquake data so that the UI is not blocked while the
    // application parses the XML data.
    //
    // IMPORTANT! - Don't access or affect UIKit objects on secondary threads.
    //
    ParseOperation *parseOperation = [[ParseOperation alloc] init];
    [self.parseQueue addOperation:parseOperation];
//    [parseOperation release];   // once added to the NSOperationQueue it's retained, we don't need it anymore
    
    // earthquakeData will be retained by the NSOperation until it has finished executing,
    // so we no longer need a reference to it in the main thread.
    self.stationXMLData = nil;

    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    // TODO: Reload the station data?
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

// Our NSNotification callback from the running NSOperation to add the earthquakes
//
- (void)addStations:(NSNotification *)notif {
    assert([NSThread isMainThread]);
    
    [self addStationsToList:[[notif userInfo] valueForKey:kStationResultsKey]];
}

// Our NSNotification callback from the running NSOperation when a parsing error has occurred
//
- (void)stationError:(NSNotification *)notif {
    assert([NSThread isMainThread]);
    
    [self handleError:[[notif userInfo] valueForKey:kStationsMsgErrorKey]];
}

// The NSOperation "ParseOperation" calls addStations: via NSNotification, on the main thread
// which in turn calls this method, with batches of parsed objects.
// The batch size is set via the kSizeOfEarthquakeBatch constant.
//
- (void)addStationsToList:(NSArray *)stations {
    
    // insert the earthquakes into our secondViewController's data source (for KVO purposes)
//    [self.rootViewController insertEarthquakes:earthquakes];
    
    //This will in turn add the stations to the map.
    UIViewController *controller = (UIViewController*)self.window.rootViewController;
//    if (controller.is)
    //TODO: the following line is super dangerous and dumb as implemented.  Please change!
    [controller.childViewControllers[0] insertStations:stations];
    
}

@end
