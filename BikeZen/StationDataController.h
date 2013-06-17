//
//  StationDataController.h
//  DockSmart
//
//  Created by John Penning on 6/15/13.
//  Copyright (c) 2013 John Penning. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Station;

@interface StationDataController : NSObject

@property (nonatomic, copy) NSMutableArray *stationList;
- (NSUInteger)countOfStationList;
- (Station *)objectInStationListAtIndex:(NSUInteger)index;
- (void)addStationListObject:(Station *)station;
- (void)addStationListObjectsFromArray:(NSArray *)stations;
@end
