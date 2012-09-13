//
//  StopDetailViewController.m
//  muniverse2
//
//  Created by Nick O'Neill on 8/8/12.
//  Copyright (c) 2012 Nick O'Neill. All rights reserved.
//

#import "StopDetailViewController.h"
#import "AppDelegate.h"
#import "NextBusClient.h"
#import "Stop.h"
#import "Line.h"
#import "Favorite.h"
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
        
    UIImage *bgimage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"BackgroundTextured" ofType:@"png"]];
    [self.view setBackgroundColor:[UIColor colorWithPatternImage:bgimage]];
    
    self.stopName.text = self.stop.name;
    self.stopID.text = [NSString stringWithFormat:@"%@",self.stop.tag];
    
    self.primaryArrival.text = @"Fetching...";
    self.secondaryArrival.text = @"";
    
    if ([self isFavorite]) {
        [self.favoriteButton setTitle:@"Remove favorite" forState:UIControlStateNormal];
    } else {
        [self.favoriteButton setTitle:@"Add favorite" forState:UIControlStateNormal];
    }
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

- (IBAction)toggleFavorite:(id)sender
{
    if ([self isFavorite]) {
        // remove the favorite
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"FavoriteAdded" object:nil];
        [self.favoriteButton setTitle:@"Remove favorite" forState:UIControlStateNormal];
        // add the favorite
        [self performSelector:@selector(addFavorite) withObject:nil afterDelay:0.6];
    }
}

- (void)addFavorite
{
    AppDelegate *app = [[UIApplication sharedApplication] delegate];
        
    Favorite *fav = [NSEntityDescription insertNewObjectForEntityForName:@"Favorite" inManagedObjectContext:app.managedObjectContext];
    
    int max = [self maxFavoriteOrder] + 1;
    
    [fav setIsInbound:[NSNumber numberWithBool:self.isInbound]];
    [fav setLine:self.line];
    [fav setStop:self.stop];
    [fav setOrder:[NSNumber numberWithInt:max]];
    
    NSError *err;
    if (![app.managedObjectContext save:&err]) {
        NSLog(@"Whoops, error saving favorite data: %@",[err localizedDescription]);
    }
}

- (int)maxFavoriteOrder
{
    AppDelegate *app = [[UIApplication sharedApplication] delegate];
    
    NSFetchRequest *fetch = [NSFetchRequest fetchRequestWithEntityName:@"Favorite"];
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"order" ascending:NO];
    
    [fetch setSortDescriptors:[NSArray arrayWithObject:sort]];
    
    [fetch setFetchLimit:1];
    
    NSError *err;
    NSArray *maxfav = [app.managedObjectContext executeFetchRequest:fetch error:&err];
    
    int maxorder = 0;
    if ([maxfav count] == 1) {
        maxorder = [[[maxfav objectAtIndex:0] order] integerValue];
    }
    
    return maxorder;
}

- (BOOL)isFavorite
{
    AppDelegate *app = [[UIApplication sharedApplication] delegate];
    
    NSFetchRequest *req = [NSFetchRequest fetchRequestWithEntityName:@"Favorite"];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@ && %K == %@",@"stop",self.stop,@"line",self.line];
    
    [req setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *results = [app.managedObjectContext executeFetchRequest:req error:&error];
    if (!results) {
        NSLog(@"Fetch error: %@", error);
        abort();
    }
    if ([results count] == 0) {
        return NO;
    }
    return YES;
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
