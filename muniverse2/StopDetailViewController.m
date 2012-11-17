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
#import "MuniUtilities.h"
#import "Stop.h"
#import "Line.h"
#import "Favorite.h"

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

    // subscribe to the application becoming active after being in the background
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshPredictions) name:@"becameActive" object:nil];


    UIImage *bgimage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"TexturedBackground" ofType:@"png"]];
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
    
    UIImage *buttonBg = [[UIImage imageNamed:@"blueButton.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(18, 18, 18, 18)];
    [self.favoriteButton setBackgroundImage:buttonBg forState:UIControlStateNormal];
    
    // set up needed items for the refresh button states
    UIActivityIndicatorView *spin = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 30, 20)];
    [spin setTag:1];
    self.refreshing = [[UIBarButtonItem alloc] initWithCustomView:spin];
    
    [self refreshPredictions];
}

- (IBAction)refreshPredictions
{
    [[self navigationItem] setRightBarButtonItem:self.refreshing];
    [(UIActivityIndicatorView *)self.refreshing.customView startAnimating];
    
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
        
        [(UIActivityIndicatorView *)self.refreshing.customView stopAnimating];
        [[self navigationItem] setRightBarButtonItem:self.refresh];
    } andFailure:^(NSError * err) {
        NSLog(@"some failure: %@",err);
        
        [(UIActivityIndicatorView *)self.refreshing.customView stopAnimating];
        [[self navigationItem] setRightBarButtonItem:self.refresh];
    }];
}

- (IBAction)toggleFavorite:(id)sender
{
    if ([self isFavorite]) {
        [self removeFavorite];
        
        [self.favoriteButton setTitle:@"Add favorite" forState:UIControlStateNormal];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"FavoriteAdded" object:nil];
        [self.favoriteButton setTitle:@"Remove favorite" forState:UIControlStateNormal];

        [self performSelector:@selector(addFavorite) withObject:nil afterDelay:0.6];
    }
}

- (void)removeFavorite
{
    AppDelegate *app = [[UIApplication sharedApplication] delegate];
    
    NSFetchRequest *req = [NSFetchRequest fetchRequestWithEntityName:@"Favorite"];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@ && %K == %@",@"stop",self.stop,@"line",self.line];
    
    [req setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *results = [app.managedObjectContext executeFetchRequest:req error:&error];
    if (error) {
        NSLog(@"there was an error getting the favorite: %@",[error localizedDescription]);
    }
    
    for (Favorite *fav in results) {
        [app.managedObjectContext deleteObject:fav];
    }
    
    [app.managedObjectContext save:&error];
    if (error) {
        NSLog(@"error saving context after delete: %@",[error localizedDescription]);
    }
}

- (void)addFavorite
{
    AppDelegate *app = [[UIApplication sharedApplication] delegate];
        
    Favorite *fav = [NSEntityDescription insertNewObjectForEntityForName:@"Favorite" inManagedObjectContext:app.managedObjectContext];
    
    int max = [MuniUtilities maxFavoriteOrder] + 1;
    
    [fav setIsInbound:[NSNumber numberWithBool:self.isInbound]];
    [fav setLine:self.line];
    [fav setStop:self.stop];
    [fav setOrder:[NSNumber numberWithInt:max]];
    
    NSError *err;
    if (![app.managedObjectContext save:&err]) {
        NSLog(@"Whoops, error saving favorite data: %@",[err localizedDescription]);
    }
}

- (BOOL)isFavorite
{
    AppDelegate *app = [[UIApplication sharedApplication] delegate];
    
    NSFetchRequest *req = [NSFetchRequest fetchRequestWithEntityName:@"Favorite"];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@ && %K == %@",@"stop",self.stop,@"line",self.line];
    
    [req setPredicate:predicate];
    
    NSError *error;
    int resultCount = [app.managedObjectContext countForFetchRequest:req error:&error];
    if (error) {
        NSLog(@"count error: %@", error);
    }
    if (resultCount == 0) {
        return NO;
    }
    
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
