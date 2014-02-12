//
//  MyLocation.m
//  DockSmart
//
//  Created by John Penning on 5/1/13.
//  Copyright (c) 2013 John Penning. All rights reserved.
//

#import "MyLocation.h"

// Reuse identifiers for MyLocation annotationIdentifer in the MapView
NSString *kSourceStation = @"SourceStation";
NSString *kDestinationLocation = @"DestinationLocation";
NSString *kDestinationStation = @"DestinationStation";
NSString *kAlternateStation = @"AlternateStation";
NSString *kStation = @"Station";

@implementation MyLocation

- (id)initWithName:(NSString *)name latitude:(CLLocationDegrees)latitude longitude:(CLLocationDegrees)longitude distanceFromUser:(CLLocationDistance)distance
{
    
    self = [super init];
    
    if (self)
    {
        _name = name;
        _coordinate = CLLocationCoordinate2DMake(latitude, longitude);
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

#pragma mark - State Restoration

static NSString *NameKey = @"NameKey";
static NSString *CoordinateLatitudeKey = @"CoordinateLatitudeKey";
static NSString *CoordinateLongitudeKey = @"CoordinateLongitudeKey";
static NSString *DistanceFromUserKey = @"DistanceFromUserKey";
static NSString *AnnotationIdentifierKey = @"AnnotationIdentifierKey";

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.name forKey:NameKey];
    [aCoder encodeDouble:self.coordinate.latitude forKey:CoordinateLatitudeKey];
    [aCoder encodeDouble:self.coordinate.longitude forKey:CoordinateLongitudeKey];
    [aCoder encodeDouble:self.distanceFromUser forKey:DistanceFromUserKey];
    [aCoder encodeObject:self.annotationIdentifier forKey:AnnotationIdentifierKey];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    
    if (self)
    {
        self.name = [aDecoder decodeObjectForKey:NameKey];
        _coordinate = CLLocationCoordinate2DMake([aDecoder decodeDoubleForKey:CoordinateLatitudeKey], [aDecoder decodeDoubleForKey:CoordinateLongitudeKey]);
        self.distanceFromUser = [aDecoder decodeDoubleForKey:DistanceFromUserKey];
        self.annotationIdentifier = [aDecoder decodeObjectForKey:AnnotationIdentifierKey];
    }
    return self;
}

- (void)applicationFinishedRestoringState
{
    //Called on restored view controllers after other object decoding is complete.
    NSString* logText = [NSString stringWithFormat:@"finished restoring MyLocation"];
    DLog(@"%@",logText);
    [[NSNotificationCenter defaultCenter] postNotificationName:kLogToTextViewNotif
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:logText
                                                                                           forKey:kLogTextKey]];
}

- (id)copyWithZone:(NSZone *)zone
{
    MyLocation *other = [[MyLocation alloc] initWithName:[self.name copyWithZone:zone] coordinate:self.coordinate distanceFromUser:self.distanceFromUser];
    other.annotationIdentifier = [self.annotationIdentifier copyWithZone:zone];
    
    return other;
}


@end
