//
//  LineDetailViewController.h
//  muniverse2
//
//  Created by Nick O'Neill on 8/4/12.
//  Copyright (c) 2012 Nick O'Neill. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Line;

@interface LineDetailViewController : UITableViewController <NSFetchedResultsControllerDelegate>

@property (nonatomic,strong) NSManagedObjectContext *moc;
@property (nonatomic,strong) NSFetchedResultsController *frc;
//@property (nonatomic,strong) IBOutlet UISegmentedControl *type;
@property (nonatomic,strong) Line *line;

@end
