//
//  Address.h
//  DockSmart
//
//  Created by John Penning on 6/24/13.
//  Copyright (c) 2013 John Penning. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MyLocation.h"

@class MyLocation;

@interface Address : MyLocation <NSCoding, NSCopying>

//geolocation properties/methods to be declared here
@property (nonatomic, readonly) CLPlacemark *placemark;

- (id)initWithPlacemark:(CLPlacemark *)placemark distanceFromUser:(CLLocationDistance)distance;

@end
