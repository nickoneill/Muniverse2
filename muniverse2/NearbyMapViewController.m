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

@interface NearbyMapViewController ()

@end

#define SMALL_CLUSTER_DISTANCE 60

@implementation NearbyMapViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.autoRegionChange = NO;
        self.lastDisplayCluster = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.detailView setFrame:CGRectMake(0, self.map.frame.size.height + 44, self.detailView.frame.size.width, self.map.frame.size.height - 184)];
    [[self.detailView viewWithTag:10] setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"Nearby_Detail_Bg.png"]]];
    
    UIImage *bgimage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Textured_App_Bg" ofType:@"png"]];
    [self.detailTable setBackgroundView:[[UIImageView alloc] initWithImage:bgimage]];
    
    NSFetchRequest *fetch = [NSFetchRequest fetchRequestWithEntityName:@"Stop"];
    [fetch setFetchLimit:4000];
    
    AppDelegate *app = [[UIApplication sharedApplication] delegate];
    
    NSError *err;
    self.loadedStops = [app.managedObjectContext executeFetchRequest:fetch error:&err];
    if (err != nil) {
        NSLog(@"There was an issue fetching nearby stops");
    }
    
    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(37.766644, -122.414474);
    [self.map setCenterCoordinate:coord zoomLevel:11 animated:NO];
    [self.map setUserTrackingMode:MKUserTrackingModeNone];
    
    self.shouldZoomToUser = YES;
}

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated
{
    //
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    // automatic changes in regions (triggered by us) are a special case
    if (self.autoRegionChange) {
        self.autoRegionChange = NO;
    } else {
        [self displayStops];
    }
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
//    NSLog(@"updated user location %f %f",[userLocation.location coordinate].latitude,[userLocation.location coordinate].longitude);
    
    if (self.shouldZoomToUser && userLocation.location.coordinate.latitude != 0) {
        CLLocationCoordinate2D loc = [userLocation.location coordinate];
        
        [self.map setCenterCoordinate:loc zoomLevel:14 animated:NO];
        
        self.shouldZoomToUser = NO;
    }
}

