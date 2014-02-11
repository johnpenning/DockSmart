//
//  LocationDataController.m
//  DockSmart
//
//  Created by John Penning on 6/24/13.
//  Copyright (c) 2013 John Penning. All rights reserved.
//

#import "LocationDataController.h"
#import "DockSmartMapViewController.h"
#import "LocationController.h"
#import "MyLocation.h"
#import "Station.h"
#import "Address.h"
#import "define.h"

@interface LocationDataController ()
- (void)initializeDefaultDataList;
@end

@implementation LocationDataController

- (void)initializeDefaultDataList {
    NSMutableArray *theStationList = [[NSMutableArray alloc] init];
    self.stationList = theStationList;
    //for now, just initialize these to empty lists... later on, recall data from file to store here
    NSMutableArray *theRecentsList = [[NSMutableArray alloc] init];
    self.recentsList = theRecentsList;
    NSMutableArray *theFavoritesList = [[NSMutableArray alloc] init];
    self.favoritesList = theFavoritesList;
    
    self.userCoordinate = kCLLocationCoordinate2DInvalid;
    
//    [LocationController sharedInstance].delegate = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateLocation:)
                                                 name:kLocationUpdateNotif
                                               object:nil];

}

- (void)setStationList:(NSMutableArray *)stationList
{
    if (_stationList != stationList)
    {
        _stationList = [stationList mutableCopy];
    }
}

- (void)setRecentsList:(NSMutableArray *)recentsList
{
    if (_recentsList != recentsList)
    {
        _recentsList = [recentsList mutableCopy];
    }
}

- (void)setFavoritesList:(NSMutableArray *)favoritesList
{
    if (_favoritesList != favoritesList)
    {
        _favoritesList = [favoritesList mutableCopy];
    }
}

- (id)init
{
    self = [super init];
    
    if (self)
    {
        [self initializeDefaultDataList];
        return self;
    }
    return nil;
}

- (NSUInteger)countOfLocationList:(NSArray *)list
{
    return [list count];
}

- (MyLocation *)objectInLocationList:(NSArray *)list atIndex:(NSUInteger)index
{
    return [list objectAtIndex:index];
}

- (void)addLocationObject:(MyLocation *)location toList:(NSMutableArray *)list
{
    [list addObject:location];
    
    //update distances:
    [self updateDistancesFromUserLocation:[self userCoordinate]];
}

- (void)addLocationObjectsFromArray:(NSArray *)locations toList:(NSMutableArray *)list
{
    [list addObjectsFromArray:locations];

    //update distances:
    [self updateDistancesFromUserLocation:[self userCoordinate]];
}

- (NSArray *)sortLocationList:(NSMutableArray *)locations byMethod:(LocationDataSortMethod)method
{
    for (MyLocation *location in locations)
    {
        if ((![location isKindOfClass:[Station class]]) && ((method == LocationDataSortByBikes) || (method == LocationDataSortByDocks)))
        {
            //We cannot sort by bikes or docks if the list of locations to be sorted does not 100% contain Station objects. Return the original unsorted list and log an error.
            DLog(@"Non-Station objects attempted to be sorted by bikes or docks.");
            return (NSArray *)locations;
        }
    }
    
    NSSortDescriptor *sortDescriptor;
    
    switch (method) {
        case LocationDataSortByBikes:
            sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"nbBikes" ascending:NO];
            break;
        case LocationDataSortByDocks:
            sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"nbEmptyDocks" ascending:NO];
            break;
        case LocationDataSortByDistanceFromUser:
            sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"distanceFromUser" ascending:YES];
            break;
        case LocationDataSortByDistanceFromDestination:
            sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"distanceFromDestination" ascending:YES];
            break;
        case LocationDataSortByName:
        default:
            sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
            break;
    }
    
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    NSArray *sortedArray;
    sortedArray = [locations sortedArrayUsingDescriptors:sortDescriptors];
    return sortedArray;
}

#pragma mark - KVO compliance

- (void)updateLocation:(NSNotification *)notif {
    
    [self setUserCoordinate:[(CLLocation *)[[notif userInfo] valueForKey:kNewLocationKey] coordinate]];
    [self updateDistancesFromUserLocation:[self userCoordinate]];
}

- (void)updateDistancesFromUserLocation:(CLLocationCoordinate2D)coordinate
{
    [self willChangeValueForKey:kStationList];
    
    for (Station *station in self.stationList)
    {
        [station setDistanceFromUser:MKMetersBetweenMapPoints(MKMapPointForCoordinate(coordinate), MKMapPointForCoordinate(station.coordinate))];
    }
    [self didChangeValueForKey:kStationList];
    
    //TODO: Set distances for recents and favorites lists

}

#pragma mark - State Restoration

//- (void) encodeRestorableStateWithCoder:(NSCoder *)coder
//{
//    
//}
//
//- (void) decodeRestorableStateWithCoder:(NSCoder *)coder
//{
//    
//}

@end
