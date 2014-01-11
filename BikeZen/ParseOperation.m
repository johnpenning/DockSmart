//
//  ParseOperation.m
//  DockSmart
//
//  Created by John Penning on 5/5/13.
//  Copyright (c) 2013 John Penning. All rights reserved.
//

/* CODE MODIFIED FROM:
 File: ParseOperation.m
 Abstract: The NSOperation class used to perform the XML parsing of earthquake data.
 Version: 2.3
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2010 Apple Inc. All Rights Reserved.
 
 */


#import "ParseOperation.h"
#import "Station.h"
#import "DockSmartAppDelegate.h"

// NSNotification name for sending station data to the map view
NSString *kAddStationsNotif = @"AddStationsNotif";

// NSNotification userInfo key for obtaining the earthquake data
NSString *kStationResultsKey = @"StationResultsKey";

// NSNotification name for reporting errors
NSString *kStationErrorNotif = @"StationErrorNotif";

// NSNotification userInfo key for obtaining the error message
NSString *kStationsMsgErrorKey = @"StationsMsgErrorKey";


@interface ParseOperation () <NSXMLParserDelegate>

//variables used during parsing:
@property Station *currentStationObject;
@property NSMutableArray *currentParseBatch;
@property NSMutableString *currentParsedCharacterData;

@end

@implementation ParseOperation


- (id)initWithData:(NSData *)parseData
{
    if (self = [super init]) {
        _stationXMLData = [parseData copy];
        
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        [self.dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"] ];
        [self.dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
    }
    return self;
}

- (void)addStationsToList:(NSArray *)stations {
//    assert([NSThread isMainThread]);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kAddStationsNotif
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:stations
                                                                                           forKey:kStationResultsKey]];
}

