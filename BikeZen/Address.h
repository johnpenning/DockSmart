//
//  Address.h
//  DockSmart
//
//  A subclass of MyLocation that is meant to be used for a general addressable location on a map, not a bikeshare Station.
//
//  Created by John Penning on 6/24/13.
//  Copyright (c) 2013 John Penning. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MyLocation.h"

@class MyLocation;

@interface Address : MyLocation <NSCoding, NSCopying>

//The placemark that is returned when we reverse geocode this Address
@property (nonatomic, readonly) CLPlacemark *placemark;

//Initialization method
- (id)initWithPlacemark:(CLPlacemark *)placemark distanceFromUser:(CLLocationDistance)distance;
//Setter for MyLocation properties using the given placemark
- (void)setNameAndCoordinateWithPlacemark:(CLPlacemark *)placemark distanceFromUser:(CLLocationDistance)distance;

@end
