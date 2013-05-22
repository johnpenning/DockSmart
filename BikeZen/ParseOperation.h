//
//  ParseOperation.h
//  BikeZen
//
//  Created by John Penning on 5/5/13.
//  Copyright (c) 2013 John Penning. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *kAddStationsNotif;
extern NSString *kStationResultsKey;
extern NSString *kStationErrorNotif;
extern NSString *kStationsMsgErrorKey;

@class Station;

@interface ParseOperation : NSOperation

@property (copy, readonly) NSData *stationXMLData;
@property NSDateFormatter *dateFormatter;

////variables used during parsing:
//@property Station *currentStationObject;
//@property NSMutableArray *currentParseBatch;
//@property NSMutableString *currentParsedCharacterData;

@property bool accumulatingParsedCharacterData;
@property bool didAbortParsing;
@property NSUInteger parsedStationsCounter;

@end
