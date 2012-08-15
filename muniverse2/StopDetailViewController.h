//
//  StopDetailViewController.h
//  muniverse2
//
//  Created by Nick O'Neill on 8/8/12.
//  Copyright (c) 2012 Nick O'Neill. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Stop,Line;

@interface StopDetailViewController : UIViewController

@property (strong) Stop *stop;
@property (strong) Line *line;
@property BOOL isInbound;
@property (strong) IBOutlet UIBarButtonItem *refresh;
@property (strong) IBOutlet UILabel *stopName;
@property (strong) IBOutlet UILabel *stopID;
@property (strong) IBOutlet UILabel *primaryArrival;
@property (strong) IBOutlet UILabel *secondaryArrival;

- (IBAction)refreshPredictions:(id)sender;

@end
