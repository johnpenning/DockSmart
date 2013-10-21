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
//        _name = name;
//        _coordinate = CLLocationCoordinate2DMake(latitude, longitude);
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

//- (void)initCoordinateWithLatitude:(CLLocationDegrees)latitude longitude:(CLLocationDegrees)longitude
//{
//    _coordinate = CLLocationCoordinate2DMake(latitude, longitude);
//}

//- (NSString *)title
//{
////    return [[NSString alloc] initWithFormat:@"Test name"];
//    return _name;
//}

- (NSString *)subtitle
{
    NSString* bikeSummary = [[NSString alloc] initWithFormat:@"Bikes: %i - Docks: %i - Dist: %2.2f mi", _nbBikes, _nbEmptyDocks, [super distanceFromUser]/METERS_PER_MILE];
//    CLLocationDistance *distance = MKMetersBetweenMapPoints(MKMapPointForCoordinate(_coordinate), )
    return bikeSummary;
}

//- (CLLocationCoordinate2D)coordinate
//{
//    return _coordinate;
//}

//- (MKMapItem*)mapItem
//{
//    NSDictionary *addressDict = @{(NSString*)kABPersonAddressStreetKey : _address};
//    
//    MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:self.coordinate addressDictionary:addressDict];
//    
//    MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
//    mapItem.name = self.title;
//    
//    return mapItem;
//}

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

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeInteger:self.stationID forKey:StationIDKey];
    [coder encodeDouble:self.latitude forKey:LatitudeKey];
    [coder encodeDouble:self.longitude forKey:LongitudeKey];
    [coder encodeBool:self.installed forKey:InstalledKey];
    [coder encodeBool:self.locked forKey:LockedKey];
    [coder encodeBool:self.publiclyViewable forKey:PubliclyViewableKey];
    [coder encodeInteger:self.nbBikes forKey:NbBikesKey];
    [coder encodeInteger:self.nbEmptyDocks forKey:NbEmptyDocksKey];
    [coder encodeObject:self.lastStationUpdate forKey:LastStationUpdateKey];
    [coder encodeDouble:self.distanceFromDestination forKey:DistanceFromDestinationKey];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super decodeRestorableStateWithCoder:coder];
    
    self.stationID = [coder decodeIntegerForKey:StationIDKey];
    self.latitude = [coder decodeDoubleForKey:LatitudeKey];
    self.longitude = [coder decodeDoubleForKey:LongitudeKey];
    self.installed = [coder decodeBoolForKey:InstalledKey];
    self.locked = [coder decodeBoolForKey:LockedKey];
    self.publiclyViewable = [coder decodeBoolForKey:PubliclyViewableKey];
    self.nbBikes = [coder decodeIntegerForKey:NbBikesKey];
    self.nbEmptyDocks = [coder decodeIntegerForKey:NbEmptyDocksKey];
    self.lastStationUpdate = [coder decodeObjectForKey:LastStationUpdateKey];
    self.distanceFromDestination = [coder decodeDoubleForKey:DistanceFromDestinationKey];
}

@end
