//
//  DockSmartDestinationsMasterViewController.m
//  DockSmart
//
//  Created by John Penning on 6/13/13.
//  Copyright (c) 2013 John Penning. All rights reserved.
//

#import "DockSmartDestinationsMasterViewController.h"
#import "DockSmartAddressDetailViewController.h"
#import "DockSmartStationDetailViewController.h"
#import "MyLocation.h"
#import "Station.h"
#import "Address.h"
#import "LocationDataController.h"
#import "DockSmartMapViewController.h"

@interface DockSmartDestinationsMasterViewController ()

//The station data controller, copied over from the MapView when this view appears.
@property (nonatomic) LocationDataController *dataController;
/*
 The searchResults array contains the content filtered as a result of a search.
 */
@property (nonatomic) NSMutableArray *searchResults;

@end

@implementation DockSmartDestinationsMasterViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    // KVO: listen for changes to our station data source for map view updates
    [self addObserver:self forKeyPath:@"stationList" options:0 context:NULL];

}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    // KVO: listen for changes to our station data source for map view updates
    [self addObserver:self forKeyPath:@"stationList" options:0 context:NULL];
    
    /*
     Create a mutable array to contain products for the search results table.
     */
    self.searchResults = [NSMutableArray arrayWithCapacity:[self.dataController countOfLocationList:self.dataController.stationList]];

}

- (void)viewWillAppear:(BOOL)animated
{
    //TODO: the following line is super dangerous and dumb as implemented.  Please change! (use Notifs?)
    self.dataController = [self.tabBarController.childViewControllers[0] dataController];
    [self.dataController setSortedStationList:[self.dataController sortLocationList:self.dataController.stationList byMethod:LocationDataSortByName]];

    [self.navigationController setNavigationBarHidden:YES animated:animated];
    //deselect the last row selected
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - KVO compliance

// listen for changes to the station list coming from our app delegate.
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    //Reload station data in Destinations list
#warning Ineffective listener.
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
#warning Incomplete method implementation.
    // Return the number of rows in the section.
    
    switch (section) {
        case DestinationTableSectionSearch: //Search cell
            if (tableView == self.searchDisplayController.searchResultsTableView)
            {
                if ([[self.searchResults objectAtIndex:0] isMemberOfClass:[MyLocation class]])
                {
                    return 1;
                }
                return 0;
            }
            break;
        case DestinationTableSectionFavorites: //Favorites
            return 0;
            break;
        case DestinationTableSectionRecents: //Recents
            return 0;
            break;
        case DestinationTableSectionStations:
        {
            /* "Stations" section: */
//            //TODO: the following line is super dangerous and dumb as implemented.  Please change! (use Notifs?)
//            DockSmartMapViewController *controller = self.tabBarController.childViewControllers[0];
//            if (controller.class == [DockSmartMapViewController class])
//            {
//                controller = (DockSmartMapViewController*)controller;
//                return [controller.dataController countOfStationList];
//            }
//            else
//            {
//                NSLog(@"ERROR: Incorrect class of TabBarController index!");
//                return 0;
//            }
            
            /*
             If the requesting table view is the search display controller's table view, return the count of
             the filtered list, otherwise return the count of the main list.
             */
            if (tableView == self.searchDisplayController.searchResultsTableView)
            {
                return [self.searchResults count] == 0 ? 0 : ([self.searchResults count] - 1); //TODO change constant arithmetic to dynamic object type counting when other sections come into play
            }
            else
            {
                return [self.dataController countOfLocationList:self.dataController.sortedStationList];
            }
        }
            break;
            
        default:
            break;
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    //Return the title of each section.
    
    if (![self tableView:tableView numberOfRowsInSection:section])
        return nil; //Do not put a section header on a section with no rows
    
    switch (section) {
        case DestinationTableSectionSearch: //Search cell
            return @"Search for...";
            break;
        case DestinationTableSectionFavorites:
            return @"Favorites";
            break;
        case DestinationTableSectionRecents:
            return @"Recents";
            break;
        case DestinationTableSectionStations:
            return @"Stations";
            break;
        default:
            break;
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
//    static NSString *CellIdentifier = @"Cell";
//    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    
    static NSString *CellIdentifier;
    
//    if ((tableView == self.searchDisplayController.searchResultsTableView) && ([[self.searchResults objectAtIndex:0] isMemberOfClass:[MyLocation class]]) && (indexPath.row == 0))
//    {
//        CellIdentifier = @"SearchCell";
//    }
//    else
//    {
//        CellIdentifier = @"StationCell";
//    }
    
    switch ([indexPath section]) {
        case DestinationTableSectionSearch:
            CellIdentifier = @"SearchCell";
            break;
        case DestinationTableSectionFavorites:
            break;
        case DestinationTableSectionRecents:
            break;
        case DestinationTableSectionStations:
            CellIdentifier = @"StationCell";
            break;
        default:
            break;
    }
    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    MyLocation *locationAtIndex;
    
    if (tableView == self.searchDisplayController.searchResultsTableView)
	{
        switch ([indexPath section]) {
            case DestinationTableSectionSearch:
                locationAtIndex = [self.searchResults objectAtIndex:indexPath.row];
                break;
            case DestinationTableSectionFavorites:
                //TODO
                break;
            case DestinationTableSectionRecents:
                break;
            case DestinationTableSectionStations:
                locationAtIndex = [self.searchResults objectAtIndex:(indexPath.row+1)]; //TODO change constant arithmetic to dynamic object type counting when other sections come into play
                break;
            default:
                break;
        }
    }
	else
	{
        locationAtIndex = (Station*)[self.dataController objectInLocationList:self.dataController.sortedStationList atIndex:indexPath.row]; //[mapViewController.dataController objectInSortedStationListAtIndex:indexPath.row];
    }
    
    //Set main text label:
    if ([CellIdentifier isEqualToString:@"SearchCell"])
    {
        [[cell textLabel] setText:[NSString stringWithFormat:@"\"%@\"", locationAtIndex.name]];
    }
    else
        [[cell textLabel] setText:locationAtIndex.name];
    
    //Set detail text label if applicable:
    if ([locationAtIndex isKindOfClass:[Station class]])
    {
        Station *stationAtIndex = (Station *)locationAtIndex;
        [[cell detailTextLabel] setText:[NSString stringWithFormat:@"Bikes: %d Docks: %d Distance: 99.99 mi", stationAtIndex.nbBikes, stationAtIndex.nbEmptyDocks /*, TODO insert stationAtIndex.distance later*/]];
    }
    else if ([locationAtIndex isKindOfClass:[Address class]])
    {
//        Address *addressAtIndex = (Address *)locationAtIndex;
        [[cell detailTextLabel] setText:[NSString stringWithFormat:@"Distance: 99.99 mi" /* TODO insert stationAtIndex.distance later*/]];
    }
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"DestinationsToStationDetail"]) {
//        DockSmartMapViewController *mapViewController = self.tabBarController.childViewControllers[0];
        DockSmartStationDetailViewController *detailViewController = [segue destinationViewController];
        detailViewController.station = (Station *)[self.dataController objectInLocationList:self.dataController.sortedStationList atIndex:[self.tableView indexPathForSelectedRow].row];
    }
}

