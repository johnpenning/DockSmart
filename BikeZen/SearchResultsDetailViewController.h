//
//  SearchResultsDetailViewController.h
//  DockSmart
//
//  Created by John Penning on 6/26/13.
//  Copyright (c) 2013 John Penning. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LocationDataController;

@interface SearchResultsDetailViewController : UITableViewController

//The station data controller, copied over from the MapView when this view appears.
@property (nonatomic) LocationDataController *dataController;

@end
