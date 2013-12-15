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

-(NSInteger)stationID;
-(NSString *)name;
-(CLLocationDegrees)lat;
-(CLLocationDegrees)lng;
-(NSInteger)bikes;
-(NSInteger)free;
-(NSDate *)timestamp;
-(bool)installed;
-(bool)locked;

@end
