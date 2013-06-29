//
//  DockSmartDestinationsMasterViewController.h
//  DockSmart
//
//  Created by John Penning on 6/13/13.
//  Copyright (c) 2013 John Penning. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, DestinationTableSectionNumber) {
    DestinationTableSectionSearch = 0,
    DestinationTableSectionSearchResults,
    DestinationTableSectionFavorites,
    DestinationTableSectionRecents,
    DestinationTableSectionStations,
};

@interface DockSmartDestinationsMasterViewController : UITableViewController <UITableViewDelegate, UITableViewDataSource, UISearchDisplayDelegate, UISearchBarDelegate>

@end
