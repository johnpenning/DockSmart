//
//  MyLocation.h
//  DockSmart
//
//  Created by John Penning on 5/1/13.
//  Copyright (c) 2013 John Penning. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface MyLocation : NSObject <MKAnnotation>

@property (nonatomic, copy) NSString *name;
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
//@property (nonatomic) CLLocationDegrees latitude;
//@property (nonatomic) CLLocationDegrees longitude;

- (id)initWithName:(NSString *)name latitude:(CLLocationDegrees)latitude longitude:(CLLocationDegrees)longitude;
- (id)initWithName:(NSString *)name coordinate:(CLLocationCoordinate2D)coordinate;
- (void)initCoordinateWithLatitude:(CLLocationDegrees)latitude longitude:(CLLocationDegrees)longitude;

@end
