//
//  MyLocation.h
//  DockSmart
//
//  Created by John Penning on 5/1/13.
//  Copyright (c) 2013 John Penning. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "DockSmartSettingsViewController.h"

// Reuse identifiers for MyLocation annotations in the MapView
extern NSString *kSourceStation;
extern NSString *kDestinationLocation;
extern NSString *kDestinationStation;
extern NSString *kAlternateStation;
extern NSString *kStation;

@interface MyLocation : NSObject <MKAnnotation, UIStateRestoring>

@property (nonatomic, copy) NSString *name;
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
//@property (nonatomic) CLLocationDegrees latitude;
//@property (nonatomic) CLLocationDegrees longitude;
@property (nonatomic) CLLocationDistance distanceFromUser;
@property (nonatomic, copy) NSString *annotationIdentifier;
//State restoration:
@property (strong, nonatomic) Class<UIObjectRestoration> objectRestorationClass;
@property (strong, nonatomic) id<UIStateRestoring> restorationParent;

- (id)initWithName:(NSString *)name latitude:(CLLocationDegrees)latitude longitude:(CLLocationDegrees)longitude distanceFromUser:(CLLocationDistance)distance;
- (id)initWithName:(NSString *)name coordinate:(CLLocationCoordinate2D)coordinate distanceFromUser:(CLLocationDistance)distance;
- (void)initCoordinateWithLatitude:(CLLocationDegrees)latitude longitude:(CLLocationDegrees)longitude;

@end

//@interface DestinationLocation : MyLocation <MKAnnotation>
//
//@end
