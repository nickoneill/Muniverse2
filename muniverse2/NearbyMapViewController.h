//
//  NearbyMapViewController.h
//  muniverse2
//
//  Created by Nick O'Neill on 8/29/12.
//  Copyright (c) 2012 Nick O'Neill. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@class MKMapView,CalloutAnnotation,CalloutAnnotationView;

@interface NearbyMapViewController : UIViewController <MKMapViewDelegate>

@property (strong) IBOutlet MKMapView *map;
@property (strong) IBOutlet UIView *detailView;
@property (strong) IBOutlet UITableView *detailTable;

@property (strong) NSMutableArray *loadedStops;
@property (strong) CalloutAnnotation *calloutAnnotation;
@property (strong) MKAnnotationView *selectedAnnotationView;
//@property (strong) MuniPinAnnotation *pinAnnotation;
@property BOOL shouldZoomToUser;

@property (strong) IBOutlet UIImageView *closeButton;

- (IBAction)closeDetail;

@end
