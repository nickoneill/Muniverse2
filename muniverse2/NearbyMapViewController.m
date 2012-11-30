//
//  NearbyMapViewController.m
//  muniverse2
//
//  Created by Nick O'Neill on 8/29/12.
//  Copyright (c) 2012 Nick O'Neill. All rights reserved.
//

#import "NearbyMapViewController.h"
#import <MapKit/MapKit.h>
#import "MKMapView+ZoomLevel.h"
#import "AppDelegate.h"
#import "Stop.h"
#import "Line.h"
#import "Favorite.h"
#import "MuniPinAnnotation.h"
#import "GroupedPredictionCell.h"
#import "ClusterAnnotation.h"
#import "SmallClusterAnnotation.h"
#import "NextBusClient.h"
#import "MuniUtilities.h"
#import "StopLoadOperation.h"

@interface NearbyMapViewController ()

@end

@implementation NearbyMapViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.autoRegionChange = NO;
        self.lastDisplayCluster = NO;
        self.loadedAnnotations = [[NSMutableArray alloc] init];
        self.queue = [[NSOperationQueue alloc] init];
        [self.queue setMaxConcurrentOperationCount:1];
        [self.queue setName:@"com.Muniverse.mapops"];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
        
    // hide the detail pane
    [self.detailView setFrame:CGRectMake(0, self.map.frame.size.height + 44, self.detailView.frame.size.width, self.map.frame.size.height - 184)];
    [[self.detailView viewWithTag:10] setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"Nearby_Detail_Bg.png"]]];
    
    UIImage *bgimage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Textured_App_Bg" ofType:@"png"]];
    [self.detailTable setBackgroundView:[[UIImageView alloc] initWithImage:bgimage]];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        // load all those stops
        NSFetchRequest *fetch = [NSFetchRequest fetchRequestWithEntityName:@"Stop"];
        [fetch setFetchLimit:4000];
        
        AppDelegate *app = [[UIApplication sharedApplication] delegate];
        
        NSError *err;
        self.loadedStops = [app.managedObjectContext executeFetchRequest:fetch error:&err];
        if (err != nil) {
            NSLog(@"There was an issue fetching nearby stops");
        }
    });
    
    // set up needed items for the refresh button states
    [self.navItem setRightBarButtonItem:nil];
    
    UIActivityIndicatorView *spin = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 30, 20)];
    self.refreshing = [[UIBarButtonItem alloc] initWithCustomView:spin];
    
    // center on downtown SF for starters
    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(37.766644, -122.414474);
    [self.map setCenterCoordinate:coord zoomLevel:11 animated:NO];
//    [self.map setUserTrackingMode:MKUserTrackingModeNone];
    
    self.shouldZoomToUser = YES;
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    // automatic changes in regions (triggered by us) are a special case
    if (self.autoRegionChange) {
        self.autoRegionChange = NO;
    } else {
        // we don't care to load stops we've moved away from
        [self.queue cancelAllOperations];
        
        // this will load all stops and process clusters async
        StopLoadOperation *loadOp = [[StopLoadOperation alloc] initWithNearby:self];
        
        [self.queue addOperation:loadOp];
    }
}


- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    if (self.shouldZoomToUser && userLocation.location.coordinate.latitude != 0) {
        CLLocationCoordinate2D loc = [userLocation.location coordinate];
        
        [self.map setCenterCoordinate:loc zoomLevel:14 animated:NO];
        
        self.shouldZoomToUser = NO;
    }
}

- (BOOL)checkRoughDistanceOf:(CLLocation *)locOne from:(CLLocation *)locTwo
{
    if (locOne.coordinate.latitude > locTwo.coordinate.latitude+SMALL_CLUSTER_DISTANCE || locOne.coordinate.latitude < locTwo.coordinate.latitude-SMALL_CLUSTER_DISTANCE || locOne.coordinate.longitude > locTwo.coordinate.longitude+SMALL_CLUSTER_DISTANCE || locOne.coordinate.longitude < locTwo.coordinate.longitude-SMALL_CLUSTER_DISTANCE) {
        return NO;
    }
    
    return YES;
}

