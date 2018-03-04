//
//  SPGooglePlacesAutocompleteDemoViewController.m
//  SPGooglePlacesAutocomplete
//
//  Created by Stephen Poletto on 7/17/12.
//  Copyright (c) 2012 Stephen Poletto. All rights reserved.
//

#import "SPGooglePlacesAutocompleteDemoViewController.h"
#import "SPGooglePlacesAutocomplete.h"
#import "UIView+XLFormAdditions.h"
#import <MapKit/MapKit.h>
#import "SCHUtility.h"
#import "SCHAlert.h"
#import "AppDelegate.h"

@interface SPGooglePlacesAutocompleteDemoViewController ()<CLLocationManagerDelegate>
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (nonatomic, assign) BOOL recenterToUserLocation;
@end

@implementation SPGooglePlacesAutocompleteDemoViewController
@synthesize rowDescriptor = _rowDescriptor;
@synthesize mapView;
NSString *selectedAddress;
CLPlacemark *selectedPlacemark;
UIBarButtonItem *selectButton=nil;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        searchQuery = [[SPGooglePlacesAutocompleteQuery alloc] initWithApiKey:@"AIzaSyBrCwyUwfaACUCwLYFdzodwYWtuabBHBzw"];//@"AIzaSyAFsaDn7vyI8pS53zBgYRxu0HfRwYqH-9E"];
        shouldBeginEditing = YES;
    }
    return self;
}

- (void)viewDidLoad {
    //self.searchDisplayController.searchBar.placeholder = @"Search or Address";
    // ** Don't forget to add NSLocationWhenInUseUsageDescription in MyApp-Info.plist and give it a string
    self.recenterToUserLocation = YES;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification  object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(internetConnectionChanged)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7) {
        
        self.automaticallyAdjustsScrollViewInsets=YES;
        self.edgesForExtendedLayout = UIRectEdgeNone;
        self.navigationController.view.backgroundColor = [UIColor lightGrayColor];
        self.navigationController.navigationBar.translucent = YES;
    }
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    // Check for iOS 8. Without this guard the code will crash with "unknown selector" on iOS 7.
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
        [self.locationManager requestWhenInUseAuthorization];
        [self.locationManager requestAlwaysAuthorization];
    }
   
    [self.locationManager startUpdatingLocation];
    NSDictionary *location;
    if(self.XLFormdelegate!=NULL)
        location =  (NSDictionary*)self.XLFormdelegate.rowDescriptor.value;
    else
       location =  (NSDictionary*)self.rowDescriptor.value;
    NSString * addressString = [location valueForKey:@"address"];
   // NSLog(@"%@",addressString);
    if(addressString.length > 0){
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder geocodeAddressString:addressString completionHandler:^(NSArray *placemarks, NSError *error) {
        if (error) {
           // NSLog(@"%@", error);
        } else {
           // placeMark = [placemarks lastObject];
            [self addPlacemarkAnnotationToMap:[placemarks lastObject] addressString:addressString];
            [self recenterMapToPlacemark:[placemarks lastObject]];
        }
    }];
    }
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc]
                                   initWithTitle: @"Cancel"
                                   style:UIBarButtonItemStylePlain
                                   target: self action: @selector(goBack)];
    self.navigationItem.leftBarButtonItem = backButton;

    
    
//    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Icon-Back@3x.png"]
//                                                                   style:UIBarButtonItemStylePlain
//                                                                  target:self
//                                                                  action:@selector(goBack)];
//   self.title = @"Search Your Address";
//    self.navigationItem.leftBarButtonItem = backButton;
}

-(void)internetConnectionChanged{
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (!appDelegate.serverReachable){
        [self.navigationController popToRootViewControllerAnimated:YES];
        // [self.navigationController popToRootViewControllerAnimated:YES];
    }
    
}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
   // [self recenterMapToUserLocation:nil];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
}



- (void)viewDidUnload {
    [self setMapView:nil];
    [super viewDidUnload];
}


