//
//  DockSmartDestinationsMasterViewController.h
//  DockSmart
//
//  Created by John Penning on 6/13/13.
//  Copyright (c) 2013 John Penning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LocationController.h"

//Sections that are used in the table view.
typedef NS_ENUM(NSInteger, DestinationTableSectionNumber) {
    DestinationTableSectionSearch = 0,
    DestinationTableSectionSearchResults,
    DestinationTableSectionFavorites,
    DestinationTableSectionRecents,
    DestinationTableSectionStations,
};

// NSNotification name for informing the map view that we want to bike to a destination
extern NSString * const kStartBikingNotif;
// NSNotification userInfo for the MyLocation object to bike to
extern NSString * const kBikeDestinationKey;

@interface DockSmartDestinationsMasterViewController : UITableViewController <UITableViewDelegate, UITableViewDataSource, UISearchDisplayDelegate, UISearchBarDelegate, UIActionSheetDelegate>

@end
