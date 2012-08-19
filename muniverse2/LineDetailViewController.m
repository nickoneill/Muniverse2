//
//  LineDetailViewController.m
//  muniverse2
//
//  Created by Nick O'Neill on 8/4/12.
//  Copyright (c) 2012 Nick O'Neill. All rights reserved.
//

#import "LineDetailViewController.h"
#import "AppDelegate.h"
#import "Line.h"
#import "Stop.h"
#import "AllLinesTableViewController.h"
#import "StopDetailViewController.h"

@interface LineDetailViewController ()

@end

@implementation LineDetailViewController

typedef enum {
    kDirectionInbound,
    kDirectionOutbound,
} DirectionTypes;

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
    
    self.title = self.line.name;
    
    [self directionChange:nil];
}

- (void)sortStops
{
    NSMutableArray *stopstrings;
    if (self.inoutcontrol.selectedSegmentIndex == kDirectionInbound) {
        stopstrings = [[self.line.inboundSort componentsSeparatedByString:@","] mutableCopy];
    } else {
        stopstrings = [[self.line.outboundSort componentsSeparatedByString:@","] mutableCopy];
    }
    
    [stopstrings removeObjectAtIndex:0];
    
    NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
    [f setNumberStyle:NSNumberFormatterDecimalStyle];
    
    NSMutableArray *stoparray = [NSMutableArray array];
    for (NSString *component in stopstrings) {
        [stoparray addObject:[f numberFromString:component]];
    }
    
    [self.stops sortUsingComparator:^NSComparisonResult(Stop *obj1, Stop *obj2) {
        if ([stoparray indexOfObject:obj1.tag] > [stoparray indexOfObject:obj2.tag]) {
            return NSOrderedDescending;
        } else {
            return NSOrderedAscending;
        }
    }];
}

- (void)directionChange:(id)sender
{
    if (self.inoutcontrol.selectedSegmentIndex == kDirectionInbound) {
        self.stops = [[self.line.inboundStops allObjects] mutableCopy];
    } else {
        self.stops = [[self.line.outboundStops allObjects] mutableCopy];
    }
    
    [self sortStops];

    [[self tableView] reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (section == 0) {
        return 1;
    } else {        
        return [self.stops count];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return @"";
    } else {
        if (self.inoutcontrol.selectedSegmentIndex == kDirectionInbound) {
            return self.line.inboundDesc;
        } else {
            return self.line.outboundDesc;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    if ([indexPath section] == 0) {
        static NSString *CellIdentifier = @"SwitchCell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        self.inoutcontrol = (UISegmentedControl *)[cell viewWithTag:1];
        [self.inoutcontrol addTarget:self action:@selector(directionChange:) forControlEvents:UIControlEventValueChanged];
    } else {
        static NSString *CellIdentifier = @"Cell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
                
        [self configureCell:cell atIndexPath:indexPath];
    }
    
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)ip
{
    // rewrite this index path because we manually create the first section
//    NSIndexPath *newpath = [[NSIndexPath indexPathWithIndex:0] indexPathByAddingIndex:[ip row]];
    Stop *stop = [self.stops objectAtIndex:[ip row]];
    
    if ([ip row] == 0) {
        NSString *middlePath = [[NSBundle mainBundle] pathForResource:@"Marker_Start" ofType:@"png"];
        cell.imageView.image = [UIImage imageWithContentsOfFile:middlePath];
    } else if ([ip row] > 0 && [ip row] < [self.stops count]-1) {
        NSString *middlePath = [[NSBundle mainBundle] pathForResource:@"Marker_Middle" ofType:@"png"];
        cell.imageView.image = [UIImage imageWithContentsOfFile:middlePath];
    } else if ([ip row] == [self.stops count]-1) {
        NSString *endPath = [[NSBundle mainBundle] pathForResource:@"Marker_End" ofType:@"png"];
        cell.imageView.image = [UIImage imageWithContentsOfFile:endPath];
    }

    
    cell.textLabel.text = stop.name;
    cell.textLabel.font = [UIFont boldSystemFontOfSize:16];

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

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
//    [self performSegueWithIdentifier:@"DirectionToStop" sender:self];
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
//    NSIndexPath *newpath = [[NSIndexPath indexPathWithIndex:0] indexPathByAddingIndex:[[self.tableView indexPathForSelectedRow] row]];

    // set our detail stop info
    Stop *selectedStop = [self.stops objectAtIndex:[[self.tableView indexPathForSelectedRow] row]];
    [(StopDetailViewController *)[segue destinationViewController] setStop:selectedStop];
    
    // set line and direction info
    [(StopDetailViewController *)[segue destinationViewController] setLine:self.line];
    
    if (self.inoutcontrol.selectedSegmentIndex == kDirectionInbound) {
        [(StopDetailViewController *)[segue destinationViewController] setIsInbound:YES];
    } else {
        [(StopDetailViewController *)[segue destinationViewController] setIsInbound:NO];
    }
}

@end
