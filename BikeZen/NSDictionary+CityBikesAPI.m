//
//  NSDictionary+CityBikesAPI.m
//  DockSmart
//
//  Created by John Penning on 12/14/13.
//  Copyright (c) 2013 John Penning. All rights reserved.
//

#import "NSDictionary+CityBikesAPI.h"

@implementation NSDictionary (CityBikesAPI)

-(NSInteger)stationID
{
    NSInteger n = [[self objectForKey:@"id"] integerValue];
    return n;
}

-(NSString *)name
{
    NSString *str = [self objectForKey:@"name"];
    //Take the first 8 characters out of the name, where the ID number is (for DC only... current API does not standardize this, so might have to make it city-specific for now)
    return [str stringByReplacingCharactersInRange:NSMakeRange(0, 8) withString:@""];
}

-(CLLocationDegrees)lat
{
    CLLocationDegrees n = [[self objectForKey:@"lat"] integerValue]/1e6;
//    CLLocationDegrees n = (CLLocationDegrees)[str integerValue];
    return n;
}

-(CLLocationDegrees)lng
{
    CLLocationDegrees n = [[self objectForKey:@"lng"] integerValue]/1e6;
    //    CLLocationDegrees n = (CLLocationDegrees)[str integerValue];
    return n;
}

-(NSInteger)bikes
{
    NSInteger n = [[self objectForKey:@"bikes"] integerValue];
    return n;
}

-(NSInteger)free
{
    NSInteger n = [[self objectForKey:@"free"] integerValue];
    return n;
}

-(NSDate *)timestamp
{
    NSString *str = [self objectForKey:@"timestamp"];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'.'SSSSSS"];
    [df setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    NSDate *date = [df dateFromString:str];
    return date;
}

-(bool)installed
{
    bool n = [[self objectForKey:@"installed"] boolValue];
    return n;
}

-(bool)locked
{
    bool n = [[self objectForKey:@"locked"] boolValue];
    return n;
}

@end