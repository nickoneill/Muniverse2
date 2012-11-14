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
#import "CalloutAnnotation.h"
#import "CalloutAnnotationView.h"
#import "MuniPinAnnotation.h"
#import "GroupedPredictionCell.h"
#import "CluserAnnotationView.h"
#import "ClusterAnnotation.h"
#import "NextBusClient.h"
#import "MuniUtilities.h"

@interface NearbyMapViewController ()

@end

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
    [[self.detailView viewWithTag:10] setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"NearbyDetailBg.png"]]];
    
    UIImage *bgimage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"BackgroundTextured" ofType:@"png"]];
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
    
    if (self.map.region.span.latitudeDelta <= 0.02) {
        // under a certain distance, we can display the stops themselves
        
        if (self.lastDisplayCluster) {
            // remove cluster annotations if that was the last thing we annotated
            // this is used to persist the stop annotations between drags, it could potentially slow down if someone dragged a lot but small use case, I think
            [self.map removeAnnotations:self.map.annotations];
            self.lastDisplayCluster = NO;
        }
        
        // pick stops from the cache for the current region
        for (Stop *stop in self.loadedStops) {
            if ([stop.lat floatValue] >= mincoord.latitude && [stop.lat floatValue] <= maxcoord.latitude && [stop.lon floatValue] >= mincoord.longitude && [stop.lon floatValue] <= maxcoord.longitude) {

                MuniPinAnnotation *point = [[MuniPinAnnotation alloc] init];
                [point setStop:stop];
                [point setCoordinate:CLLocationCoordinate2DMake([stop.lat floatValue], [stop.lon floatValue])];
                [self.map addAnnotation:point];
            }
        }
    } else if (self.map.region.span.latitudeDelta <= 0.16) {
        // VERY crude implementation of clustering
        // divide the current region into smaller squares (tune more/less by changing the divisions)
        // then sum up stops in that region, and weighted-average the stop coordinates
        [self.map removeAnnotations:self.map.annotations];
        
        int divisions = 5;
        
        for (int i = 0; i < divisions; i++) {
            for (int j = 0; j < divisions; j++) {
                CLLocationCoordinate2D minBox = {mincoord.latitude + ((region.span.latitudeDelta/divisions)*i), mincoord.longitude + ((region.span.longitudeDelta/divisions)*j)};
                CLLocationCoordinate2D maxBox = {minBox.latitude + region.span.latitudeDelta/divisions, minBox.longitude + region.span.longitudeDelta/divisions};
                
                int stopCount = 0;
                CLLocationCoordinate2D avg = CLLocationCoordinate2DMake(0, 0);
                for (Stop *stop in self.loadedStops) {
                    if ([stop.lat floatValue] >= minBox.latitude && [stop.lat floatValue] <= maxBox.latitude && [stop.lon floatValue] >= minBox.longitude && [stop.lon floatValue] <= maxBox.longitude) {
                        
                        if (avg.latitude == 0) {
                            avg = CLLocationCoordinate2DMake([stop.lat floatValue], [stop.lon floatValue]);
                        } else {
                            avg = CLLocationCoordinate2DMake((avg.latitude + [stop.lat floatValue])/2, (avg.longitude + [stop.lon floatValue])/2);
                        }
                        
                        stopCount++;
                    }
                }
                
                ClusterAnnotation *point = [[ClusterAnnotation alloc] init];
                [point setClusterCount:[NSNumber numberWithInt:stopCount]];
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
        
        if ([[(MuniPinAnnotation *)annotation stop] isFavorite]) {
            [pin setImage:[UIImage imageNamed:@"StopPinFav.png"]];
        } else {
            [pin setImage:[UIImage imageNamed:@"StopPin.png"]];
        }
        
        return pin;
    } else if ([annotation isKindOfClass:[ClusterAnnotation class]]) {
        CluserAnnotationView *cluster = (CluserAnnotationView *)[self.map dequeueReusableAnnotationViewWithIdentifier:@"cluster"];
        
        if (!cluster) {
            cluster = [[CluserAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"cluster"];
        }
        [cluster.clusterCount setText:[NSString stringWithFormat:@"%@",[(ClusterAnnotation *)annotation clusterCount]]];
        
        return cluster;
    }
        
    return nil;
}

- (void)adjustMapRegionForAnnotation:(MKAnnotationView *)annotationView {
    // this brings the selected annotation up the top center, where the callout looks best
    
	CGPoint mapViewOriginRelativeToParent = [self.map convertPoint:self.map.frame.origin toView:annotationView];
    
    CGFloat xPixelShift = mapViewOriginRelativeToParent.x + 136;
    CGFloat yPixelShift = mapViewOriginRelativeToParent.y + 25;
	
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
            [self.map setCenterCoordinate:coord zoomLevel:16 animated:YES];
        }        
    }
}

- (void)toggleFavorite
{
    NSLog(@"favorite");
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
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(closeDetail)];
    [self.map addGestureRecognizer:pan];
    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(closeDetail)];
    [self.map addGestureRecognizer:pinch];
    UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(closeDetail)];
    [self.map addGestureRecognizer:swipe];
    UIRotationGestureRecognizer *rot = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(closeDetail)];
    [self.map addGestureRecognizer:rot];
    
    // animate open the drawer
    [UIView animateWithDuration:0.3 animations:^{
        [self.detailView setFrame:CGRectMake(0, 184, self.detailView.frame.size.width, self.map.frame.size.height - 184)];
    }];
}

- (void)closeDetail
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

//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
//{
//    return @"Lines for this stop:";
//}

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

