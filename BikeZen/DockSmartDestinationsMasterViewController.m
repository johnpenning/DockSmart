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
#import "SearchResultsDetailViewController.h"
#import "MyLocation.h"
#import "Station.h"
#import "Address.h"
#import "LocationDataController.h"
#import "DockSmartMapViewController.h"
#import "ParseOperation.h"
#import "MBProgressHUD.h"
#import "define.h"


// NSNotification name for informing the map view that we want to bike to a destination
NSString *kStartBikingNotif = @"StartBikingNotif";

// NSNotification userInfo for the MyLocation object to bike to
NSString *kBikeDestinationKey = @"BikeDestinationKey";


@interface DockSmartDestinationsMasterViewController ()

//The station data controller, copied over from the MapView when this view appears.
@property (nonatomic) LocationDataController *dataController;
/*
 The searchResults array contains the content filtered as a result of a search.
 */
@property (nonatomic) MyLocation *searchLocation;
@property (nonatomic) MyLocation *selectedLocation;
@property (nonatomic) NSMutableArray *filterResults;
@property (nonatomic) NSMutableArray *geocodeSearchResults;
//@property (nonatomic) NSUInteger geocodeSearchResultsCount;
@property (nonatomic) CLLocationCoordinate2D userCoordinate;
@property (nonatomic, readwrite) UIActionSheet *navSheet;

- (void)performStringGeocode:(NSString *)string;
- (void)showNavigateActions:(NSString *)title;

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

    //initialize local userCoordinate property:
    self.userCoordinate = CLLocationCoordinate2DMake(0, 0);
    
    // KVO: listen for changes to our station data source for table view updates
//    [self addObserver:self forKeyPath:kStationList options:0 context:NULL];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(addStations:)
                                                 name:kAddStationsNotif
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateLocation:)
                                                 name:kLocationUpdateNotif
                                               object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    // KVO: listen for changes to our station data source for map view updates
    [self addObserver:self forKeyPath:kStationList options:0 context:NULL];
    
    /*
     Create a mutable array to contain products for the search results table.
     */
    self.filterResults = [NSMutableArray arrayWithCapacity:[self.dataController countOfLocationList:self.dataController.stationList]];
    //Create geocode search results mutable array.
    self.geocodeSearchResults = [[NSMutableArray alloc] init];
    self.selectedLocation = [[MyLocation alloc] init];
}

