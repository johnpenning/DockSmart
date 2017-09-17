//
//  Address.m
//  DockSmart
//
//  A subclass of MyLocation that is meant to be used for a general addressable location on a map, not a bikeshare
//  Station.
//
//  Created by John Penning on 6/24/13.
//  Copyright (c) 2013 John Penning. All rights reserved.
//

#import "Address.h"
#import "MyLocation.h"
#import "define.h"

@implementation Address

// Initialization method
- (id)initWithPlacemark:(CLPlacemark *)placemark distanceFromUser:(CLLocationDistance)distance
{
    self = [super
            initWithName:[NSString stringWithFormat:@"%@%@%@%@%@%@%@",
                                                    placemark.subThoroughfare ? placemark.subThoroughfare : @"",
                                                    placemark.subThoroughfare ? @" " : @"",
                                                    placemark.thoroughfare ? placemark.thoroughfare : @"",
                                                    (placemark.subThoroughfare || placemark.thoroughfare) ? @", " : @"",
                                                    placemark.locality ? placemark.locality : @"",
                                                    (placemark.locality && placemark.administrativeArea) ? @", " : @"",
                                                    placemark.administrativeArea ? placemark.administrativeArea : @""]
              coordinate:placemark.location.coordinate
        distanceFromUser:distance];

    if (self) {
        _placemark = placemark;
        return self;
    }
    return nil;
}

// Setter for MyLocation properties using the given placemark
- (void)setNameAndCoordinateWithPlacemark:(CLPlacemark *)placemark distanceFromUser:(CLLocationDistance)distance
{
    self.name = [NSString
        stringWithFormat:@"%@%@%@%@%@%@%@", placemark.subThoroughfare ? placemark.subThoroughfare : @"",
                         placemark.subThoroughfare ? @" " : @"", placemark.thoroughfare ? placemark.thoroughfare : @"",
                         (placemark.subThoroughfare || placemark.thoroughfare) ? @", " : @"",
                         placemark.locality ? placemark.locality : @"",
                         (placemark.locality && placemark.administrativeArea) ? @", " : @"",
                         placemark.administrativeArea ? placemark.administrativeArea : @""];
    [self initCoordinateWithLatitude:placemark.location.coordinate.latitude
                           longitude:placemark.location.coordinate.longitude];
    self.distanceFromUser = distance;
    _placemark = placemark;
}

// MKAnnotation protocol method to return the subtitle for presentation in an annotation callout
- (NSString *)subtitle
{
    NSString *addressSummary;

    // only show sublocality (i.e. neighborhood, ideally) if it's not null and not the same string as the locality (i.e.
    // town, ideally)
    addressSummary = [[NSString alloc]
        initWithFormat:@"%@%@Dist: %2.2f mi",
                       (_placemark.subLocality && (![[_placemark subLocality] isEqualToString:[_placemark locality]]))
                           ? _placemark.subLocality
                           : @"",
                       (_placemark.subLocality && (![[_placemark subLocality] isEqualToString:[_placemark locality]]))
                           ? @" - "
                           : @"",
                       [super distanceFromUser] / METERS_PER_MILE];

    return addressSummary;
}

#pragma mark - State Restoration

static NSString *const PlacemarkKey = @"PlacemarkKey";

// Encode the necessary properties of this object
- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:_placemark forKey:PlacemarkKey];
}

// Decode the necessary properties of this object and use them to initialize it
- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];

    if (self) {
        _placemark = [aDecoder decodeObjectForKey:PlacemarkKey];
    }
    return self;
}

#pragma mark - NSCopying

// NSCopying protocol method
- (id)copyWithZone:(NSZone *)zone
{
    Address *other =
        [[Address alloc] initWithPlacemark:[_placemark copyWithZone:zone] distanceFromUser:self.distanceFromUser];
    other.annotationIdentifier = [self.annotationIdentifier copyWithZone:zone];

    return other;
}

@end
