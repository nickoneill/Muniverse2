//
//  StationViewController.m
//  muniverse2
//
//  Created by Nick O'Neill on 7/16/12.
//  Copyright (c) 2012 Nick O'Neill. All rights reserved.
//

#import "StationViewController.h"
#import "AppDelegate.h"
#import "Subway.h"
#import "Stop.h"
#import "Line.h"
#import "GroupedPredictionCell.h"
#import "NextBusClient.h"

@interface StationViewController ()

@end

@implementation StationViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIImage *bg = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Background" ofType:@"png"]];
    [self.table setBackgroundView:[[UIImageView alloc] initWithImage:bg]];
	
    NSManagedObjectContext *moc = [(AppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
    
    NSFetchRequest *req = [NSFetchRequest fetchRequestWithEntityName:@"Line"];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"%@ IN %K",self.subway.inboundStop,@"inboundStops"];
    [req setPredicate:pred];
    
    NSError *err;
    self.lines = [moc executeFetchRequest:req error:&err];
    if (err != nil) {
        NSLog(@"issue with subway stops: %@",[err localizedDescription]);
    }
    
    self.navigationItem.title = [self.subway valueForKey:@"name"];
    
    [self refreshPredictions];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.lines count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    GroupedPredictionCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    Line *line = [self.lines objectAtIndex:[indexPath row]];
    
    cell.lineIcon.image = [UIImage imageNamed:[NSString stringWithFormat:@"Subway_Icon_%@.png",line.shortname]];
    
    if ([line.shortname isEqualToString:@"J"]) {
        cell.primaryText.text = @"Church";
    } else if ([line.shortname isEqualToString:@"L"]) {
        cell.primaryText.text = @"Taraval";
    } else if ([line.shortname isEqualToString:@"M"]) {
        cell.primaryText.text = @"Ocean View";
    } else if ([line.shortname isEqualToString:@"N"]) {
        cell.primaryText.text = @"Judah";
    } else if ([line.shortname isEqualToString:@"KT"]) {
        if (self.inoutcontrol.selectedSegmentIndex == kDirectionInbound) {
            cell.primaryText.text = @"Third Street";
        } else {
            cell.primaryText.text = @"Ingleside";
        }
    }
    
    if (self.inoutcontrol.selectedSegmentIndex == kDirectionInbound) {
        cell.secondaryText.text = [self stripPrefix:@"Inbound " fromText:line.inboundDesc];
    } else {
        cell.secondaryText.text = [self stripPrefix:@"Outbound " fromText:line.outboundDesc];
    }
    
    cell.primaryPrediction.text = @"";
    cell.secondaryPrediction.text = @"";
    
    return cell;
}

- (IBAction)directionChange:(id)sender
{
    [self.table reloadData];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return @"KT is sometimes K, sometimes T. I know, that's some whack shit.";
}

- (void)refreshPredictions
{
    NextBusClient *client = [[NextBusClient alloc] init];
    
    for (int i = 0; i < [self.lines count]; i++) {
        int stopid = 0;
        NSString *lineTag = @"";
        if (self.inoutcontrol.selectedSegmentIndex == kDirectionInbound) {
            stopid = [[self.subway.inboundStop stopId] intValue];
            lineTag = [[self.lines objectAtIndex:i] inboundTags];
        } else {
            stopid = [[self.subway.outboundStop stopId] intValue];
            lineTag = [[self.lines objectAtIndex:i] outboundTags];
        }
        
        [client predictionForLineTag:lineTag atStopId:stopid withSuccess:^(NSArray *els) {
            GroupedPredictionCell *cell = (GroupedPredictionCell *)[self.table cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            
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

- (NSString *)stripPrefix:(NSString *)prefix fromText:(NSString *)text
{
    NSRange prefixRange = [text rangeOfString:prefix];
    
    return [text stringByReplacingCharactersInRange:prefixRange withString:@""];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
