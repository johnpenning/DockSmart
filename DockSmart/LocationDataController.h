//
//  LocationDataController.h
//  DockSmart
//
//  Created by John Penning on 6/24/13.
//  Copyright (c) 2013 John Penning. All rights reserved.
//

#import "LocationController.h"
#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

@class MyLocation, Station, Address;

typedef NS_ENUM(NSInteger, LocationDataSortMethod) {
    LocationDataSortByName = 0,
    LocationDataSortByDistanceFromUser,
    LocationDataSortByDistanceFromDestination,
    LocationDataSortByBikes,
    LocationDataSortByDocks,
};

@interface LocationDataController : NSObject

// List of all stations in the current city's system
@property(nonatomic, copy) NSMutableArray *stationList;
// A version of the stationList that can be sorted according to different parameters
@property(nonatomic, copy) NSArray *sortedStationList;
// List of recent destinations (not fully implemented in this release)
@property(nonatomic, copy) NSMutableArray *recentsList;
// A version of the recentsList that can be sorted according to different parameters
@property(nonatomic, copy) NSArray *sortedRecentsList;
// List of user-specified favorite destinations (not fully implemented in this release)
@property(nonatomic, copy) NSMutableArray *favoritesList;
// A version of the favoritesList that can be sorted according to different parameters
@property(nonatomic, copy) NSArray *sortedFavoritesList;
// Current user coordinate
@property CLLocationCoordinate2D userCoordinate;

// Returns the count of a given list property
- (NSUInteger)countOfLocationList:(NSArray *)list;
// Returns the MyLocation object at a certain index in a given list property
- (MyLocation *)objectInLocationList:(NSArray *)list atIndex:(NSUInteger)index;
// Adds a MyLocation object to a list and updates the station distances from the user
- (void)addLocationObject:(MyLocation *)location toList:(NSMutableArray *)list;
// Adds an array of MyLocations to a list and updates the station distances from the user
- (void)addLocationObjectsFromArray:(NSArray *)locations toList:(NSMutableArray *)list;
// Sorts a list by a given LocationDataSortMethod (by name, distance from user, distances from destination, number of
// bikes, or number of docks)
- (NSArray *)sortLocationList:(NSMutableArray *)list byMethod:(LocationDataSortMethod)method;
// Updates station distances from the user
- (void)updateDistancesFromUserLocation:(CLLocationCoordinate2D)coordinate;

@end