- (IBAction)recenterMapToUserLocation:(id)sender {
    self.recenterToUserLocation = NO;
    MKCoordinateRegion region;
    MKCoordinateSpan span;
    
    span.latitudeDelta = 0.02;
    span.longitudeDelta = 0.02;
    
    region.span = span;
    region.center = self.mapView.userLocation.coordinate;
    
    [self.mapView setRegion:region animated:YES];
    
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder reverseGeocodeLocation:self.locationManager.location completionHandler:^(NSArray *placemarks, NSError *error) {
       // NSLog(@"Finding address");
        if (error) {
           // NSLog(@"Error %@", error.description);
        } else {
            CLPlacemark *placemark = [placemarks lastObject];
            //NSLog(@"Name: %@", placemark.name);
            NSLog(@"PlaceMark: %@",placemark);
            NSMutableString *MutableAddressString = [[NSMutableString alloc] init];
            
            if (placemark.subThoroughfare.length > 0){
                [MutableAddressString appendString: placemark.subThoroughfare];
            }
            if (placemark.thoroughfare.length > 0){
                [MutableAddressString appendString:[NSString localizedStringWithFormat:@" %@,", placemark.thoroughfare] ];
            }

            [MutableAddressString appendString:[NSString localizedStringWithFormat:@" %@, %@, %@", placemark.locality, placemark.administrativeArea, placemark.country ]];
            
            NSString *addressString = [[NSString alloc] initWithString:MutableAddressString];

           addressString= [addressString stringByReplacingOccurrencesOfString:@"(null)" withString:@""];
            [self addPlacemarkAnnotationToMap:placemark addressString:addressString];
            [self recenterMapToPlacemark:placemark];
        }
    }];
    
}

// MKMapViewDelegate Methods
- (void)mapViewWillStartLocatingUser:(MKMapView *)mapView
{
    // Check authorization status (with class method)
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    
    // User has never been asked to decide on location authorization
    if (status == kCLAuthorizationStatusNotDetermined) {
       // NSLog(@"Requesting when in use auth");
        [self.locationManager requestWhenInUseAuthorization];
    }
    // User has denied location use (either for this app or for all apps
    else if (status == kCLAuthorizationStatusDenied) {
       // NSLog(@"Location services denied");
        // Alert the user and send them to the settings to turn on location
    }
}
// Location Manager Delegate Methods
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
   // NSLog(@"%@", [locations lastObject]);
}


#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [searchResultPlaces count];
}

- (SPGooglePlacesAutocompletePlace *)placeAtIndexPath:(NSIndexPath *)indexPath {
    return searchResultPlaces[indexPath.row];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"SPGooglePlacesAutocompleteCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    cell.textLabel.font = [UIFont fontWithName:@"GillSans" size:16.0];
    cell.textLabel.text = [self placeAtIndexPath:indexPath].name;
    return cell;
}

#pragma mark -
#pragma mark UITableViewDelegate

- (void)recenterMapToPlacemark:(CLPlacemark *)placemark {
    self.recenterToUserLocation = NO;
    MKCoordinateRegion region;
    MKCoordinateSpan span;
    
    span.latitudeDelta = 0.02;
    span.longitudeDelta = 0.02;
    
    region.span = span;
    region.center = placemark.location.coordinate;
    
    [self.mapView setRegion:region];
   // [self recenterMapToPlacemark:placemark];
   

}

- (void)addPlacemarkAnnotationToMap:(CLPlacemark *)placemark addressString:(NSString *)address {
    
    [self.mapView removeAnnotation:selectedPlaceAnnotation];
    
    selectedPlaceAnnotation = [[MKPointAnnotation alloc] init];
    selectedPlaceAnnotation.shouldGroupAccessibilityChildren = NO;
    selectedPlaceAnnotation.coordinate = placemark.location.coordinate;
    selectedPlaceAnnotation.title = address;
    selectedPlaceAnnotation.subtitle = @"Selected Address";
    [self.mapView addAnnotation:selectedPlaceAnnotation];
    selectedAddress = address;
    selectedPlacemark = placemark;
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    SPGooglePlacesAutocompletePlace *place = [self placeAtIndexPath:indexPath];
    NSLog(@"%@", place);
    
    [place resolveToPlacemark:^(CLPlacemark *placemark, NSString *addressString, NSError *error) {
        if (error) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Could not map selected Place"
                                                            message:error.localizedDescription
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil, nil];
            [alert show];
        } else if (placemark) {
            NSString *place = [[placemark.addressDictionary valueForKey:@"FormattedAddressLines"] componentsJoinedByString:@", "];
//            NSLog(@"%@",ABCreateStringWithAddressDictionary(placemark.addressDictionary, NO));
            [self addPlacemarkAnnotationToMap:placemark addressString:place];
            [self recenterMapToPlacemark:placemark];
            // ref: https://github.com/chenyuan/SPGooglePlacesAutocomplete/issues/10
            [self.searchDisplayController setActive:NO];
            [self.searchDisplayController.searchResultsTableView deselectRowAtIndexPath:indexPath animated:NO];
        }
    }];
}

#pragma mark -
#pragma mark UISearchDisplayDelegate