- (void)clearCustomAnnoations
{
    NSLog(@"custom clear");
    // if we don't take care to not remove the user location it is either lost or constantly readded
    for (id annot in self.map.annotations) {
        if (![annot isKindOfClass:[MKUserLocation class]]) {
            [self.map removeAnnotation:annot];
        }
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    // detect the type of annotation and display the associated annotation view
    
    if ([annotation isKindOfClass:[MuniPinAnnotation class]]) {
        MKAnnotationView *pin = (MKAnnotationView *)[self.map dequeueReusableAnnotationViewWithIdentifier:@"pin"];
        
        if (!pin) {
            pin = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"MuniPin"];
            [pin setCanShowCallout:NO];
            [pin setDraggable:NO];
            [pin setCenterOffset:CGPointMake(0, -9)];
        }
        
        // change the pin style if it's a favorite already
        if ([[(MuniPinAnnotation *)annotation stop] isFavorite]) {
            [pin setImage:[UIImage imageNamed:@"StopPinFav.png"]];
        } else {
            [pin setImage:[UIImage imageNamed:@"StopPin.png"]];
        }
        
        return pin;
    } else if ([annotation isKindOfClass:[ClusterAnnotation class]]) {
        MKAnnotationView *cluster = [self.map dequeueReusableAnnotationViewWithIdentifier:@"cluster"];
        
        if (!cluster) {
            cluster = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"cluster"];
            [cluster setCanShowCallout:NO];
            [cluster setDraggable:NO];
        }
        [cluster setImage:[UIImage imageNamed:@"StopClusterBig.png"]];

        
        return cluster;
    } else if ([annotation isKindOfClass:[SmallClusterAnnotation class]]) {
        MKAnnotationView *cluster = [self.map dequeueReusableAnnotationViewWithIdentifier:@"smallcluster"];
        
        if (!cluster) {
            cluster = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"smallcluster"];
            [cluster setCanShowCallout:NO];
            [cluster setDraggable:NO];
        }
        [cluster setImage:[UIImage imageNamed:@"StopCluster.png"]];
        
        return cluster;
    } else if ([annotation isKindOfClass:[MKUserLocation class]]) {
        MKAnnotationView *user = [self.map viewForAnnotation:annotation];
        
        return user;
    }
        
    return nil;
}

- (void)adjustMapRegionForAnnotation:(MKAnnotationView *)annotationView {
    // this brings the selected annotation up the top center, where the callout looks best
    
	CGPoint mapViewOriginRelativeToParent = [self.map convertPoint:self.map.frame.origin toView:annotationView];
    
    CGFloat xPixelShift = mapViewOriginRelativeToParent.x + 150;
    CGFloat yPixelShift = mapViewOriginRelativeToParent.y + 10;
	
	//Calculate new center point, if needed
	if (xPixelShift || yPixelShift) {
		CGFloat pixelsPerDegreeLongitude = self.map.frame.size.width / self.map.region.span.longitudeDelta;
		CGFloat pixelsPerDegreeLatitude = self.map.frame.size.height / self.map.region.span.latitudeDelta;
		
		CLLocationDegrees longitudinalShift = -(xPixelShift / pixelsPerDegreeLongitude);
		CLLocationDegrees latitudinalShift = yPixelShift / pixelsPerDegreeLatitude;
		
		CLLocationCoordinate2D newCenterCoordinate = {self.map.region.center.latitude + latitudinalShift,
			self.map.region.center.longitude + longitudinalShift};
		
		[self.map setCenterCoordinate:newCenterCoordinate animated:YES];
	}
        
    self.autoRegionChange = YES;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    NSLog(@"logy");
    if ([view.annotation isKindOfClass:[MuniPinAnnotation class]]) {
        if ([self isAtStopZoomLevel]) {
            // actual callout annotation will be added at the end of this map transformation
            [self adjustMapRegionForAnnotation:view];
            
            // set the selected view for reference later
            self.selectedAnnotationView = view;

            [self openDetail];
        } else {
            CLLocationCoordinate2D coord = [view.annotation coordinate];
            
            // zoom to the annoation we may have tapped on
            [self.map setCenterCoordinate:coord zoomLevel:17 animated:YES];
        }        
    } else if ([view.annotation isKindOfClass:[ClusterAnnotation class]]) {
        CLLocationCoordinate2D coord = [view.annotation coordinate];
        
        // zoom to the annoation we may have tapped on
        [self.map setCenterCoordinate:coord zoomLevel:15 animated:YES];
    } else if ([view.annotation isKindOfClass:[SmallClusterAnnotation class]]) {
        CLLocationCoordinate2D coord = [view.annotation coordinate];
        
        // zoom to the annoation we may have tapped on
        [self.map setCenterCoordinate:coord zoomLevel:17 animated:YES];
    }
}

