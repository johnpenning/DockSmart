//
//  MyLocation.h
//  DockSmart
//
//  Created by John Penning on 5/1/13.
//  Copyright (c) 2013 John Penning. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "DockSmartLogViewController.h"

// Reuse identifiers for MyLocation annotations in the MapView
extern NSString * const kSourceStation;
extern NSString * const kDestinationLocation;
extern NSString * const kDestinationStation;
extern NSString * const kAlternateStation;
extern NSString * const kStation;

@interface MyLocation : NSObject <MKAnnotation, NSCoding, NSCopying>

@property (nonatomic, copy) NSString *name;
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic) CLLocationDistance distanceFromUser;
@property (nonatomic, copy) NSString *annotationIdentifier;

- (id)initWithName:(NSString *)name latitude:(CLLocationDegrees)latitude longitude:(CLLocationDegrees)longitude distanceFromUser:(CLLocationDistance)distance;
- (id)initWithName:(NSString *)name coordinate:(CLLocationCoordinate2D)coordinate distanceFromUser:(CLLocationDistance)distance;
- (void)initCoordinateWithLatitude:(CLLocationDegrees)latitude longitude:(CLLocationDegrees)longitude;

@end