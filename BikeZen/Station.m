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

@end
