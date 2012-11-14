//
//  StationViewController.h
//  muniverse2
//
//  Created by Nick O'Neill on 7/16/12.
//  Copyright (c) 2012 Nick O'Neill. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Subway,Line;

@interface StationViewController : UIViewController <UITableViewDataSource,UITableViewDelegate>

@property (strong) Subway *subway;
@property (strong) NSArray *lines;
@property (strong) IBOutlet UITableView *table;
@property (strong) IBOutlet UISegmentedControl *inoutcontrol;
@property (strong) IBOutlet UIBarButtonItem *refresh;
@property (strong) UIBarButtonItem *refreshing;

@end
