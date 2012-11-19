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

    // subscribe to the application becoming active after being in the background
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshPredictions) name:@"becameActive" object:nil];
    
    // set the title from our provided data
    self.navigationItem.title = [self.subway valueForKey:@"name"];

    // set background image for the table
    UIImage *bg = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Textured_App_Bg" ofType:@"png"]];
    [self.table setBackgroundView:[[UIImageView alloc] initWithImage:bg]];
    
    // finally request the lines from core data
    NSManagedObjectContext *moc = [(AppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
    
    NSFetchRequest *req = [NSFetchRequest fetchRequestWithEntityName:@"Line"];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"%@ IN %K",self.subway.inboundStop,@"inboundStops"];
    [req setPredicate:pred];
    
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"allLinesSort" ascending:YES];
    [req setSortDescriptors:[NSArray arrayWithObject:sort]];
    
    NSError *err;
    self.lines = [moc executeFetchRequest:req error:&err];
    if (err != nil) {
        NSLog(@"issue with subway stops: %@",[err localizedDescription]);
    }
    
    // set up needed items for the refresh button states
    UIActivityIndicatorView *spin = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 30, 20)];
    [spin setTag:1];
    self.refreshing = [[UIBarButtonItem alloc] initWithCustomView:spin];

    // kick off predictions
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
    
    [cell.primaryText setText:[NextBusClient nameStripShort:line.name]];
    [cell.lineIcon setImage:[UIImage imageNamed:[NSString stringWithFormat:@"Subway_Icon_%@.png",line.shortname]]];
    if (self.inoutcontrol.selectedSegmentIndex == kDirectionInbound) {
        [cell.secondaryText setText:[NextBusClient truncatedDescription:line.inboundDesc]];
    } else {
        [cell.secondaryText setText:[NextBusClient truncatedDescription:line.outboundDesc]];
    }
    
    cell.primaryPrediction.text = @"";
    cell.secondaryPrediction.text = @"";
    
    return cell;
}

- (IBAction)directionChange:(id)sender
{
    [self.table reloadData];
    [self refreshPredictions];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (self.inoutcontrol.selectedSegmentIndex == kDirectionOutbound) {
        return @"T-Third Street line continues outbound as K-Ingleside after Folsom & Embarcadero";
    } else {
        return @"For Ballpark or Caltrain service, take any inbound N-Judah or T-Third Street train";
    }
}

- (IBAction)refreshPredictions
{
    NSLog(@"refreshing");
    
    [[self navigationItem] setRightBarButtonItem:self.refreshing];
    [(UIActivityIndicatorView *)self.refreshing.customView startAnimating];
    
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
                cell.primaryPrediction.text = [NextBusClient formattedTimeFromNumer:[els objectAtIndex:0]];
                
                if ([els count] > 1) {
                    cell.secondaryPrediction.text = [NextBusClient formattedTimeFromNumer:[els objectAtIndex:1]];
                } else {
                    cell.secondaryPrediction.text = @"--";
                }
            } else {
                cell.primaryPrediction.text = @"";
                cell.secondaryPrediction.text = @"";
            }
            
            [(UIActivityIndicatorView *)self.refreshing.customView stopAnimating];
            [[self navigationItem] setRightBarButtonItem:self.refresh];
        } andFailure:^(NSError *err) {
            NSLog(@"failed getting predictions: %@",[err localizedDescription]);

            [(UIActivityIndicatorView *)self.refreshing.customView stopAnimating];
            [[self navigationItem] setRightBarButtonItem:self.refresh];
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

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
