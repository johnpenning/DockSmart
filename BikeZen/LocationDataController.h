//
//  LocationDataController.h
//  DockSmart
//
//  Created by John Penning on 6/24/13.
//  Copyright (c) 2013 John Penning. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class MyLocation, Station, Address;

extern NSString *kLocationUpdateNotif;
extern NSString *kNewLocationKey;

typedef NS_ENUM(NSInteger, LocationDataSortMethod) {
    LocationDataSortByName          = 0,
    LocationDataSortByDistance      = 1,
    LocationDataSortByBikes         = 2,
    LocationDataSortByDocks         = 3,
};

@interface LocationDataController : NSObject

@property (nonatomic, copy) NSMutableArray *stationList;
@property (nonatomic, copy) NSArray *sortedStationList;
@property (nonatomic, copy) NSMutableArray *recentsList;
@property (nonatomic, copy) NSArray *sortedRecentsList;
@property (nonatomic, copy) NSMutableArray *favoritesList;
@property (nonatomic, copy) NSArray *sortedFavoritesList;

- (NSUInteger)countOfLocationList:(NSArray *)list;
- (MyLocation *)objectInLocationList:(NSArray *)list atIndex:(NSUInteger)index;
//- (MyLocation *)objectInSortedLocationListAtIndex:(NSUInteger)index;
- (void)addLocationObject:(MyLocation *)location toList:(NSMutableArray *)list;
- (void)addLocationObjectsFromArray:(NSArray *)locations toList:(NSMutableArray *)list;
- (NSArray *)sortLocationList:(NSMutableArray *)list byMethod:(LocationDataSortMethod)method;
- (void)updateDistancesFromUserLocation:(CLLocationCoordinate2D)coordinate;

@end