/* Search Bar Implementation - Pilfered & tweaked from Apple's TableSearch example project */

#pragma mark - Content Filtering

- (void)updateFilteredContentForLocationName:(NSString *)locationName type:(NSString *)typeName
{
	/*
	 Update the filtered array based on the search text and scope.
	 */
    if ((locationName == nil) || [locationName length] == 0)
    {
        // If there is no search string and the scope is "All".
        if (typeName == nil)
        {
            self.searchResults = [self.dataController.sortedStationList mutableCopy];
        }
        else
        {
            // If there is no search string and the scope is chosen.
            NSMutableArray *searchResults = [[NSMutableArray alloc] init];
            for (Station *station in self.dataController.sortedStationList)
            {
//                if ([product.type isEqualToString:typeName])
//                {
                    [searchResults addObject:station];
//                }
            }
            self.searchResults = searchResults;
        }
        return;
    }
    
    
    [self.searchResults removeAllObjects]; // First clear the filtered array.
    
    /* Add a search row at the top, to begin a geocode for the input address.
       Since this does not have coordinates yet, initialize this simply as a MyLocation object
       instead of an Address.
     */
    MyLocation *newSearchAddress = [[MyLocation alloc] initWithName:locationName latitude:0 longitude:0];
    [self.searchResults addObject:newSearchAddress];
    
	/*
	 Search the main list for locations whose type matches the scope (if selected) and whose name matches searchText; add items that match to the filtered array.
	 */
    for (Station *station in self.dataController.sortedStationList)
	{
//		if ((typeName == nil) || [product.type isEqualToString:typeName])
//		{
            NSUInteger searchOptions = NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch;
            NSRange stationNameRange = NSMakeRange(0, station.name.length);
            NSRange foundRange = [station.name rangeOfString:locationName options:searchOptions range:stationNameRange];
            if (foundRange.length > 0)
			{
				[self.searchResults addObject:station];
            }
//		}
	}
    
}


#pragma mark - UISearchDisplayController Delegate Methods

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    NSString *scope = nil;
    
//    NSInteger selectedScopeButtonIndex = [self.searchDisplayController.searchBar selectedScopeButtonIndex];
//    if (selectedScopeButtonIndex > 0)
//    {
//        scope = [[APLProduct deviceTypeNames] objectAtIndex:(selectedScopeButtonIndex - 1)];
//    }
    
    [self updateFilteredContentForLocationName:searchString type:scope];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
    NSString *searchString = [self.searchDisplayController.searchBar text];
    NSString *scope;
    
//    if (searchOption > 0)
//    {
//        scope = [[APLProduct deviceTypeNames] objectAtIndex:(searchOption - 1)];
//    }
    
    [self updateFilteredContentForLocationName:searchString type:scope];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}

@end
