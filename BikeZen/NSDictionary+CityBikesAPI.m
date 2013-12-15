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
    NSString *str = [self objectForKey:@"id"];
    NSInteger n = [str integerValue];
    return n;
}

-(NSString *)name
{
    return [self objectForKey:@"name"];
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
    
}

-(NSInteger)free
{
    
}

-(NSDate *)timestamp
{
    
}

-(bool)installed
{
    
}

-(bool)locked
{
    
}

-(NSNumber *)cloudCover{
    NSString *cc = [self objectForKey:@"cloudcover"];
    NSNumber *n = [NSNumber numberWithInt:[cc intValue]];
    return n;
}

-(NSNumber *)humidity{
    NSString *cc = [self objectForKey:@"humidity"];
    NSNumber *n = [NSNumber numberWithInt:[cc intValue]];
    return n;
}

-(NSDate *)observationTime{
    // NSString *cc = [[self currentWeather] objectForKey:@"observation_time"];
    NSDate *n = [NSDate date];//parse instead "09:07 PM";
    return n;
}

-(NSNumber *)precipMM{
    NSString *cc = [self objectForKey:@"precipMM"];
    NSNumber *n = [NSNumber numberWithInt:[cc floatValue]];
    return n;
}

-(NSNumber *)pressue{
    NSString *cc = [self objectForKey:@"pressure"];
    NSNumber *n = [NSNumber numberWithInt:[cc floatValue]];
    return n;
}

-(NSNumber *)tempC{
    NSString *cc = [self objectForKey:@"temp_C"];
    NSNumber *n = [NSNumber numberWithInt:[cc floatValue]];
    return n;
}

-(NSNumber *)tempF{
    NSString *cc = [self objectForKey:@"temp_F"];
    NSNumber *n = [NSNumber numberWithInt:[cc floatValue]];
    return n;
}

-(NSNumber *)visibility{
    NSString *cc = [self objectForKey:@"visibility"];
    NSNumber *n = [NSNumber numberWithInt:[cc floatValue]];
    return n;
}

-(NSNumber *)weatherCode{
    NSString *cc = [self objectForKey:@"weatherCode"];
    NSNumber *n = [NSNumber numberWithInt:[cc floatValue]];
    return n;
}

-(NSString *)windDir16Point{
    return [self objectForKey:@"winddir16Point"];
}

-(NSNumber *)windDirDegree{
    NSString *cc = [self objectForKey:@"winddirDegree"];
    NSNumber *n = [NSNumber numberWithInt:[cc floatValue]];
    return n;
}

-(NSNumber *)windSpeedKmph{
    NSString *cc = [self objectForKey:@"windspeedKmph"];
    NSNumber *n = [NSNumber numberWithInt:[cc floatValue]];
    return n;
}

-(NSNumber *)windSpeedMiles{
    NSString *cc = [self objectForKey:@"windspeedMiles"];
    NSNumber *n = [NSNumber numberWithInt:[cc floatValue]];
    return n;
}

-(NSString *)weatherDescription{
    NSArray *ar = [self objectForKey:@"weatherDesc"];
    NSDictionary *dict = [ar objectAtIndex:0];
    return [dict objectForKey:@"value"];
}

-(NSString *)weatherIconURL{
    NSArray *ar = [self objectForKey:@"weatherIconUrl"];
    NSDictionary *dict = [ar objectAtIndex:0];
    return [dict objectForKey:@"value"];
}

-(NSDate *)date{
    // NSString *dateStr = [self objectForKey:@"date"];//date = "2013-01-15";
    return [NSDate date];
}


-(NSNumber *)tempMaxC{
    NSString *cc = [self objectForKey:@"tempMaxC"];
    NSNumber *n = [NSNumber numberWithInt:[cc intValue]];
    return n;
}

-(NSNumber *)tempMaxF{
    NSString *cc = [self objectForKey:@"tempMaxF"];
    NSNumber *n = [NSNumber numberWithInt:[cc intValue]];
    return n;
}

-(NSNumber *)tempMinC{
    NSString *cc = [self objectForKey:@"tempMinC"];
    NSNumber *n = [NSNumber numberWithInt:[cc intValue]];
    return n;
}

-(NSNumber *)tempMinF{
    NSString *cc = [self objectForKey:@"tempMinF"];
    NSNumber *n = [NSNumber numberWithInt:[cc intValue]];
    return n;
}


@end
