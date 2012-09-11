//
//  NewStopDetailViewController.h
//  muniverse2
//
//  Created by Nick O'Neill on 8/31/12.
//  Copyright (c) 2012 Nick O'Neill. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Stop,Line,MKMapView;

@interface NewStopDetailViewController : UIViewController

@property (strong) Stop *stop;
@property (strong) Line *line;
@property BOOL isInbound;

@property (strong) IBOutlet MKMapView *map;

@end
