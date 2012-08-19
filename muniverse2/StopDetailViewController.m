//
//  StopDetailViewController.m
//  muniverse2
//
//  Created by Nick O'Neill on 8/8/12.
//  Copyright (c) 2012 Nick O'Neill. All rights reserved.
//

#import "StopDetailViewController.h"
#import "NextBusClient.h"
#import "Stop.h"
#import "Line.h"
#import "TouchXML.h"

@interface StopDetailViewController ()

@end

@implementation StopDetailViewController

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
        
    UIImage *bgimage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Background" ofType:@"png"]];
    [self.view setBackgroundColor:[UIColor colorWithPatternImage:bgimage]];
    
    self.stopName.text = self.stop.name;
    self.stopID.text = [NSString stringWithFormat:@"%@",self.stop.tag];
    
    self.primaryArrival.text = @"Fetching...";
    self.secondaryArrival.text = @"";
    
    [self refreshPredictions:nil];
}

- (IBAction)refreshPredictions:(id)sender
{
    [self setBarButtonItemRefreshing:YES];
    
    NextBusClient *client = [[NextBusClient alloc] init];
    
    NSString *lineTag = self.line.inboundTags;
    if (!self.isInbound) {
        lineTag = self.line.outboundTags;
    }
    [client predictionForLineTag:lineTag atStopId:[self.stop.stopId intValue] withSuccess:^(NSArray *els) {
        if ([els count]) {
            
            if ([[els objectAtIndex:0] intValue] == 0) {
                self.primaryArrival.text = @"Arriving now";
            } else if ([[els objectAtIndex:0] intValue] == 1) {
                self.primaryArrival.text = [NSString stringWithFormat:@"%@ Minute",[els objectAtIndex:0]];
            } else {
                self.primaryArrival.text = [NSString stringWithFormat:@"%@ Minutes",[els objectAtIndex:0]];
            }
            
            if ([els count] >= 4) {
                self.secondaryArrival.text = [NSString stringWithFormat:@"%@, %@ and %@ minutes",[els objectAtIndex:1],[els objectAtIndex:2],[els objectAtIndex:3]];
            } else if ([els count] == 3) {
                self.secondaryArrival.text = [NSString stringWithFormat:@"%@ and %@ minutes",[els objectAtIndex:1],[els objectAtIndex:2]];
            } else if ([els count] == 2) {
                self.secondaryArrival.text = [NSString stringWithFormat:@"Also %@ minutes",[els objectAtIndex:1]];
            } else {
                self.secondaryArrival.text = @"No later arrivals";
            }
        } else {
            self.primaryArrival.text = @"No arrivals scheduled";
        }
        
        [self setBarButtonItemRefreshing:YES];
    } andFailure:^(NSError * err) {
        NSLog(@"some failure: %@",err);
        
        [self setBarButtonItemRefreshing:NO];
    }];
}

- (void)setBarButtonItemRefreshing:(BOOL)refreshing
{
//    if (refreshing) {
//        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
//        [spinner startAnimating];
//        
//        UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithCustomView:spinner];
//        [self.navigationItem setRightBarButtonItem:button];
//    } else {
//        UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshPredictions:)];
//        [self.navigationItem setRightBarButtonItem:button];
//    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
