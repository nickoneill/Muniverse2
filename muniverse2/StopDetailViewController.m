//
//  StopDetailViewController.m
//  muniverse2
//
//  Created by Nick O'Neill on 8/8/12.
//  Copyright (c) 2012 Nick O'Neill. All rights reserved.
//

#import "StopDetailViewController.h"
#import "Stop.h"

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
    
    self.primaryArrival.text = @"Never. Muni sucks.";
    self.secondaryArrival.text = @"1, 2 and 3 minutes";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
