//
//  MuniTabController.m
//  muniverse2
//
//  Created by Nick O'Neill on 8/29/12.
//  Copyright (c) 2012 Nick O'Neill. All rights reserved.
//

#import "MuniTabController.h"
#import "AppDelegate.h"
#import "NearbyMapViewController.h"
#import "Flurry.h"

@interface MuniTabController ()

@end

@implementation MuniTabController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    [[NSNotificationCenter defaultCenter] addObserverForName:@"FavoriteAdded" object:nil queue:nil usingBlock:^(NSNotification *note) {
        UIView *currentView = self.selectedViewController.view;
        
        if (self.selectedIndex != 0) {
            UIView *favorites = [[self.viewControllers objectAtIndex:0] view];
            
            [UIView transitionFromView:currentView toView:favorites duration:0.5 options:UIViewAnimationOptionTransitionFlipFromRight completion:^(BOOL finished) {
                [self setSelectedIndex:0];
            }];
        }
    }];
    
    AppDelegate *app = [[UIApplication sharedApplication] delegate];
    
    NSFetchRequest *fetch = [NSFetchRequest fetchRequestWithEntityName:@"Favorite"];
    
    NSError *err;
    int favorites = [app.managedObjectContext countForFetchRequest:fetch error:&err];

    if (favorites == 0) {
        [self setSelectedIndex:1];
    }
}

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    [Flurry logEvent:[NSString stringWithFormat:@"selected tab %@",[item title]]];
    
    if ([tabBar selectedItem] == [[tabBar items] objectAtIndex:1] && self.previouslySelected == [[tabBar items] objectAtIndex:1]) {
        NearbyMapViewController *nearby = (NearbyMapViewController *)[self.viewControllers objectAtIndex:1];
        
        [nearby recenter];
    }
    
    self.previouslySelected = [tabBar selectedItem];
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
