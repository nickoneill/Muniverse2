//
//  FavoritesViewController.m
//  muniverse2
//
//  Created by Nick O'Neill on 8/19/12.
//  Copyright (c) 2012 Nick O'Neill. All rights reserved.
//

#import "FavoritesViewController.h"
#import "AppDelegate.h"
#import "Favorite.h"
#import "FavoriteCell.h"
#import "Line.h"
#import "Stop.h"
#import "NextBusClient.h"
#import "StopDetailViewController.h"

@interface FavoritesViewController ()

@end

@implementation FavoritesViewController

@synthesize frc=_frc;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // subscribe to the application becoming active after being in the background
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshPredictions) name:@"becameActive" object:nil];
    
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:80/255.0f green:109/255.0f blue:131/255.0f alpha:1];
    
    // load up easy-to-access managed object context
    AppDelegate *app = [[UIApplication sharedApplication] delegate];
    self.moc = app.managedObjectContext;
    
    NSError *error;
    if (![[self frc] performFetch:&error]) {
        NSLog(@"whoops with faves frc: %@",error);
    }
    
    // set up needed items for the refresh button states
    UIActivityIndicatorView *spin = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 30, 20)];
    [spin setTag:1];
    self.refreshing = [[UIBarButtonItem alloc] initWithCustomView:spin];

    [self refreshPredictions];
}

- (NSFetchedResultsController *)frc {
    
    if (_frc != nil) {
        return _frc;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Favorite" inManagedObjectContext:self.moc];
    [fetchRequest setEntity:entity];
        
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sort]];
    
    [fetchRequest setFetchBatchSize:20];
    
    NSFetchedResultsController *theFetchedResultsController =
    [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                        managedObjectContext:self.moc sectionNameKeyPath:nil
                                                   cacheName:nil];
    self.frc = theFetchedResultsController;
    _frc.delegate = self;
    
    return _frc;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    _frc = nil;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id sectionInfo = [[[self frc] sections] objectAtIndex:section];
    
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    FavoriteCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (void)configureCell:(FavoriteCell *)cell atIndexPath:(NSIndexPath *)ip
{
    Favorite *fav = [self.frc objectAtIndexPath:ip];
    
    cell.stopName.text = fav.stop.name;
    cell.lineName.text = fav.line.name;
    if (fav.isInbound) {
        cell.destination.text = fav.line.inboundDesc;
    } else {
        cell.destination.text = fav.line.outboundDesc;
    }
}

- (IBAction)refreshPredictions
{
    if ([[self.frc fetchedObjects] count]) {
        [[self navigationItem] setRightBarButtonItem:self.refreshing];
        [(UIActivityIndicatorView *)self.refreshing.customView startAnimating];
    }

    NextBusClient *client = [[NextBusClient alloc] init];
    
    for (int i = 0; i < [[self.frc fetchedObjects] count]; i++) {
        Favorite *fav = [self.frc objectAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        int stopid = [fav.stop.stopId intValue];
        NSString *lineTag = @"";
        if (fav.isInbound) {
            lineTag = fav.line.inboundTags;
        } else {
            lineTag = fav.line.outboundTags;
        }
        
        [client predictionForLineTag:lineTag atStopId:stopid withSuccess:^(NSArray *els) {
            FavoriteCell *cell = (FavoriteCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            
            if ([els count]) {
                cell.primaryPrediction.text = [NSString stringWithFormat:@"%@",[els objectAtIndex:0]];
                
                if ([els count] > 1) {
                    cell.secondaryPrediction.text = [NSString stringWithFormat:@"%@",[els objectAtIndex:1]];
                } else {
                    cell.secondaryPrediction.text = @"--";
                }
            } else {
                cell.primaryPrediction.text = @"";
                cell.secondaryPrediction.text = @"!";
            }
            
            [(UIActivityIndicatorView *)self.refreshing.customView stopAnimating];
            [[self navigationItem] setRightBarButtonItem:self.refresh];
        } andFailure:^(NSError *err) {
            NSLog(@"some failure: %@",err);

            [(UIActivityIndicatorView *)self.refreshing.customView stopAnimating];
            [[self navigationItem] setRightBarButtonItem:self.refresh];
        }];
    }
}

- (IBAction)editButton:(id)sender
{
    UIBarButtonItem *button = sender;
        
    if ([self.tableView isEditing]) {
        
        // favorite order debugging
        NSMutableArray *favs = [[self.frc fetchedObjects] mutableCopy];
        
        for (Favorite *favobj in favs) {
            NSLog(@"fav: %@ %@",favobj.line.name,favobj.order);
        }
        
        [button setTitle:@"Edit"];
        [button setStyle:UIBarButtonItemStylePlain];

        [self.tableView setEditing:NO animated:YES];
    } else {
        [button setTitle:@"Done"];
        [button setStyle:UIBarButtonItemStyleDone];
        
        [self.tableView setEditing:YES animated:YES];
    }
}

- (void)resetFavoriteOrder
{

}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Favorite *fav = [self.frc objectAtIndexPath:indexPath];
        [self.moc deleteObject:fav];
        
        NSError *err;
        [self.moc save:&err];
        if (err != nil) {
            NSLog(@"there was an issue deleting the favorite");
        }
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    
    NSMutableArray *favs = [[self.frc fetchedObjects] mutableCopy];
    
    Favorite *fav = [self.frc objectAtIndexPath:fromIndexPath];
    
    [favs removeObject:fav];
    [favs insertObject:fav atIndex:[toIndexPath row]];
    
    int i = 0;
    for (Favorite *favobj in favs) {
        [favobj setOrder:[NSNumber numberWithInt:i++]];
    }
    
    NSError *err;
    [self.moc save:&err];
    if (err != nil) {
        NSLog(@"there was an issue reordering the favorite");
    }
    
    [self.tableView moveRowAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
}

#pragma mark - frc delegate stuff

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
    [self.tableView beginUpdates];
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    
    UITableView *tableView = self.tableView;
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [self refreshPredictions];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:(FavoriteCell *)[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            // don't do our work for us
            break;
    }
}


- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id )sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
    [self.tableView endUpdates];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // set our detail stop info
    Favorite *selectedFav = [self.frc objectAtIndexPath:[self.tableView indexPathForSelectedRow]];
    [(StopDetailViewController *)[segue destinationViewController] setStop:selectedFav.stop];
    
    // set line and direction info
    [(StopDetailViewController *)[segue destinationViewController] setLine:selectedFav.line];
    
    if (selectedFav.isInbound) {
        [(StopDetailViewController *)[segue destinationViewController] setIsInbound:YES];
    } else {
        [(StopDetailViewController *)[segue destinationViewController] setIsInbound:NO];
    }

}

@end
