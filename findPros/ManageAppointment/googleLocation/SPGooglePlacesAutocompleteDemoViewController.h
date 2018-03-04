//
//  SPGooglePlacesAutocompleteDemoViewController.h
//  SPGooglePlacesAutocomplete
//
//  Created by Stephen Poletto on 7/17/12.
//  Copyright (c) 2012 Stephen Poletto. All rights reserved.
//

#import <MapKit/MapKit.h>
#import "XLForm.h"
#import "SCHLocationSelectorViewController.h"
@class SPGooglePlacesAutocompleteQuery;

@interface SPGooglePlacesAutocompleteDemoViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchDisplayDelegate, UISearchBarDelegate, MKMapViewDelegate, XLFormRowDescriptorViewController> {
    NSArray *searchResultPlaces;
    SPGooglePlacesAutocompleteQuery *searchQuery;
    MKPointAnnotation *selectedPlaceAnnotation;
    
    BOOL shouldBeginEditing;
}
@property (nonatomic, weak) id <XLFormRowDescriptorViewController> XLFormdelegate;
@property (strong, nonatomic) IBOutlet MKMapView *mapView;
@property (assign) BOOL isFromUserLocation;
@end
