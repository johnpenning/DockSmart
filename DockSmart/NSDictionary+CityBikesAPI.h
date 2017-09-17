//
//  NSDictionary+CityBikesAPI.h
//  DockSmart
//
//  NSDictionary categories for the City Bikes API, to pull the proper data from the NSDictionary output of AFNetworking
//  methods.
//
//  Created by John Penning on 12/14/13.
//  Copyright (c) 2013 John Penning. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface NSDictionary (CityBikesAPI)

/*
 Data from http://api.citybik.es

 There are some variables that all systems share:

 id: CityBikes station id
 name: Station name
 lat: Latitude in E6 format
 lng: Longitude in E6 format
 bikes: Number of bikes in the station
 free: Number of free slots
 timestamp: The last time the station has been updated

 And sometimes, there are Community Bike systems that provide more info than usual (for example in Wien). In these cases
 you will see more info in the feed, like:

 internal_id: The real station id
 status
 description (an address..)
 ...
*/

// Used in <system>.json
- (NSInteger)stationID;
- (NSString *)name;
- (NSInteger)bikes;
- (NSInteger)free;
- (NSDate *)timestamp;
- (bool)installed;
- (bool)locked;

// Used in networks.json
- (NSString *)url;

// Used in both networks.json and <system>.json
- (CLLocationDegrees)lat;
- (CLLocationDegrees)lng;

@end
