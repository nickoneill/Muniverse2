//
//  AllLinesTableViewController.h
//  muniverse2
//
//  Created by Nick O'Neill on 8/2/12.
//  Copyright (c) 2012 Nick O'Neill. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AllLinesTableViewController : UITableViewController <NSFetchedResultsControllerDelegate>

@property (nonatomic,strong) NSManagedObjectContext *moc;
@property (nonatomic,strong) NSFetchedResultsController *frc;
@property (nonatomic,strong) IBOutlet UISegmentedControl *type;

- (void)lineTypeChange:(id)sender;

@end