- (void)displayStops
{
    // loading stops all the way to the edge of the screen feels weird, this adjusts that in slightly
    float adjustment = -0.0005;
    
    MKCoordinateRegion region = [self.map region];
    CLLocationCoordinate2D mincoord;
    mincoord.latitude = region.center.latitude - (region.span.latitudeDelta/2) - adjustment;
    mincoord.longitude = region.center.longitude - (region.span.longitudeDelta/2) - adjustment;
    CLLocationCoordinate2D maxcoord;
    maxcoord.latitude = region.center.latitude + (region.span.latitudeDelta/2) + adjustment;
    maxcoord.longitude = region.center.longitude + (region.span.longitudeDelta/2) + adjustment;
    
    if (self.map.region.span.latitudeDelta <= 0.005) {
        // display all stops if we're real close
        
        if (self.lastDisplayCluster) {
            // remove cluster annotations if that was the last thing we annotated
            // this is used to persist the stop annotations between drags, it could potentially slow down if someone dragged a lot but small use case, I think
            [self.map removeAnnotations:self.map.annotations];
            self.lastDisplayCluster = NO;
        }
        
        // pick stops from the cache for the current region
        for (Stop *stop in self.loadedStops) {
            MKMapPoint point = MKMapPointForCoordinate(CLLocationCoordinate2DMake([stop.lat floatValue], [stop.lon floatValue]));
            
            if (MKMapRectContainsPoint(self.map.visibleMapRect, point)) {
                MuniPinAnnotation *point = [[MuniPinAnnotation alloc] init];
                [point setStop:stop];
                [point setCoordinate:CLLocationCoordinate2DMake([stop.lat floatValue], [stop.lon floatValue])];
                [self.map addAnnotation:point];
            }
        }
        
    } else if (self.map.region.span.latitudeDelta <= 0.03) {
        // display stops with some clusters if we're somewhat close
        
        [self.map removeAnnotations:self.map.annotations];

        // pick stops from the cache for the current region
        NSMutableArray *visibleStops = [NSMutableArray array];
        for (Stop *stop in self.loadedStops) {
            MKMapPoint point = MKMapPointForCoordinate(CLLocationCoordinate2DMake([stop.lat floatValue], [stop.lon floatValue]));

            if (MKMapRectContainsPoint(self.map.visibleMapRect, point)) {
                [visibleStops addObject:stop];
            }
        }
        
        // stop clusters stores the current clusters as they're built
        // ignore stops is the stops we've used, we want to treat them as clusters (but can't mutate the array we're enumerating
        NSMutableArray *stopClusters = [NSMutableArray array];
        NSMutableArray *ignoreStops = [NSMutableArray array];
        for (Stop *stop in visibleStops) {
            if (![ignoreStops containsObject:stop]) {
                CLLocation *stopLoc = [[CLLocation alloc] initWithLatitude:[stop.lat floatValue] longitude:[stop.lon floatValue]];
                
                // if we're added to a cluster, we don't want to take any other action afterwards
                BOOL addedToCluster = NO;
                for (NSArray __strong *cluster in stopClusters) {
                    float avgLat = 0;
                    float avgLon = 0;
                    
                    for (Stop *clusterStop in cluster) {
                        avgLat += [clusterStop.lat floatValue];
                        avgLon += [clusterStop.lon floatValue];
                    }
                    int clusterCount = [cluster count];
                    
                    CLLocation *avgLoc = [[CLLocation alloc] initWithLatitude:avgLat/clusterCount longitude:avgLon/clusterCount];
                    // the center of the cluster matching region changes subtley with an additional stop, but less impact with each additional stop added
                    if ([stopLoc distanceFromLocation:avgLoc] <= SMALL_CLUSTER_DISTANCE) {
                        [ignoreStops addObject:stop];
                        cluster = [cluster arrayByAddingObject:stop];
                        addedToCluster = YES;
                    }
                }

                // if we're not added to a cluster, we check if we're close to any other stops for forming new clusters
                if (!addedToCluster) {
                    for (Stop *otherStop in visibleStops) {
                        if (![ignoreStops containsObject:otherStop] && ![ignoreStops containsObject:stop]) {
                            CLLocation *otherStopLoc = [[CLLocation alloc] initWithLatitude:[otherStop.lat floatValue] longitude:[otherStop.lon floatValue]];
                            
                            if ([stopLoc distanceFromLocation:otherStopLoc] <= SMALL_CLUSTER_DISTANCE && [stopLoc distanceFromLocation:otherStopLoc] != 0.0) {
                                [ignoreStops addObjectsFromArray:@[stop,otherStop]];
                                [stopClusters addObject:@[stop, otherStop]];
                            }
                        }
                    }
                }
                
            }
        }
        
        // add all the stops that weren't added to clusters
        for (Stop *stop in visibleStops) {
            if (![ignoreStops containsObject:stop]) {
                MuniPinAnnotation *point = [[MuniPinAnnotation alloc] init];
                [point setStop:stop];
                [point setCoordinate:CLLocationCoordinate2DMake([stop.lat floatValue], [stop.lon floatValue])];
                [self.map addAnnotation:point];
            }
        }
        
        // add the clusters to the map
        for (NSArray *cluster in stopClusters) {
            float avgLat = 0;
            float avgLon = 0;
            
            for (Stop *stop in cluster) {
                avgLat += [stop.lat floatValue];
                avgLon += [stop.lon floatValue];
            }
            int clusterCount = [cluster count];
            
            CLLocation *avgLoc = [[CLLocation alloc] initWithLatitude:avgLat/clusterCount longitude:avgLon/clusterCount];

            SmallClusterAnnotation *clusterNote = [[SmallClusterAnnotation alloc] init];
            [clusterNote setCoordinate:[avgLoc coordinate]];
            [self.map addAnnotation:clusterNote];
        }
        
        self.lastDisplayCluster = YES;
    } else if (self.map.region.span.latitudeDelta <= 0.16) {
        // VERY crude implementation of clustering for zoomed out views
        // much faster than the more detailed model, but with significantly less accuracy
        //
        [self.map removeAnnotations:self.map.annotations];
        
        int divisions = 5;
        
        // divide the current region into smaller squares (tune more/less by changing the divisions)
        for (int i = 0; i < divisions; i++) {
            for (int j = 0; j < divisions; j++) {
                
                int stopCount = 0;
                CLLocationCoordinate2D avg = CLLocationCoordinate2DMake(0, 0);
                // then sum up stops in that region, and weighted-average the stop coordinates (for simplicity)
                for (Stop *stop in self.loadedStops) {
                    MKMapPoint point = MKMapPointForCoordinate(CLLocationCoordinate2DMake([stop.lat floatValue], [stop.lon floatValue]));
                    
                    if (MKMapRectContainsPoint(self.map.visibleMapRect, point)) {
                        if (avg.latitude == 0) {
                            avg = CLLocationCoordinate2DMake([stop.lat floatValue], [stop.lon floatValue]);
                        } else {
                            avg = CLLocationCoordinate2DMake((avg.latitude + [stop.lat floatValue])/2, (avg.longitude + [stop.lon floatValue])/2);
                        }
                        
                        stopCount++;
                    }
                }
                
                ClusterAnnotation *point = [[ClusterAnnotation alloc] init];
                [point setCoordinate:avg];
                
                [self.map addAnnotation:point];
            }
        }
        
        self.lastDisplayCluster = YES;
    } else {
        [self.map removeAnnotations:self.map.annotations];
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
    // load data for the stop
    [self loadLinesForSelectedStop];
    
    MuniPinAnnotation *pin = self.selectedAnnotationView.annotation;
    Stop *stop = pin.stop;
    
    [(UILabel *)[self.detailView viewWithTag:11] setText:stop.name];
    
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
    for (UIGestureRecognizer *gest in self.map.gestureRecognizers) {
        [self.map removeGestureRecognizer:gest];
    }
    
    // close the drawer
    [UIView animateWithDuration:0.3 animations:^{
        [self.detailView setFrame:CGRectMake(0, self.map.frame.size.height + 44, self.detailView.frame.size.width, self.map.frame.size.height - 184)];
    }];
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

- (void)refreshPredictions
{
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
                cell.secondaryPrediction.text = @"";
            }
        } andFailure:^(NSError *err) {
            NSLog(@"failed getting predictions: %@",[err localizedDescription]);
        }];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end

