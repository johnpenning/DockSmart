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
#import "Station.h"
#import "StationDataController.h"
#import "DockSmartMapViewController.h"

@interface DockSmartDestinationsMasterViewController ()

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
    
//    // KVO: listen for changes to our station data source for map view updates
//    [self addObserver:self forKeyPath:@"stationList" options:0 context:NULL];
}

- (void)viewWillAppear:(BOOL)animated
{
    //TODO: the following line is super dangerous and dumb as implemented.  Please change! (use Notifs?)
    StationDataController *dataController = [self.tabBarController.childViewControllers[0] dataController];
    [dataController setSortedStationList:[dataController sortStationList:[dataController stationList] byMethod:StationDataSortByName]];

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
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
#warning Incomplete method implementation.
    // Return the number of rows in the section.
    
    switch (section) {
        case 0:
            return 0;
            break;
        case 1:
        {
            /* "Stations" section: */
            //TODO: the following line is super dangerous and dumb as implemented.  Please change! (use Notifs?)
            DockSmartMapViewController *controller = self.tabBarController.childViewControllers[0];
            if (controller.class == [DockSmartMapViewController class])
            {
                controller = (DockSmartMapViewController*)controller;
                return [controller.dataController countOfStationList];
            }
            else
            {
                NSLog(@"ERROR: Incorrect class of TabBarController index!");
                return 0;
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
        case 0:
            return @"Favorites";
            break;
        case 1:
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
    
    static NSString *CellIdentifier = @"StationCell";
    DockSmartMapViewController *mapViewController = self.tabBarController.childViewControllers[0];
    
    if (mapViewController.class != [DockSmartMapViewController class])
    {
        NSLog(@"ERROR: Incorrect class of TabBarController index!");
        return nil;
    }
//    static NSDateFormatter *formatter = nil;
//    
//    if (formatter == nil) {
//        formatter = [[NSDateFormatter alloc] init];
//        [formatter setDateStyle:NSDateFormatterMediumStyle];
//    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    Station *stationAtIndex = [mapViewController.dataController objectInSortedStationListAtIndex:indexPath.row];
    
    [[cell textLabel] setText:stationAtIndex.name];
//    [[cell detailTextLabel] setText:[formatter stringFromDate:(NSDate *)sightingAtIndex.date]];

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
        DockSmartMapViewController *mapViewController = self.tabBarController.childViewControllers[0];
        DockSmartStationDetailViewController *detailViewController = [segue destinationViewController];
        detailViewController.station = [mapViewController.dataController objectInSortedStationListAtIndex:[self.tableView indexPathForSelectedRow].row];
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
            self.searchResults = [self.products mutableCopy];
        }
        else
        {
            // If there is no search string and the scope is chosen.
            NSMutableArray *searchResults = [[NSMutableArray alloc] init];
            for (APLProduct *product in self.products)
            {
                if ([product.type isEqualToString:typeName])
                {
                    [searchResults addObject:product];
                }
            }
            self.searchResults = searchResults;
        }
        return;
    }
    
    
    [self.searchResults removeAllObjects]; // First clear the filtered array.
	/*
	 Search the main list for products whose type matches the scope (if selected) and whose name matches searchText; add items that match to the filtered array.
	 */
    for (APLProduct *product in self.products)
	{
		if ((typeName == nil) || [product.type isEqualToString:typeName])
		{
            NSUInteger searchOptions = NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch;
            NSRange productNameRange = NSMakeRange(0, product.name.length);
            NSRange foundRange = [product.name rangeOfString:productName options:searchOptions range:productNameRange];
            if (foundRange.length > 0)
			{
				[self.searchResults addObject:product];
            }
		}
	}
}


#pragma mark - UISearchDisplayController Delegate Methods

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    NSString *scope;
    
    NSInteger selectedScopeButtonIndex = [self.searchDisplayController.searchBar selectedScopeButtonIndex];
    if (selectedScopeButtonIndex > 0)
    {
        scope = [[APLProduct deviceTypeNames] objectAtIndex:(selectedScopeButtonIndex - 1)];
    }
    
    [self updateFilteredContentForProductName:searchString type:scope];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
    NSString *searchString = [self.searchDisplayController.searchBar text];
    NSString *scope;
    
    if (searchOption > 0)
    {
        scope = [[APLProduct deviceTypeNames] objectAtIndex:(searchOption - 1)];
    }
    
    [self updateFilteredContentForProductName:searchString type:scope];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}

@end
