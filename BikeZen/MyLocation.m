//
//  MyLocation.m
//  DockSmart
//
//  Created by John Penning on 5/1/13.
//  Copyright (c) 2013 John Penning. All rights reserved.
//

#import "MyLocation.h"

@implementation MyLocation

- (id)initWithName:(NSString *)name latitude:(CLLocationDegrees)latitude longitude:(CLLocationDegrees)longitude distanceFromUser:(CLLocationDistance)distance
{
    
    self = [super init];
    
    if (self)
    {
        _name = name;
        _coordinate = CLLocationCoordinate2DMake(latitude, longitude);
//        _latitude = latitude;
//        _longitude = longitude;
        _distanceFromUser = distance;
        return self;
    }
    return nil;
}

- (id)initWithName:(NSString *)name coordinate:(CLLocationCoordinate2D)coordinate distanceFromUser:(CLLocationDistance)distance
{
    
    self = [super init];
    
    if (self)
    {
        _name = name;
        _coordinate = coordinate;
        _distanceFromUser = distance;
        return self;
    }
    return nil;
}

- (void)initCoordinateWithLatitude:(CLLocationDegrees)latitude longitude:(CLLocationDegrees)longitude
{
    _coordinate = CLLocationCoordinate2DMake(latitude, longitude);
}

- (NSString *)title
{
    return _name;
}

@end
