//
//  NewStopDetailViewController.m
//  muniverse2
//
//  Created by Nick O'Neill on 8/31/12.
//  Copyright (c) 2012 Nick O'Neill. All rights reserved.
//

#import "NewStopDetailViewController.h"
#import "Line.h"
#import "Stop.h"

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
	// Do any additional setup after loading the view.
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