// the main function for this NSOperation, to start the parsing
- (void)main {
    self.currentParseBatch = [NSMutableArray array];
    self.currentParsedCharacterData = [NSMutableString string];
    
    //Start spinning the network activity indicator:
    [(DockSmartAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:YES];
    
    // It's also possible to have NSXMLParser download the data, by passing it a URL, but this is
    // not desirable because it gives less control over the network, particularly in responding to
    // connection errors.
    //
    // Trying it anyway:
    // TODO: test this versus NSURLConnection method
    static NSString *feedURLString = @"http://www.capitalbikeshare.com/data/stations/bikeStations.xml";
    NSXMLParser *parser = [[NSXMLParser alloc] initWithContentsOfURL:[NSURL URLWithString:feedURLString]];
    [parser setDelegate:self];
    [parser parse];
    
    // depending on the total number of earthquakes parsed, the last batch might not have been a
    // "full" batch, and thus not been part of the regular batch transfer. So, we check the count of
    // the array and, if necessary, send it to the main thread.
    //
    if ([self.currentParseBatch count] > 0) {
        [self performSelectorOnMainThread:@selector(addStationsToList:)
                               withObject:self.currentParseBatch
                            waitUntilDone:NO];
//        [self addStationsToList:self.currentParseBatch];
    }
    
    //Stop spinning the network activity indicator:
    [(DockSmartAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO];
    
    self.currentParseBatch = nil;
    self.currentStationObject = nil;
    self.currentParsedCharacterData = nil;
    
}


#pragma mark -
#pragma mark Parser constants

// Limit the number of parsed earthquakes to 50
// (a given day may have more than 50 earthquakes around the world, so we only take the first 50)
//
static const NSUInteger kMaximumNumberOfStationsToParse = 2000; //TODO: optimize this number

// When an Earthquake object has been fully constructed, it must be passed to the main thread and
// the table view in RootViewController must be reloaded to display it. It is not efficient to do
// this for every Earthquake object - the overhead in communicating between the threads and reloading
// the table exceed the benefit to the user. Instead, we pass the objects in batches, sized by the
// constant below. In your application, the optimal batch size will vary
// depending on the amount of data in the object and other factors, as appropriate.
//
static NSUInteger const kSizeOfStationBatch = 10;

// Reduce potential parsing errors by using string constants declared in a single place.
static NSString * const kStationElementName = @"station";
static NSString * const kIDElementName = @"id";
static NSString * const kNameElementName = @"name";
static NSString * const kLatElementName = @"lat";
static NSString * const kLongElementName = @"long";
static NSString * const kInstalledElementName = @"installed";
static NSString * const kLockedElementName = @"locked";
static NSString * const kPublicElementName = @"public";
static NSString * const kNbBikesElementName = @"nbBikes";
static NSString * const kNbEmptyDocksElementName = @"nbEmptyDocks";
static NSString * const kLastStationUpdateElementName = @"latestUpdateTime";


#pragma mark -
#pragma mark NSXMLParser delegate methods

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName
    attributes:(NSDictionary *)attributeDict {
    // If the number of parsed earthquakes is greater than
    // kMaximumNumberOfEarthquakesToParse, abort the parse.
    //
    if (self.parsedStationsCounter >= kMaximumNumberOfStationsToParse)
    {
        // Use the flag didAbortParsing to distinguish between this deliberate stop
        // and other parser errors.
        //
        self.didAbortParsing = YES;
        [parser abortParsing];
    }
    if ([elementName isEqualToString:kStationElementName])
    {
        Station *tempStation = [[Station alloc] init];
        self.currentStationObject = tempStation;
    }
    else if ([elementName isEqualToString:kIDElementName] ||
               [elementName isEqualToString:kNameElementName] ||
               [elementName isEqualToString:kLatElementName] ||
               [elementName isEqualToString:kLongElementName] ||
               [elementName isEqualToString:kInstalledElementName] ||
               [elementName isEqualToString:kLockedElementName] ||
               [elementName isEqualToString:kPublicElementName] ||
               [elementName isEqualToString:kNbBikesElementName] ||
               [elementName isEqualToString:kNbEmptyDocksElementName] ||
               [elementName isEqualToString:kLastStationUpdateElementName] )
    {
        // For the other data elements within each station that we are interested in, begin accumulating parsed character data.
        // The contents are collected in parser:foundCharacters:.
        self.accumulatingParsedCharacterData = YES;
        // The mutable string needs to be reset to empty.
        [self.currentParsedCharacterData setString:@""];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName {
    if ([elementName isEqualToString:kStationElementName])
    {
        [self.currentStationObject initCoordinateWithLatitude:self.currentStationObject.latitude longitude:self.currentStationObject.longitude];
        [self.currentParseBatch addObject:self.currentStationObject];
        self.parsedStationsCounter++;
        if ([self.currentParseBatch count] >= kMaximumNumberOfStationsToParse) {
            [self performSelectorOnMainThread:@selector(addStationsToList:)
                                   withObject:self.currentParseBatch
                                waitUntilDone:NO];
//            [self addStationsToList:self.currentParseBatch];
            self.currentParseBatch = [NSMutableArray array];
        }
    }
    else if ([elementName isEqualToString:kIDElementName])
    {
        NSScanner *scanner = [NSScanner scannerWithString:self.currentParsedCharacterData];
        NSInteger stationID;
        if ([scanner scanInteger:&stationID]) {
            self.currentStationObject.stationID = stationID;
        }
    }
    else if ([elementName isEqualToString:kNameElementName])
    {
        NSScanner *scanner = [NSScanner scannerWithString:self.currentParsedCharacterData];
        NSString *name;
        if ([scanner scanUpToCharactersFromSet:[NSCharacterSet illegalCharacterSet] intoString:&name])
            self.currentStationObject.name = name;
    }
    else if ([elementName isEqualToString:kLatElementName])
    {
        NSScanner *scanner = [NSScanner scannerWithString:self.currentParsedCharacterData];
        double latitude;
        if ([scanner scanDouble:&latitude])
            self.currentStationObject.latitude = latitude;
    }
    else if ([elementName isEqualToString:kLongElementName])
    {
        NSScanner *scanner = [NSScanner scannerWithString:self.currentParsedCharacterData];
        double longitude;
        if ([scanner scanDouble:&longitude])
            self.currentStationObject.longitude = longitude;
    }
    else if ([elementName isEqualToString:kInstalledElementName])
    {
        NSScanner *scanner = [NSScanner scannerWithString:self.currentParsedCharacterData];
        bool installed;
        if ([scanner scanInteger:(NSInteger*)&installed]) {
            self.currentStationObject.installed = installed;
        }
    }
    else if ([elementName isEqualToString:kLockedElementName])
    {
        NSScanner *scanner = [NSScanner scannerWithString:self.currentParsedCharacterData];
        bool locked;
        if ([scanner scanInteger:(NSInteger*)&locked]) {
            self.currentStationObject.locked = locked;
        }
    }
    else if ([elementName isEqualToString:kPublicElementName])
    {
        NSScanner *scanner = [NSScanner scannerWithString:self.currentParsedCharacterData];
        bool publiclyViewable;
        if ([scanner scanInteger:(NSInteger*)&publiclyViewable]) {
            self.currentStationObject.publiclyViewable = publiclyViewable;
        }
    }
    else if ([elementName isEqualToString:kNbBikesElementName])
    {
        NSScanner *scanner = [NSScanner scannerWithString:self.currentParsedCharacterData];
        NSInteger nbBikes;
        if ([scanner scanInteger:&nbBikes]) {
            self.currentStationObject.nbBikes = nbBikes;
        }
    }
    else if ([elementName isEqualToString:kNbEmptyDocksElementName])
    {
        NSScanner *scanner = [NSScanner scannerWithString:self.currentParsedCharacterData];
        NSInteger nbEmptyDocks;
        if ([scanner scanInteger:&nbEmptyDocks]) {
            self.currentStationObject.nbEmptyDocks = nbEmptyDocks;
        }
    }
    else if ([elementName isEqualToString:kLastStationUpdateElementName])
    {
        if (self.currentStationObject != nil) {
            self.currentStationObject.lastStationUpdate =
            [self.dateFormatter dateFromString:self.currentParsedCharacterData];
        }
    }
//    else if ([elementName isEqualToString:kUpdatedElementName])
//    {
////        if (self.currentStationObject != nil) {
////            self.currentStationObject.date =
////            [self.dateFormatter dateFromString:self.currentParsedCharacterData];
////        }
////        else {
////            // kUpdatedElementName can be found outside an entry element (i.e. in the XML header)
////            // so don't process it here.
////        }
//    }
//    else if ([elementName isEqualToString:kGeoRSSPointElementName])
//    {
//        // The georss:point element contains the latitude and longitude of the earthquake epicenter.
//        // 18.6477 -66.7452
//        //
////        NSScanner *scanner = [NSScanner scannerWithString:self.currentParsedCharacterData];
////        double latitude, longitude;
////        if ([scanner scanDouble:&latitude]) {
////            if ([scanner scanDouble:&longitude]) {
////                self.currentStationObject.latitude = latitude;
////                self.currentStationObject.longitude = longitude;
////            }
////        }
//    }
    // Stop accumulating parsed character data. We won't start again until specific elements begin.
    self.accumulatingParsedCharacterData = NO;
}

// This method is called by the parser when it find parsed character data ("PCDATA") in an element.
// The parser is not guaranteed to deliver all of the parsed character data for an element in a single
// invocation, so it is necessary to accumulate character data until the end of the element is reached.
//
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    if (self.accumulatingParsedCharacterData) {
        // If the current element is one whose content we care about, append 'string'
        // to the property that holds the content of the current element.
        //
        [self.currentParsedCharacterData appendString:string];
    }
}

// an error occurred while parsing the earthquake data,
// post the error as an NSNotification to our app delegate.
//
- (void)handleStationsError:(NSError *)parseError {
    [[NSNotificationCenter defaultCenter] postNotificationName:kStationErrorNotif
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:parseError
                                                                                           forKey:kStationsMsgErrorKey]];
}

// an error occurred while parsing the earthquake data,
// pass the error to the main thread for handling.
// (note: don't report an error if we aborted the parse due to a max limit of earthquakes)
//
- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    if ([parseError code] != NSXMLParserDelegateAbortedParseError && !(self.didAbortParsing))
    {
        [self performSelectorOnMainThread:@selector(handleStationsError:)
                               withObject:parseError
                            waitUntilDone:NO];
//        [self handleStationsError:parseError];
    }
}

@end
