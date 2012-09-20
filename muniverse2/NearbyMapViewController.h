//
//  NearbyMapViewController.h
//  muniverse2
//
//  Created by Nick O'Neill on 8/29/12.
//  Copyright (c) 2012 Nick O'Neill. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MKMapView;

@interface NearbyMapViewController : UIViewController

@property (strong) IBOutlet MKMapView *map;
@property (strong) IBOutlet UIView *detailView;
@property (strong) IBOutlet UITableView *detailTable;
@property (strong) NSMutableArray *loadedStops;
@property BOOL shouldZoomToUser;

@property (weak, nonatomic) IBOutlet UIImageView *closeButton;

@end
