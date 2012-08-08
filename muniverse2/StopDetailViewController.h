//
//  StopDetailViewController.h
//  muniverse2
//
//  Created by Nick O'Neill on 8/8/12.
//  Copyright (c) 2012 Nick O'Neill. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Stop;

@interface StopDetailViewController : UIViewController

@property (strong) Stop *stop;
@property (strong) IBOutlet UILabel *stopName;
@property (strong) IBOutlet UILabel *stopID;
@property (strong) IBOutlet UILabel *primaryArrival;
@property (strong) IBOutlet UILabel *secondaryArrival;

@end