- (void)toggleFavorite
{
    MuniPinAnnotation *pin = self.selectedAnnotationView.annotation;
    Stop *stop = pin.stop;

    AppDelegate *app = [[UIApplication sharedApplication] delegate];
    
    if ([stop isFavorite]) {
        
        NSFetchRequest *req = [NSFetchRequest fetchRequestWithEntityName:@"Favorite"];
        
        // could potentially remove multiple favorite stops for different lines with this... not sure if that's a common use case
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@",@"stop",stop];
        
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
        
        [self.selectedAnnotationView setImage:[UIImage imageNamed:@"StopPin.png"]];
        [(UIButton *)[self.detailView viewWithTag:12] setImage:[UIImage imageNamed:@"FavoriteButton-off.png"] forState:UIControlStateNormal];
    } else {
        // pick a line

        if ([self.linesCache count] > 1) {
            UIActionSheet *action = [[UIActionSheet alloc] init];
            [action setDelegate:self];
            [action setTitle:@"Please select a line"];
            
            for (Line *line in self.linesCache) {
                [action addButtonWithTitle:line.name];
            }
            
            [action addButtonWithTitle:@"Cancel"];
            [action setCancelButtonIndex:[self.linesCache count]];
            
            [action showFromTabBar:self.tabBarController.tabBar];
        } else {
            [(UIButton *)[self.detailView viewWithTag:12] setImage:[UIImage imageNamed:@"FavoriteButton-on.png"] forState:UIControlStateNormal];
            [self performSelector:@selector(addFavoriteForCurrentStopAndLine:) withObject:self.linesCache[0] afterDelay:0.6];

            [[NSNotificationCenter defaultCenter] postNotificationName:@"FavoriteAdded" object:nil];
        }
    }
}

- (void)addFavoriteForCurrentStopAndLine:(Line *)line
{
    AppDelegate *app = [[UIApplication sharedApplication] delegate];
    MuniPinAnnotation *pin = self.selectedAnnotationView.annotation;
    Stop *stop = pin.stop;
    
    Favorite *fav = [NSEntityDescription insertNewObjectForEntityForName:@"Favorite" inManagedObjectContext:app.managedObjectContext];
    
    int max = [MuniUtilities maxFavoriteOrder] + 1;
    
    [fav setIsInbound:[NSNumber numberWithBool:[MuniUtilities isStop:stop inboundForLine:line]]];
    [fav setLine:line];
    [fav setStop:stop];
    [fav setOrder:[NSNumber numberWithInt:max]];
    
    NSError *err;
    if (![app.managedObjectContext save:&err]) {
        NSLog(@"Whoops, error saving favorite data: %@",[err localizedDescription]);
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != actionSheet.cancelButtonIndex) {
        [self.selectedAnnotationView setImage:[UIImage imageNamed:@"StopPinFav.png"]];
        [(UIButton *)[self.detailView viewWithTag:12] setImage:[UIImage imageNamed:@"FavoriteButton-on.png"] forState:UIControlStateNormal];
        
        [self performSelector:@selector(addFavoriteForCurrentStopAndLine:) withObject:self.linesCache[buttonIndex] afterDelay:0.6];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"FavoriteAdded" object:nil];
    }
}

- (void)openDetail
{
    [self.navItem setRightBarButtonItem:self.refresh];
    
    // load data for the stop
    [self loadLinesForSelectedStop];
    
    MuniPinAnnotation *pin = self.selectedAnnotationView.annotation;
    Stop *stop = pin.stop;
    
    [(UILabel *)[self.detailView viewWithTag:11] setText:stop.name];
    [(UILabel *)[self.detailView viewWithTag:13] setText:[NSString stringWithFormat:@"Stop #%@",stop.tag]];
    
    if ([stop isFavorite]) {
        [(UIButton *)[self.detailView viewWithTag:12] setImage:[UIImage imageNamed:@"FavoriteButton-on.png"] forState:UIControlStateNormal];
    } else {
        [(UIButton *)[self.detailView viewWithTag:12] setImage:[UIImage imageNamed:@"FavoriteButton-off.png"] forState:UIControlStateNormal];
    }
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeDetail)];
    [self.map addGestureRecognizer:tap];
    
    // animate open the drawer
    [UIView animateWithDuration:0.3 animations:^{
        [self.detailView setFrame:CGRectMake(0, 184, self.detailView.frame.size.width, self.map.frame.size.height - 184)];
    }];
}

- (IBAction)closeDetail
{
    [self.navItem setRightBarButtonItem:nil];
    
    for (UIGestureRecognizer *gest in self.map.gestureRecognizers) {
        [self.map removeGestureRecognizer:gest];
    }
    
    // close the drawer
    [UIView animateWithDuration:0.3 animations:^{
        [self.detailView setFrame:CGRectMake(0, self.map.frame.size.height + 44, self.detailView.frame.size.width, self.map.frame.size.height - 184)];
    }];
}

