//
//  MyLocation.h
//  DockSmart
//
//  Created by John Penning on 5/1/13.
//  Copyright (c) 2013 John Penning. All rights reserved.
//

#import "DockSmartLogViewController.h"
#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

// Reuse identifiers for MyLocation annotations in the MapView
extern NSString *const kSourceStation;
extern NSString *const kDestinationLocation;
extern NSString *const kDestinationStation;
extern NSString *const kAlternateStation;
extern NSString *const kStation;

@interface MyLocation : NSObject <MKAnnotation, NSCoding, NSCopying>

// Location name. Set differently via different subclass init overrides
@property(nonatomic, copy) NSString *name;
// Location coordinates
@property(nonatomic, readonly) CLLocationCoordinate2D coordinate;
// Distance (in meters) of this MyLocation object from the user's current location
@property(nonatomic) CLLocationDistance distanceFromUser;
// Determines which annotation is used to represent this object on a map view
@property(nonatomic, copy) NSString *annotationIdentifier;

// Initialization functions
- (id)initWithName:(NSString *)name
            latitude:(CLLocationDegrees)latitude
           longitude:(CLLocationDegrees)longitude
    distanceFromUser:(CLLocationDistance)distance;
- (id)initWithName:(NSString *)name
          coordinate:(CLLocationCoordinate2D)coordinate
    distanceFromUser:(CLLocationDistance)distance;
- (void)initCoordinateWithLatitude:(CLLocationDegrees)latitude longitude:(CLLocationDegrees)longitude;

@end