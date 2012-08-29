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
    
    AppDelegate *app = [[UIApplication sharedApplication] delegate];
    self.moc = app.managedObjectContext;
    
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:80/255.0f green:109/255.0f blue:131/255.0f alpha:1];
    
    NSError *error;
    if (![[self frc] performFetch:&error]) {
        NSLog(@"whoops with faves frc: %@",error);
    }

    [self refreshPredictions];
}

- (NSFetchedResultsController *)frc {
    
    if (_frc != nil) {
        return _frc;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Favorite" inManagedObjectContext:self.moc];
    [fetchRequest setEntity:entity];
        
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:NO];
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

- (IBAction)refreshAll:(id)sender
{
    [self refreshPredictions];
}

- (void)refreshPredictions
{
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
                cell.secondaryPrediction.text = @"";
            }
        } andFailure:^(NSError *err) {
            NSLog(@"some failure: %@",err);
        }];
    }
}

- (IBAction)editButton:(id)sender
{
    NSFetchRequest *fetch = [NSFetchRequest fetchRequestWithEntityName:@"Stop"];
    
    [fetch setPredicate:[NSPredicate predicateWithFormat:@"%K == %@",@"stopId",@14015]];
    
    NSError *err;
    NSArray *stops = [self.moc executeFetchRequest:fetch error:&err];
    
    Stop *stop = [stops objectAtIndex:0];
    
    Favorite *newfav = [NSEntityDescription insertNewObjectForEntityForName:@"Favorite" inManagedObjectContext:self.moc];
    
    [newfav setIsInbound:[NSNumber numberWithBool:YES]];
    [newfav setStop:stop];
    [newfav setLine:[[stop inboundLines] anyObject]];
    
    if (![self.moc save:&err]) {
        NSLog(@"Whoops, error saving favorite data: %@",[err localizedDescription]);
    }
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - frc delegate stuff

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
    [self.tableView beginUpdates];
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    
    UITableView *tableView = self.tableView;
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:(FavoriteCell *)[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray
                                               arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray
                                               arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
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