- (IBAction)recenter
{
    CLLocation *loc = [[self.map userLocation] location];
    
    [self.map setCenterCoordinate:[loc coordinate] zoomLevel:16 animated:NO];
}

- (BOOL)isAtStopZoomLevel
{
    float regionsize = self.map.region.span.latitudeDelta;
    
    if (regionsize <= 0.0032) {
        return YES;
    }
    
    return NO;
}

// this stop could be used for inbound, outbound or a combination of the two
- (void)loadLinesForSelectedStop
{
    NSManagedObjectContext *moc = [(AppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
    
    MuniPinAnnotation *pin = self.selectedAnnotationView.annotation;
    
    // fetch potential inbound stops
    NSFetchRequest *inboundReq = [NSFetchRequest fetchRequestWithEntityName:@"Line"];
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"%@ IN %K",pin.stop,@"inboundStops"];
    [inboundReq setPredicate:pred];
    
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"allLinesSort" ascending:YES];
    [inboundReq setSortDescriptors:[NSArray arrayWithObject:sort]];
    
    NSError *err;
    self.linesCache = [moc executeFetchRequest:inboundReq error:&err];
    if (err != nil) {
        NSLog(@"issue with inbound stops: %@",[err localizedDescription]);
    }
    
    // fetch potential outbound stops
    NSFetchRequest *outboundReq = [NSFetchRequest fetchRequestWithEntityName:@"Line"];
    
    pred = [NSPredicate predicateWithFormat:@"%@ IN %K",pin.stop,@"outboundStops"];
    [outboundReq setPredicate:pred];
    
    [outboundReq setSortDescriptors:[NSArray arrayWithObject:sort]];

    NSArray *outboundLines = [moc executeFetchRequest:outboundReq error:&err];
    if (err != nil) {
        NSLog(@"issue with outbound stops: %@",[err localizedDescription]);
    }

    if ([outboundLines count]) {
        self.linesCache = [self.linesCache arrayByAddingObjectsFromArray:outboundLines];
    }
    
    [self.detailTable reloadData];
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
    return [self.linesCache count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    GroupedPredictionCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GPCell"];
    
    MuniPinAnnotation *pin = self.selectedAnnotationView.annotation;
    Line *line = [self.linesCache objectAtIndex:[indexPath row]];
    
    if ([line.metro boolValue]) {
        [cell.lineIcon setImage:[UIImage imageNamed:[NSString stringWithFormat:@"Subway_Icon_%@.png",line.shortname]]];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"GPCellText"];
    }
    
    [cell.primaryText setText:line.name];
    if ([line.inboundStops containsObject:pin.stop]) {
        [cell.secondaryText setText:line.inboundDesc];
    } else {
        [cell.secondaryText setText:line.outboundDesc];
    }
    
    cell.primaryPrediction.text = @"";
    cell.secondaryPrediction.text = @"";
    
    return cell;
}

- (IBAction)refreshPredictions
{
    [self.navItem setRightBarButtonItem:self.refreshing];
    [(UIActivityIndicatorView *)self.refreshing.customView startAnimating];

    NextBusClient *client = [[NextBusClient alloc] init];
    
    Stop *stop = [(MuniPinAnnotation *)self.selectedAnnotationView.annotation stop];
    for (int i = 0; i < [self.linesCache count]; i++) {
        Line *line = [self.linesCache objectAtIndex:i];
        
        NSString *lineTag = @"";
        if ([line.inboundStops containsObject:stop]) {
            lineTag = line.inboundTags;
        } else if ([line.outboundStops containsObject:stop]) {
            lineTag = line.outboundTags;
        }
                
        [client predictionForLineTag:lineTag atStopId:[[stop stopId] intValue] withSuccess:^(NSArray *els) {
            GroupedPredictionCell *cell = (GroupedPredictionCell *)[self.detailTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            
            if ([els count]) {
                cell.primaryPrediction.text = [NextBusClient formattedTimeFromNumer:[els objectAtIndex:0]];
                
                if ([els count] > 1) {
                    cell.secondaryPrediction.text = [NextBusClient formattedTimeFromNumer:[els objectAtIndex:1]];
                } else {
                    cell.secondaryPrediction.text = @"--";
                }
            } else {
                cell.primaryPrediction.text = @"";
                cell.secondaryPrediction.text = @"!";
            }

            [(UIActivityIndicatorView *)self.refreshing.customView stopAnimating];
            [self.navItem setRightBarButtonItem:self.refresh];
        } andFailure:^(NSError *err) {
            NSLog(@"failed getting predictions: %@",[err localizedDescription]);

            [(UIActivityIndicatorView *)self.refreshing.customView stopAnimating];
            [self.navItem setRightBarButtonItem:self.refresh];
        }];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end

