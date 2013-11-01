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
//        _latitude = latitude;
//        _longitude = longitude;
        _distanceFromUser = distance;
        
//        [UIApplication registerObjectForStateRestoration:self restorationIdentifier:@"MyLocationID"];
        
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

//        [UIApplication registerObjectForStateRestoration:self restorationIdentifier:@"MyLocationID"];

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

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.name forKey:NameKey];
    [coder encodeDouble:self.coordinate.latitude forKey:CoordinateLatitudeKey];
    [coder encodeDouble:self.coordinate.longitude forKey:CoordinateLongitudeKey];
    [coder encodeDouble:self.distanceFromUser forKey:DistanceFromUserKey];
    [coder encodeObject:self.annotationIdentifier forKey:AnnotationIdentifierKey];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    self.name = [coder decodeObjectForKey:NameKey];
    _coordinate = CLLocationCoordinate2DMake([coder decodeDoubleForKey:CoordinateLatitudeKey], [coder decodeDoubleForKey:CoordinateLongitudeKey]);
    self.distanceFromUser = [coder decodeDoubleForKey:DistanceFromUserKey];
    self.annotationIdentifier = [coder decodeObjectForKey:AnnotationIdentifierKey];
}

- (void)applicationFinishedRestoringState
{
    //Called on restored view controllers after other object decoding is complete.
    NSString* logText = [NSString stringWithFormat:@"finished restoring MyLocation"];
    NSLog(@"%@",logText);
    [[NSNotificationCenter defaultCenter] postNotificationName:kLogToTextViewNotif
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:logText
                                                                                           forKey:kLogTextKey]];
}


@end
