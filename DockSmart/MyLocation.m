//
//  MyLocation.m
//  DockSmart
//
//  Created by John Penning on 5/1/13.
//  Copyright (c) 2013 John Penning. All rights reserved.
//

#import "MyLocation.h"

// Reuse identifiers for MyLocation annotationIdentifer in the MapView
NSString *const kSourceStation = @"SourceStation";
NSString *const kDestinationLocation = @"DestinationLocation";
NSString *const kDestinationStation = @"DestinationStation";
NSString *const kAlternateStation = @"AlternateStation";
NSString *const kStation = @"Station";

@implementation MyLocation

/* Initialization methods */

- (id)initWithName:(NSString *)name
            latitude:(CLLocationDegrees)latitude
           longitude:(CLLocationDegrees)longitude
    distanceFromUser:(CLLocationDistance)distance
{

    self = [super init];

    if (self) {
        _name = name;
        _coordinate = CLLocationCoordinate2DMake(latitude, longitude);
        _distanceFromUser = distance;

        return self;
    }
    return nil;
}

- (id)initWithName:(NSString *)name
          coordinate:(CLLocationCoordinate2D)coordinate
    distanceFromUser:(CLLocationDistance)distance
{

    self = [super init];

    if (self) {
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

// MKAnnotation protocol method to return the title for the annotation callout
- (NSString *)title
{
    return _name;
}

#pragma mark - State Restoration

static NSString *const NameKey = @"NameKey";
static NSString *const CoordinateLatitudeKey = @"CoordinateLatitudeKey";
static NSString *const CoordinateLongitudeKey = @"CoordinateLongitudeKey";
static NSString *const DistanceFromUserKey = @"DistanceFromUserKey";
static NSString *const AnnotationIdentifierKey = @"AnnotationIdentifierKey";

// Encode the necessary properties of this object
- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.name forKey:NameKey];
    [aCoder encodeDouble:self.coordinate.latitude forKey:CoordinateLatitudeKey];
    [aCoder encodeDouble:self.coordinate.longitude forKey:CoordinateLongitudeKey];
    [aCoder encodeDouble:self.distanceFromUser forKey:DistanceFromUserKey];
    [aCoder encodeObject:self.annotationIdentifier forKey:AnnotationIdentifierKey];
}

// Decode the necessary properties of this object and use them to initialize it
- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];

    if (self) {
        self.name = [aDecoder decodeObjectForKey:NameKey];
        _coordinate = CLLocationCoordinate2DMake([aDecoder decodeDoubleForKey:CoordinateLatitudeKey],
                                                 [aDecoder decodeDoubleForKey:CoordinateLongitudeKey]);
        self.distanceFromUser = [aDecoder decodeDoubleForKey:DistanceFromUserKey];
        self.annotationIdentifier = [aDecoder decodeObjectForKey:AnnotationIdentifierKey];
    }
    return self;
}

- (void)applicationFinishedRestoringState
{
    // Called on restored view controllers after other object decoding is complete.
    NSString *logText = [NSString stringWithFormat:@"finished restoring MyLocation"];
    DLog(@"%@", logText);
}

#pragma mark - NSCopying

// NSCopying protocol method
- (id)copyWithZone:(NSZone *)zone
{
    MyLocation *other = [[MyLocation alloc] initWithName:[self.name copyWithZone:zone]
                                              coordinate:self.coordinate
                                        distanceFromUser:self.distanceFromUser];
    other.annotationIdentifier = [self.annotationIdentifier copyWithZone:zone];

    return other;
}


@end
