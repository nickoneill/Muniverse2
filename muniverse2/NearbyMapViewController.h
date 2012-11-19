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

@interface NearbyMapViewController : UIViewController <MKMapViewDelegate,UIActionSheetDelegate>

@property (strong) IBOutlet MKMapView *map;
@property (strong) IBOutlet UIView *detailView;
@property (strong) IBOutlet UITableView *detailTable;

@property (strong) NSArray *loadedStops;
@property (strong) NSArray *linesCache;
@property (strong) CalloutAnnotation *calloutAnnotation;
@property (strong) MKAnnotationView *selectedAnnotationView;
@property BOOL autoRegionChange;
@property BOOL shouldZoomToUser;
@property BOOL lastDisplayCluster;

@property (strong) IBOutlet UIImageView *closeButton;
@property (strong) IBOutlet UINavigationItem *navItem;
@property (strong) IBOutlet UIBarButtonItem *refresh;
@property (strong) UIBarButtonItem *refreshing;

- (IBAction)toggleFavorite;
- (IBAction)refreshPredictions;

@end
