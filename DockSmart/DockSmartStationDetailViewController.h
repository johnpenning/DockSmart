//
//  DockSmartStationDetailViewController.h
//  DockSmart
//
//  NOTE: This file is currently unlinked/unused in the project. For potential future development.
//
//  Created by John Penning on 6/16/13.
//  Copyright (c) 2013 John Penning. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Station;

@interface DockSmartStationDetailViewController : UITableViewController

@property (strong, nonatomic) Station *station;
@property (weak, nonatomic) IBOutlet UILabel *stationLabel;
@property (weak, nonatomic) IBOutlet UILabel *bikesLabel;
@property (weak, nonatomic) IBOutlet UILabel *docksLabel;
@property (weak, nonatomic) IBOutlet UILabel *distanceLabel;
//@property (weak, nonatomic) IBOutlet UINavigationItem *stationDetailNavigationItem;
//@property (weak, nonatomic) IBOutlet UIBarButtonItem *destinationsButton;

@end
