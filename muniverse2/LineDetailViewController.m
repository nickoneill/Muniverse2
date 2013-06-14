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
    
    // set this above the table view when people pull down, plain white is too jarring
    UIImageView *background = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"TexturedBackground.png"]];
    [background setFrame:CGRectMake(0, -480, background.frame.size.width, background.frame.size.height)];
    [self.tableView addSubview:background];
    
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

            self.line.inboundDesc = [self.line.inboundDesc stringByReplacingOccurrencesOfString:@"Inbound t" withString:@"T"];
            return self.line.inboundDesc;
        } else {
            self.line.outboundDesc = [self.line.outboundDesc stringByReplacingOccurrencesOfString:@"Outbound t" withString:@"T"];
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
        if (self.line.outboundSort == nil) {
            [self.inoutcontrol setEnabled:NO forSegmentAtIndex:1];
        }
    } else {
        static NSString *CellIdentifier = @"Cell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
                
        [self configureCell:cell atIndexPath:indexPath];
    }
    
    LALog(@"returning: %@",cell);
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)ip
{
    Stop *stop = [self.stops objectAtIndex:[ip row]];
    
    if ([ip row] == 0) {
        NSString *middlePath = [[NSBundle mainBundle] pathForResource:@"Marker_Start" ofType:@"png"];
        NSString *middlePathHighlighted = [[NSBundle mainBundle] pathForResource:@"Marker_Start-h" ofType:@"png"];
        cell.imageView.image = [UIImage imageWithContentsOfFile:middlePath];
        cell.imageView.highlightedImage = [UIImage imageWithContentsOfFile:middlePathHighlighted];
   } else if ([ip row] > 0 && [ip row] < [self.stops count]-1) {
        NSString *middlePath = [[NSBundle mainBundle] pathForResource:@"Marker_Middle" ofType:@"png"];
        NSString *middlePathHighlighted = [[NSBundle mainBundle] pathForResource:@"Marker_Middle-h" ofType:@"png"];
        cell.imageView.image = [UIImage imageWithContentsOfFile:middlePath];
        cell.imageView.highlightedImage = [UIImage imageWithContentsOfFile:middlePathHighlighted];
    } else if ([ip row] == [self.stops count]-1) {
        NSString *endPath = [[NSBundle mainBundle] pathForResource:@"Marker_End" ofType:@"png"];
        NSString *endPathHighlighted = [[NSBundle mainBundle] pathForResource:@"Marker_End-h" ofType:@"png"];
        cell.imageView.image = [UIImage imageWithContentsOfFile:endPath];
        cell.imageView.highlightedImage = [UIImage imageWithContentsOfFile:endPathHighlighted];
   }
    
    cell.textLabel.text = stop.name;
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
