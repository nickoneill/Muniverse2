//
//  LineDetailViewController.h
//  muniverse2
//
//  Created by Nick O'Neill on 8/4/12.
//  Copyright (c) 2012 Nick O'Neill. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Line;

@interface LineDetailViewController : UITableViewController

@property (strong) UISegmentedControl *inoutcontrol;
@property (strong) Line *line;
@property (strong) NSMutableArray *stops;

@end
