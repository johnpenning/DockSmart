//
//  Station.h
//  DockSmart
//
//  Created by John Penning on 5/5/13.
//  Copyright (c) 2013 John Penning. All rights reserved.
//

#import "MyLocation.h"
#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

/*
 STATION OBJECT

 The data we care about is stored as properties in a Station object and parsed appropriately for presentation.
 */

@interface Station : MyLocation <MKAnnotation, NSCoding, NSCopying>

// ID of the Station
@property(nonatomic) NSInteger stationID;
// Station's latitude coordinate
@property(nonatomic) CLLocationDegrees latitude;
// Station's longitude coordinate
@property(nonatomic) CLLocationDegrees longitude;
// YES if the Station is installed
@property(nonatomic) bool installed;
// YES if the Station is locked
@property(nonatomic) bool locked;
// YES if the Station is public
@property(nonatomic) bool publiclyViewable;
// Number of bikes currently docked at this Station
@property NSInteger nbBikes;
// Number of empty docks currently at this Station
@property NSInteger nbEmptyDocks;
// Last time the Station data was updated
@property(nonatomic, copy) NSDate *lastStationUpdate;
// This Station's distance from the user's final destination
@property(nonatomic) CLLocationDistance distanceFromDestination;

// Public Station init method
- (id)initWithStationID:(NSInteger)stationID
                   name:(NSString *)name
               latitude:(CLLocationDegrees)latitude
              longitude:(CLLocationDegrees)longitude
              installed:(bool)installed
                 locked:(bool)locked
       publiclyViewable:(bool)publiclyViewable
                nbBikes:(NSInteger)nbBikes
           nbEmptyDocks:(NSInteger)nbEmptyDocks
      lastStationUpdate:(NSDate *)lastStationUpdate
       distanceFromUser:(CLLocationDistance)distance;

@end
