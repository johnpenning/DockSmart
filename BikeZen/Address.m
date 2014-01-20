//
//  Address.m
//  DockSmart
//
//  Created by John Penning on 6/24/13.
//  Copyright (c) 2013 John Penning. All rights reserved.
//

#import "Address.h"
#import "MyLocation.h"
#import "define.h"

@implementation Address

- (id)initWithPlacemark:(CLPlacemark *)placemark distanceFromUser:(CLLocationDistance)distance
{
    self = [super initWithName:[NSString stringWithFormat:@"%@%@%@%@%@%@%@", placemark.subThoroughfare ? placemark.subThoroughfare : @"", placemark.subThoroughfare ? @" " : @"", placemark.thoroughfare ? placemark.thoroughfare : @"", (placemark.subThoroughfare || placemark.thoroughfare) ? @", " : @"", placemark.locality ? placemark.locality : @"", (placemark.locality && placemark.administrativeArea) ? @", " : @"", placemark.administrativeArea ? placemark.administrativeArea : @""] coordinate:placemark.location.coordinate distanceFromUser:distance];
    
    if (self)
    {
        _placemark = placemark;
        return self;
    }
    return nil;
}

- (NSString *)subtitle
{
    NSString* addressSummary;
    
    //only show sublocality (i.e. neighborhood, ideally) if it's not null and not the same string as the locality (i.e. town, ideally)
//    if ([[_placemark subLocality] isEqualToString:[_placemark locality]])
//        addressSummary = [[NSString alloc] initWithFormat:@""]; //TODO: add distance later
//    else
//        addressSummary = [[NSString alloc] initWithFormat:@"%@", _placemark.subLocality]; //TODO: add distance later
    
    addressSummary = [[NSString alloc] initWithFormat:@"%@%@Dist: %2.2f mi", (_placemark.subLocality && (![[_placemark subLocality] isEqualToString:[_placemark locality]])) ? _placemark.subLocality : @"", (_placemark.subLocality && (![[_placemark subLocality] isEqualToString:[_placemark locality]])) ? @" - " : @"", [super distanceFromUser]/METERS_PER_MILE];
    
    //    CLLocationDistance *distance = MKMetersBetweenMapPoints(MKMapPointForCoordinate(_coordinate), )
    return addressSummary;
}

#pragma mark - State Restoration

static NSString *PlacemarkKey = @"PlacemarkKey";

//- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
- (void)encodeWithCoder:(NSCoder *)aCoder
{
//    [super encodeRestorableStateWithCoder:coder];
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeObject:_placemark forKey:PlacemarkKey];
}

//- (void)decodeRestorableStateWithCoder:(NSCoder *)coder
- (id)initWithCoder:(NSCoder *)aDecoder
{
//    [super decodeRestorableStateWithCoder:coder];
    self = [super initWithCoder:aDecoder];
    
    if (self)
    {
        _placemark = [aDecoder decodeObjectForKey:PlacemarkKey];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
//    Address *other = (Address *)[super copyWithZone:zone];

    Address *other = [[Address alloc] initWithPlacemark:[_placemark copyWithZone:zone] distanceFromUser:self.distanceFromUser];
    other.annotationIdentifier = [self.annotationIdentifier copyWithZone:zone];
//    other.coordinate = self.coordinate;
//    other.distanceFromUser = self.distanceFromUser;

    return other;
}

@end
