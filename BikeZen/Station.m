//
//  Station.m
//  DockSmart
//
//  Created by John Penning on 5/5/13.
//  Copyright (c) 2013 John Penning. All rights reserved.
//

#import "Station.h"
#import "MyLocation.h"
#import "define.h"

@implementation Station

- (id)init
{
    self = [super init];
    
    if (self)
    {
        [super setAnnotationIdentifier:kStation];
        return self;
    }
    return nil;
}

- (id)initWithStationID:(NSInteger)stationID name:(NSString *)name latitude:(CLLocationDegrees)latitude longitude:(CLLocationDegrees)longitude installed:(bool)installed locked:(bool)locked publiclyViewable:(bool)publiclyViewable nbBikes:(NSInteger)nbBikes nbEmptyDocks:(NSInteger)nbEmptyDocks lastStationUpdate:(NSDate *)lastStationUpdate distanceFromUser:(CLLocationDistance)distance
{
    self = [super initWithName:name latitude:latitude longitude:longitude distanceFromUser:distance];
    
    if (self)
    {
        _stationID = stationID;
        _latitude = latitude;
        _longitude = longitude;
        _installed = installed;
        _locked = locked;
        _publiclyViewable = publiclyViewable;
        _nbBikes = nbBikes;
        _nbEmptyDocks = nbEmptyDocks;
        _lastStationUpdate = lastStationUpdate;
        _distanceFromDestination = CLLocationDistanceMax; //to be filled in when the user chooses a destination
        [super setAnnotationIdentifier:kStation];
        return self;
    }
    return nil;
}

- (NSString *)subtitle
{
    NSString* bikeSummary = [[NSString alloc] initWithFormat:@"Bikes: %i - Docks: %i - Dist: %2.2f mi", _nbBikes, _nbEmptyDocks, [super distanceFromUser]/METERS_PER_MILE];
    return bikeSummary;
}

#pragma mark - State Restoration

static NSString *StationIDKey = @"StationIDKey";
static NSString *LatitudeKey = @"LatitudeKey";
static NSString *LongitudeKey = @"LongitudeKey";
static NSString *InstalledKey = @"InstalledKey";
static NSString *LockedKey = @"LockedKey";
static NSString *PubliclyViewableKey = @"PubliclyViewableKey";
static NSString *NbBikesKey = @"NbBikesKey";
static NSString *NbEmptyDocksKey = @"NbEmptyDocksKey";
static NSString *LastStationUpdateKey = @"LastStationUpdateKey";
static NSString *DistanceFromDestinationKey = @"DistanceFromDestinationKey";

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeInteger:self.stationID forKey:StationIDKey];
    [aCoder encodeDouble:self.latitude forKey:LatitudeKey];
    [aCoder encodeDouble:self.longitude forKey:LongitudeKey];
    [aCoder encodeBool:self.installed forKey:InstalledKey];
    [aCoder encodeBool:self.locked forKey:LockedKey];
    [aCoder encodeBool:self.publiclyViewable forKey:PubliclyViewableKey];
    [aCoder encodeInteger:self.nbBikes forKey:NbBikesKey];
    [aCoder encodeInteger:self.nbEmptyDocks forKey:NbEmptyDocksKey];
    [aCoder encodeObject:self.lastStationUpdate forKey:LastStationUpdateKey];
    [aCoder encodeDouble:self.distanceFromDestination forKey:DistanceFromDestinationKey];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self)
    {
        self.stationID = [aDecoder decodeIntegerForKey:StationIDKey];
        self.latitude = [aDecoder decodeDoubleForKey:LatitudeKey];
        self.longitude = [aDecoder decodeDoubleForKey:LongitudeKey];
        self.installed = [aDecoder decodeBoolForKey:InstalledKey];
        self.locked = [aDecoder decodeBoolForKey:LockedKey];
        self.publiclyViewable = [aDecoder decodeBoolForKey:PubliclyViewableKey];
        self.nbBikes = [aDecoder decodeIntegerForKey:NbBikesKey];
        self.nbEmptyDocks = [aDecoder decodeIntegerForKey:NbEmptyDocksKey];
        self.lastStationUpdate = [aDecoder decodeObjectForKey:LastStationUpdateKey];
        self.distanceFromDestination = [aDecoder decodeDoubleForKey:DistanceFromDestinationKey];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    Station *other = [[Station alloc] init];

    other = [other initWithName:[self.name copyWithZone:zone] coordinate:self.coordinate distanceFromUser:self.distanceFromUser];

    other.stationID = self.stationID;
    other.latitude = self.latitude;
    other.longitude = self.longitude;
    other.installed = self.installed;
    other.locked = self.locked;
    other.publiclyViewable = self.publiclyViewable;
    other.nbBikes = self.nbBikes;
    other.nbEmptyDocks = self.nbEmptyDocks;
    other.lastStationUpdate = [self.lastStationUpdate copyWithZone:zone];
    other.distanceFromDestination = self.distanceFromDestination;
    other.annotationIdentifier = [self.annotationIdentifier copyWithZone:zone];
    
    return other;
}

@end
