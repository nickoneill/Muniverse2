//
//  StationViewController.h
//  muniverse2
//
//  Created by Nick O'Neill on 7/16/12.
//  Copyright (c) 2012 Nick O'Neill. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Stop;

@interface StationViewController : UIViewController <UITableViewDataSource,UITableViewDelegate>

@property (strong) Stop *stop;
@property (strong) IBOutlet UITableView *table;

@end