- (void)viewWillAppear:(BOOL)animated
{
    //TODO: the following line is perhaps not so super dangerous and dumb as implemented?  Keeps us from having to store twice as many lists...
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

- (void)updateLocation:(NSNotification *)notif {
    assert([NSThread isMainThread]);
    
    self.userCoordinate = [(CLLocation *)[[notif userInfo] valueForKey:kNewLocationKey] coordinate];
//    [self updateDistancesFromUserLocation:[[notif userInfo] valueForKey:kNewLocationKey]];
}

- (void)addStations:(NSNotification *)notif {
    assert([NSThread isMainThread]);
    
    //This notification came from the parse operation telling us that a new station list has been posted.
    //Use KVO to tell this view controller to resort the list and update the tableView.
    [self willChangeValueForKey:kStationList];
    [self didChangeValueForKey:kStationList];
}

// listen for changes to the station list coming from our app delegate.
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    //Reload station data in Destinations list
#warning Ineffective listener.
    [self.dataController setSortedStationList:[self.dataController sortLocationList:self.dataController.stationList byMethod:LocationDataSortByName]];
    [self.tableView reloadData];
    //TODO: reperform search
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
#warning Incomplete method implementation.
    // Return the number of rows in the section.
    
    switch (section) {
        case DestinationTableSectionSearch: //Search cell
            if (tableView == self.searchDisplayController.searchResultsTableView)
            {
//                if ([[self.filterResults objectAtIndex:0] isMemberOfClass:[MyLocation class]])
//                {
//                    return 1;
//                }
//                return 0;
                if (self.searchLocation == nil)
                    return 0;
                else
                    return 1;
            }
            return 0;
            break;
        case DestinationTableSectionSearchResults:
            if (tableView == self.searchDisplayController.searchResultsTableView)
            {
                return [self.geocodeSearchResults count];
            }
            return 0;
            break;
        case DestinationTableSectionFavorites: //Favorites TODO
            return 0;
            break;
        case DestinationTableSectionRecents: //Recents TODO
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
//                NSInteger numRows = [self.filterResults count]; //start with the full array
//                
//                //just return 0 if the array is empty
//                if (numRows == 0)
//                    return 0;
//                
//                //if the first result is a SearchCell (i.e. a geocode prompt), subtract 1
//                if ([[self.filterResults objectAtIndex:0] isMemberOfClass:[MyLocation class]])
//                    numRows--;
//                
//                //subtract each of the previous geocode search results, with a sanity check:
//                if (numRows >= self.geocodeSearchResultsCount)
//                    numRows -= self.geocodeSearchResultsCount;
//                
//                return numRows; //[self.filterResults count] == 0 ? 0 : ([self.filterResults count] - 1); //TODO change constant arithmetic to dynamic object type counting when other sections come into play
                
                return [self.filterResults count];
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
        case DestinationTableSectionSearchResults:
            return @"Addresses";
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
    
//    if ((tableView == self.searchDisplayController.searchResultsTableView) && ([[self.filterResults objectAtIndex:0] isMemberOfClass:[MyLocation class]]) && (indexPath.row == 0))
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
        case DestinationTableSectionSearchResults:
            CellIdentifier = @"AddressCell";
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
//                locationAtIndex = [self.filterResults objectAtIndex:indexPath.row];
                if (self.searchLocation != nil)
                {
                    locationAtIndex = self.searchLocation;
                }
                break;
            case DestinationTableSectionSearchResults:
//                if ([[self.filterResults objectAtIndex:0] isMemberOfClass:[MyLocation class]])
//                    locationAtIndex = [self.filterResults objectAtIndex:(indexPath.row+1)];
//                else
//                    locationAtIndex = [self.filterResults objectAtIndex:indexPath.row];
                locationAtIndex = [self.geocodeSearchResults objectAtIndex:indexPath.row];
                break;
            case DestinationTableSectionFavorites:
                //TODO
                break;
            case DestinationTableSectionRecents:
                //TODO
                break;
            case DestinationTableSectionStations:
//                if ([[self.filterResults objectAtIndex:0] isMemberOfClass:[MyLocation class]])
//                    locationAtIndex = [self.filterResults objectAtIndex:(indexPath.row + self.geocodeSearchResultsCount + 1)]; //TODO change constant arithmetic to dynamic object type counting when other sections come into play
//                else
//                    locationAtIndex = [self.filterResults objectAtIndex:(indexPath.row + self.geocodeSearchResultsCount)];
                locationAtIndex = [self.filterResults objectAtIndex:indexPath.row];
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
        [[cell detailTextLabel] setText:[NSString stringWithFormat:@"Bikes: %d Docks: %d Distance: %2.2f mi", stationAtIndex.nbBikes, stationAtIndex.nbEmptyDocks, stationAtIndex.distanceFromUser/METERS_PER_MILE /*, TODO insert stationAtIndex.distance later*/]];
    }
    else if ([locationAtIndex isKindOfClass:[Address class]])
    {
        //show the same info as the map callout subtitle (ideally a neighborhood name, plus the distance from the current location):
        Address *addressAtIndex = (Address *)locationAtIndex;
        [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%@", [addressAtIndex subtitle]]];
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
    //Ether start a geocode search or open an action sheet to navigate to a destination.
    switch ([indexPath section]) {
        case DestinationTableSectionSearch:
            if ([indexPath row] == 0)
            {
                // perform the Geocode
                [self performStringGeocode:self.searchLocation.name];
            }
            break;
        case DestinationTableSectionSearchResults:
        {
            self.selectedLocation = (MyLocation*)[[self geocodeSearchResults] objectAtIndex:[indexPath row]];
            [self showNavigateActions:self.selectedLocation.name];
            break;
        }
        case DestinationTableSectionFavorites: //TODO
        {
            self.selectedLocation = (MyLocation*)[[[self dataController] favoritesList] objectAtIndex:[indexPath row]];
            [self showNavigateActions:self.selectedLocation.name];
            break;
        }
        case DestinationTableSectionRecents: //TODO
        {
            self.selectedLocation = (MyLocation*)[[[self dataController] recentsList] objectAtIndex:[indexPath row]];
            [self showNavigateActions:self.selectedLocation.name];
            break;
        }
        case DestinationTableSectionStations:
        {
            if (tableView == self.searchDisplayController.searchResultsTableView)
            {
                //Use filtered station results if in search results view
                self.selectedLocation = (MyLocation*)[[self filterResults] objectAtIndex:[indexPath row]];
                [self showNavigateActions:self.selectedLocation.name];
            }
            else
            {
                //Use full sorted station list if not in search results view
                self.selectedLocation = (MyLocation*)[[[self dataController] sortedStationList] objectAtIndex:[indexPath row]];
                [self showNavigateActions:self.selectedLocation.name];
            }
            break;
        }
        default:
            break;
    }
}

#if 0
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"DestinationsToStationDetail"])
    {
//        DockSmartMapViewController *mapViewController = self.tabBarController.childViewControllers[0];
        DockSmartStationDetailViewController *detailViewController = [segue destinationViewController];
        detailViewController.station = (Station *)[self.dataController objectInLocationList:self.dataController.sortedStationList atIndex:[self.tableView indexPathForSelectedRow].row];
    }
