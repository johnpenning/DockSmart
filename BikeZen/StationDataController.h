//
//  StationDataController.h
//  DockSmart
//
//  Created by John Penning on 6/15/13.
//  Copyright (c) 2013 John Penning. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Station;

typedef NS_ENUM(NSInteger, StationDataSortMethod) {
    StationDataSortByName          = 0,
    StationDataSortByBikes         = 1,
    StationDataSortByDocks         = 2,
    StationDataSortByDistance      = 3,
};

@interface StationDataController : NSObject

@property (nonatomic, copy) NSMutableArray *stationList;
@property (nonatomic, copy) NSArray *sortedStationList;
- (NSUInteger)countOfStationList;
- (Station *)objectInStationListAtIndex:(NSUInteger)index;
- (Station *)objectInSortedStationListAtIndex:(NSUInteger)index;
- (void)addStationListObject:(Station *)station;
- (void)addStationListObjectsFromArray:(NSArray *)stations;
- (NSArray *)sortStationList:(NSMutableArray *)stations byMethod:(StationDataSortMethod)method;

@end
