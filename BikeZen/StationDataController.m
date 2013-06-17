//
//  StationDataController.m
//  DockSmart
//
//  Created by John Penning on 6/15/13.
//  Copyright (c) 2013 John Penning. All rights reserved.
//

#import "StationDataController.h"
#import "Station.h"
#import "define.h"

@interface StationDataController ()
- (void)initializeDefaultDataList;
@end

@implementation StationDataController

- (void)initializeDefaultDataList {
    NSMutableArray *theStationList = [[NSMutableArray alloc] init];
    self.stationList = theStationList;
    
//    //Insert dummy station for testing:
//    Station *station;
//    NSDate *today = [NSDate date];
//    station = [[Station alloc] initWithStationID:999 name:@"Dummy Station" latitude:DUPONT_LAT longitude:DUPONT_LONG installed:YES locked:NO publiclyViewable:YES nbBikes:5 nbEmptyDocks:5 lastStationUpdate:today];
//    
//    [self addStationListObject:station];
}

- (void)setStationList:(NSMutableArray *)stationList
{
    if (_stationList != stationList)
    {
        _stationList = [stationList mutableCopy];
    }
}

- (id)init {
    if (self == [super init]) {
        [self initializeDefaultDataList];
        return self;
    }
    return nil;
}

- (NSUInteger)countOfStationList {
    return [self.stationList count];
}

- (Station *)objectInStationListAtIndex:(NSUInteger)index {
    return [self.stationList objectAtIndex:index];
}

- (void)addStationListObject:(Station *)station
{
    [self.stationList addObject:station];
}

- (void)addStationListObjectsFromArray:(NSArray *)stations
{
    [self.stationList addObjectsFromArray:stations];
}

@end