//    else if ([[segue identifier] isEqualToString:@"SearchCellToSearchResults"])
//    {
//        // perform the Geocode
//        [self performStringGeocode:self];
//
//        SearchResultsDetailViewController *resultsViewController = [segue destinationViewController];
//        
//    }
}
#endif

/* Search Bar Implementation - Pilfered & tweaked from Apple's TableSearch example project */

#pragma mark - Content Filtering

- (void)updateFilteredContentForLocationName:(NSString *)locationName type:(NSString *)typeName
{
    //Remove old search object
    self.searchLocation = nil;
    
	/*
	 Update the filtered array based on the search text and scope.
	 */
    if ((locationName == nil) || [locationName length] == 0)
    {
        // If there is no search string and the scope is "All".
        if (typeName == nil)
        {
            self.filterResults = [self.dataController.sortedStationList mutableCopy];
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
            self.filterResults = searchResults;
        }
        return;
    }
    
//    if ([self.filterResults count])
//    {
//        //remove previous search results, if the top cell was a previous geocode search prompt:
//        if ([[self.filterResults objectAtIndex:0] isMemberOfClass:[MyLocation class]])
//        {
//            [self.filterResults removeObjectAtIndex:0];
//        }
//        
//        //Remove all the stations for filtering with new locationName (and typeName):
//        NSRange stationRange = NSMakeRange(self.geocodeSearchResultsCount, ([self.filterResults count] - self.geocodeSearchResultsCount));
//        [self.filterResults removeObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:stationRange]]; // First clear the filtered array.
//        
//    }
    [self.filterResults removeAllObjects]; // First clear the filtered array.
    
    /* Add a search row at the top, to begin a geocode for the input address.
       Since this does not have coordinates yet, initialize this simply as a MyLocation object
       instead of an Address.
     */
//    MyLocation *newSearchAddress = [[MyLocation alloc] initWithName:locationName latitude:0 longitude:0];
//    [self.filterResults addObject:newSearchAddress];
    self.searchLocation = [[MyLocation alloc] initWithName:locationName coordinate:CLLocationCoordinate2DMake(0, 0) distanceFromUser:CLLocationDistanceMax];
    
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
				[self.filterResults addObject:station];
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

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    //TODO: Decide if you should start geocoding here...
    // perform the Geocode
    [self performStringGeocode:[searchBar text]];
}

#pragma mark - CLGeocoder methods

- (void)lockUI:(BOOL)lock
{
    // prevent user interaction while we are processing the forward geocoding
    self.tableView.allowsSelection = !lock;
}


