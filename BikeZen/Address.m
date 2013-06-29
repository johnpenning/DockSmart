//
//  Address.m
//  DockSmart
//
//  Created by John Penning on 6/24/13.
//  Copyright (c) 2013 John Penning. All rights reserved.
//

#import "Address.h"
#import "MyLocation.h"

@implementation Address

- (id)initWithPlacemark:(CLPlacemark *)placemark
{
    self = [super initWithName:[NSString stringWithFormat:@"%@ %@, %@", placemark.subThoroughfare, placemark.thoroughfare, placemark.locality] coordinate:placemark.location.coordinate];
    
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
    
    //only show sublocality (i.e. neighborhood, ideally) if it's not the same string as the locality (i.e. town, ideally)
    if ([[_placemark subLocality] isEqualToString:[_placemark locality]])
        addressSummary = [[NSString alloc] initWithFormat:@""]; //TODO: add distance later
    else
        addressSummary = [[NSString alloc] initWithFormat:@"%@", _placemark.subLocality]; //TODO: add distance later
    //    CLLocationDistance *distance = MKMetersBetweenMapPoints(MKMapPointForCoordinate(_coordinate), )
    return addressSummary;
}

@end
