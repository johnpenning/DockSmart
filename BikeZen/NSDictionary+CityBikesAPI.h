//
//  NSDictionary+CityBikesAPI.h
//  DockSmart
//
//  Created by John Penning on 12/14/13.
//  Copyright (c) 2013 John Penning. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface NSDictionary (CityBikesAPI)

//Used in <system>.json
-(NSInteger)stationID;
-(NSString *)name;
-(NSInteger)bikes;
-(NSInteger)free;
-(NSDate *)timestamp;
-(bool)installed;
-(bool)locked;

//Used in networks.json
-(NSString *)url;

//Used in both networks.json and <system>.json
-(CLLocationDegrees)lat;
-(CLLocationDegrees)lng;

@end
