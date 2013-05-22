//
//  Station.h
//  BikeZen
//
//  Created by John Penning on 5/5/13.
//  Copyright (c) 2013 John Penning. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

/* STATION OBJECT
    Station data is reported in this format:
 
 <station>
 <id>1</id>
 <name>20th & Bell St</name>
 <terminalName>31000</terminalName>
 <lastCommWithServer>1367777618441</lastCommWithServer>
 <lat>38.8561</lat>
 <long>-77.0512</long>
 <installed>true</installed>
 <locked>false</locked>
 <installDate>1316059200000</installDate>
 <removalDate/>
 <temporary>false</temporary>
 <public>true</public>
 <nbBikes>7</nbBikes>
 <nbEmptyDocks>4</nbEmptyDocks>
 <latestUpdateTime>1367763465290</latestUpdateTime>
 </station>

 The data we care about is declared in the Station object and parsed appropriately.
 */

@interface Station : NSObject <MKAnnotation>

//{
//@private
//    NSInteger stationId;
//    NSString *name;
//    CLLocationCoordinate2D *location;
//    bool installed;
//    bool locked;
//    bool public;
//    NSInteger nbBikes;
//    NSInteger nbEmptyDocks;
//    NSDate *lastStationUpdate;
//}

/* TODO: Make these nonatomic?? */
@property (nonatomic) NSInteger stationID;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic) CLLocationDegrees latitude;
@property (nonatomic) CLLocationDegrees longitude;
@property (nonatomic) bool installed;
@property (nonatomic) bool locked;
@property (nonatomic) bool publiclyViewable;
@property NSInteger nbBikes;
@property NSInteger nbEmptyDocks;
@property (nonatomic, copy) NSDate *lastStationUpdate;

- (id)initWithStationID:(NSInteger)stationID name:(NSString*)name latitude:(CLLocationDegrees)latitude longitude:(CLLocationDegrees)longitude installed:(bool)installed locked:(bool)locked publiclyViewable:(bool)publiclyViewable nbBikes:(NSInteger)nbBikes nbEmptyDocks:(NSInteger)nbEmptyDocks lastStationUpdate:(NSDate *)lastStationUpdate;

- (void)initCoordinateWithLatitude:(CLLocationDegrees)latitude longitude:(CLLocationDegrees)longitude;

//- (MKMapItem*) mapItem;

@end
