//
//  SubwayTableViewController.h
//  muniverse2
//
//  Created by Nick O'Neill on 7/16/12.
//  Copyright (c) 2012 Nick O'Neill. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SubwayTableViewController : UITableViewController <UITableViewDataSource,UITableViewDelegate,NSFetchedResultsControllerDelegate>

@property (nonatomic,strong) NSManagedObjectContext *moc;
@property (nonatomic,strong) NSFetchedResultsController *frc;

@end