- (void)performStringGeocode:(NSString *)string
{
//    // dismiss the keyboard if it's currently open
//    if ([self.searchStringTextField isFirstResponder])
//    {
//        [self.searchStringTextField resignFirstResponder];
//    }
    
    [self lockUI:YES];
    
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    
    //Remove previous geocode results:
    [self.geocodeSearchResults removeAllObjects];
    
    //Start HUD:
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = @"Loading addresses...";
    
    //Create a hint region around the user's current location for the geocoder
    CLRegion *region = [[CLRegion alloc]
                        initCircularRegionWithCenter:self.userCoordinate radius:5.0*METERS_PER_MILE identifier:@"Hint Region"];
    //Perform the geocode
    [geocoder geocodeAddressString:string inRegion:region completionHandler:^(NSArray *placemarks, NSError *error) {
        if (error)
        {
            NSLog(@"Geocode failed with error: %@", error);
            //                [self displayError:error];
            //Hide the HUD
            //TODO: add "No results found" text and delay?
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            return;
        }
        
        NSLog(@"Received placemarks: %@", placemarks);
        //            [self displayPlacemarks:placemarks];
        //place them at the top of the searchResults list in searchDisplayController instead of segueing to new view:
        //TODO: a new section in the table for the search results, with "Addresses" header, above everything else
        //            NSMutableArray *geocodeResults = [[NSMutableArray alloc] init];
        for (CLPlacemark *placemark in placemarks)
        {
            NSLog(@"Placemark name: %@ subthoroughfare: %@ thoroughfare: %@ sublocality: %@ locality: %@ subadministrativearea: %@ administrativearea: %@", placemark.name, placemark.subThoroughfare, placemark.thoroughfare, placemark.subLocality, placemark.locality, placemark.subAdministrativeArea, placemark.administrativeArea);
            Address *address = [[Address alloc] initWithPlacemark:placemark distanceFromUser:MKMetersBetweenMapPoints(MKMapPointForCoordinate(placemark.location.coordinate), MKMapPointForCoordinate(self.userCoordinate))];
            if ([address.name length] > 0)
            {
                [self.geocodeSearchResults addObject:address];
            }
        }
        //            self.geocodeSearchResultsCount = [geocodeResults count];
        //            NSRange searchCellRange = NSMakeRange(0, 1);
        //            [self.filterResults replaceObjectsInRange:searchCellRange withObjectsFromArray:geocodeResults];
        
        //Remove old search string object if this search returned results
        if ([self.geocodeSearchResults count])
        {
            self.searchLocation = nil;
            //TODO: add "No results found" text and delay HUD hide animation if no results were returned?
        }
        
        //Hide the HUD
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        
        //reload the data
        [self.searchDisplayController.searchResultsTableView reloadData];
        
        //unlock the UI
        [self lockUI:NO];
    }];
}

#pragma mark -
#pragma mark UIActionSheet implementation

- (void)showNavigateActions:(NSString *)title {
    
    NSString *cancelButtonTitle = NSLocalizedString(@"Cancel", @"Cancel button title");
    NSString *navigateHereTitle = NSLocalizedString(@"Navigate Here", @"Navigate Here button title");
    
    // If the user taps a destination to navigate to, present an action sheet to confirm.
    //TODO: Present more options here (to add/delete to/from Favorites, for example).
    self.navSheet = [[UIActionSheet alloc] initWithTitle:title delegate:self cancelButtonTitle:cancelButtonTitle destructiveButtonTitle:nil otherButtonTitles:navigateHereTitle, nil];
//    [self.navSheet showInView:self.view];
    [self.navSheet showFromTabBar:self.tabBarController.tabBar];
}


- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (buttonIndex == 0)
    {
        /*
         Inform the map view that the user chose to navigate to this destination.
         */
        [[NSNotificationCenter defaultCenter] postNotificationName:kStartBikingNotif
                                                            object:self
                                                          userInfo:[NSDictionary dictionaryWithObject:self.selectedLocation
                                                                                               forKey:kBikeDestinationKey]];
        //Switch over to the map view //TODO: Test this, change from hardcoded 0 to enum?
        [self.tabBarController setSelectedIndex:0];
    }
    else //cancel was pressed
    {
        //clear out the selected destination object
        self.selectedLocation = nil;
        
        //deselect the last row selected
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    self.navSheet = nil;
}


@end