- (void)handleSearchForSearchString:(NSString *)searchString {
    searchQuery.location = self.mapView.userLocation.coordinate;
    searchQuery.input = searchString;
    [searchQuery fetchPlaces:^(NSArray *places, NSError *error) {
        if (error) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Could not fetch Places"
                                                            message:error.localizedDescription
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil, nil];
            [alert show];
        } else {
            searchResultPlaces = places;
            [self.searchDisplayController.searchResultsTableView reloadData];
        }
    }];
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    [self handleSearchForSearchString:searchString];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}

#pragma mark -
#pragma mark UISearchBar Delegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (![searchBar isFirstResponder]) {
        // User tapped the 'clear' button.
        shouldBeginEditing = NO;
        [self.searchDisplayController setActive:NO];
        [self.mapView removeAnnotation:selectedPlaceAnnotation];
    }
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    if (shouldBeginEditing) {
        // Animate in the table view.
        NSTimeInterval animationDuration = 0.3;
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:animationDuration];
        self.searchDisplayController.searchResultsTableView.alpha = .8;
        [UIView commitAnimations];
        [self.searchDisplayController.searchBar setShowsCancelButton:YES animated:YES];
    }
    
    BOOL boolToReturn = shouldBeginEditing;
    shouldBeginEditing = YES;
    
    return boolToReturn;
}

- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller
{
    
    [self performSelector:@selector(removeOverlay) withObject:nil afterDelay:.001f];
}

- (void)removeOverlay
{
  //  UIView *overlay = [self.view.subviews lastObject];
  //  overlay.frame = CGRectMake(0,0,overlay.frame.size.width, overlay.frame.size.height);
}
#pragma mark -
#pragma mark MKMapView Delegate

- (MKAnnotationView *)mapView:(MKMapView *)mapViewIn viewForAnnotation:(id <MKAnnotation>)annotation {
    if (mapViewIn != self.mapView || [annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }
    static NSString *annotationIdentifier = @"SPGooglePlacesAutocompleteAnnotation";
    MKPinAnnotationView *annotationView = (MKPinAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:annotationIdentifier];
    if (!annotationView) {
        annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:annotationIdentifier];
    }
    annotationView.animatesDrop = YES;
    annotationView.canShowCallout = YES;
    
    
    UIButton *detailButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    [detailButton addTarget:self action:@selector(annotationDetailButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    annotationView.rightCalloutAccessoryView = detailButton;
    [self addSelectButton];
    return annotationView;
}

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views {
    // Whenever we've dropped a pin on the map, immediately select it to present its callout bubble.
    [self.mapView selectAnnotation:selectedPlaceAnnotation animated:YES];
    if (self.recenterToUserLocation){
        MKCoordinateRegion region;
        MKCoordinateSpan span;
        
        span.latitudeDelta = 0.02;
        span.longitudeDelta = 0.02;
        
        region.span = span;
        region.center = self.mapView.userLocation.coordinate;
        
        [self.mapView setRegion:region animated:YES];
        
    } else{
        self.recenterToUserLocation = YES;
    }
}

- (void)annotationDetailButtonPressed:(id)sender {
    // Detail view controller application logic here.
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Selected Location"
                                                    message:selectedPlaceAnnotation.title
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil, nil];
    [alert show];

}



-(void) goBack{
    [self.navigationController popViewControllerAnimated:YES];
}

-(void) addSelectButton{
    if(self.navigationItem.rightBarButtonItem==nil){
     selectButton = [[UIBarButtonItem alloc]
                                   initWithTitle: @"Select"
                                   style:UIBarButtonItemStylePlain
                                   target: self action: @selector(selectButtonAction)];
    self.navigationItem.rightBarButtonItem = selectButton;
    }
}

-(void)selectButtonAction{
        NSMutableArray *newStack = [NSMutableArray arrayWithArray:[self.navigationController viewControllers]];
    
 
    
        if(self.isFromUserLocation)
        {
            // save user location in user address
            [SCHUtility createUserLocation:selectedAddress];
        }else{
           if(self.XLFormdelegate!=NULL){
               [self.XLFormdelegate.rowDescriptor setValue:@{@"address": selectedAddress,@"cordinate": selectedPlacemark.location}];
             [newStack removeLastObject];
           }else{
               [self.rowDescriptor setValue:@{@"address": selectedAddress,@"cordinate": selectedPlacemark.location}];
           }
        }
        [newStack removeLastObject];
        [self.navigationController setViewControllers:newStack animated:YES];
}


@end
