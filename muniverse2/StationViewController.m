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
#import "Line.h"

@interface StationViewController ()

@end

@implementation StationViewController

typedef enum {
    kDirectionInbound,
    kDirectionOutbound,
} DirectionTypes;

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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    Line *line = [self.lines objectAtIndex:[indexPath row]];
    
    if ([line.shortname isEqualToString:@"J"]) {
        cell.textLabel.text = @"Church";
    } else if ([line.shortname isEqualToString:@"L"]) {
        cell.textLabel.text = @"Taraval";
    } else if ([line.shortname isEqualToString:@"M"]) {
        cell.textLabel.text = @"Ocean View";
    } else if ([line.shortname isEqualToString:@"N"]) {
        cell.textLabel.text = @"Judah";
    } else if ([line.shortname isEqualToString:@"KT"]) {
        if (self.inoutcontrol.selectedSegmentIndex == kDirectionInbound) {
            cell.textLabel.text = @"Third Street";
        } else {
            cell.textLabel.text = @"Ingleside";
        }
    }
    
    return cell;
}

- (IBAction)directionChange:(id)sender
{
    [self.table reloadData];
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
