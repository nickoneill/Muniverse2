//
//  NewStopDetailViewController.m
//  muniverse2
//
//  Created by Nick O'Neill on 8/31/12.
//  Copyright (c) 2012 Nick O'Neill. All rights reserved.
//

#import "NewStopDetailViewController.h"
#import "GroupedPredictionCell.h"
#import "Line.h"
#import "Stop.h"
#import <MapKit/MapKit.h>
#import "MKMapView+ZoomLevel.h"

@interface NewStopDetailViewController ()

@end

@implementation NewStopDetailViewController

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
	
    [self.map setCenterCoordinate:CLLocationCoordinate2DMake([self.stop.lat floatValue], [self.stop.lon floatValue]) zoomLevel:15 animated:NO];
    
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
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    GroupedPredictionCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    cell.primaryText.text = self.line.name;
    if (self.isInbound) {
        cell.secondaryText.text = self.line.inboundDesc;
    } else {
        cell.secondaryText.text = self.line.outboundDesc;
    }
    
    if ([self.line.shortname isEqualToString:@"J"]) {
        cell.lineIcon.image = [UIImage imageNamed:[NSString stringWithFormat:@"Subway_Icon_L.png"]];
    }

    cell.primaryPrediction.text = @"--";
    cell.secondaryPrediction.text = @"--";
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return @"Current line";
    } else {
        return @"";//@"Other lines at your location:";
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
