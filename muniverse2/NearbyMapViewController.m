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
    
    [self.detailView setFrame:CGRectMake(0, self.map.frame.size.height + 44, self.detailView.frame.size.width, self.map.frame.size.height - 100)];
    
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
        [self.map addAnnotation:self.calloutAnnotation];
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
    
    if ([annotation isKindOfClass:[CalloutAnnotation class]]) {
        CalloutAnnotationView *callout = (CalloutAnnotationView *)[self.map dequeueReusableAnnotationViewWithIdentifier:@"callout"];
        if (!callout) {
            callout = [[CalloutAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"callout"];
            callout.mapView = self.map;
            
//            UIImageView *favorite = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Stop_Fav_Off.png"]];
//            [favorite setFrame:CGRectMake(1, 3, 48, 48)];

            UIButton *favButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [favButton setFrame:CGRectMake(1, 3, 48, 48)];
            [favButton setImage:[UIImage imageNamed:@"Stop_Fav_Off.png"] forState:UIControlStateNormal];
            [favButton addTarget:self action:@selector(favorite:) forControlEvents:UIControlEventTouchUpInside];
            [callout.contentView addSubview:favButton];
            
            UILabel *calloutLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 2, 230, 24)];
            [calloutLabel setTag:1];
            [calloutLabel setFont:[UIFont boldSystemFontOfSize:22]];
            [calloutLabel setTextColor:[UIColor whiteColor]];
            [calloutLabel setShadowColor:[UIColor blackColor]];
            [calloutLabel setShadowOffset:CGSizeMake(1, 1)];
            [calloutLabel setBackgroundColor:[UIColor clearColor]];
            [callout.contentView addSubview:calloutLabel];

            UILabel *calloutsubLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 28, 230, 18)];
            [calloutsubLabel setTag:2];
            [calloutsubLabel setFont:[UIFont systemFontOfSize:16]];
            [calloutsubLabel setTextColor:[UIColor whiteColor]];
//            [calloutsubLabel setShadowColor:[UIColor blackColor]];
//            [calloutsubLabel setShadowOffset:CGSizeMake(1, 1)];
            [calloutsubLabel setBackgroundColor:[UIColor clearColor]];
            [callout.contentView addSubview:calloutsubLabel];
        }
        
        MuniPinAnnotation *pin = self.selectedAnnotationView.annotation;
        [(UILabel *)[callout.contentView viewWithTag:1] setText:pin.stop.name];
        [(UILabel *)[callout.contentView viewWithTag:2] setText:[NSString stringWithFormat:@"Stop #%@",pin.stop.tag]];
        
        callout.parentAnnotationView = self.selectedAnnotationView;
        
        return callout;
    } else if ([annotation isKindOfClass:[MuniPinAnnotation class]]) {
        MKAnnotationView *pin = (MKAnnotationView *)[self.map dequeueReusableAnnotationViewWithIdentifier:@"pin"];
        
        if (!pin) {
            pin = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"MuniPin"];
            [pin setCanShowCallout:NO];
            [pin setImage:[UIImage imageNamed:@"StopPin.png"]];
            [pin setDraggable:NO];
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
    
    CGFloat xPixelShift = mapViewOriginRelativeToParent.x + 150;
    CGFloat yPixelShift = mapViewOriginRelativeToParent.y + 40;
	
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
    
    // and finally add the annotation view we wanted
    if (self.calloutAnnotation == nil) {
        self.calloutAnnotation = [[CalloutAnnotation alloc] initWithLatitude:annotationView.annotation.coordinate.latitude andLongitude:annotationView.annotation.coordinate.longitude];
    } else {
        self.calloutAnnotation.coordinate = CLLocationCoordinate2DMake(annotationView.annotation.coordinate.latitude, annotationView.annotation.coordinate.longitude);
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

            // animate and update the detail view
            [self loadLinesForSelectedStop];
            [UIView animateWithDuration:0.3 animations:^{
                [self.detailView setFrame:CGRectMake(0, 144, self.detailView.frame.size.width, self.map.frame.size.height - 100)];
            }];
        } else {
            CLLocationCoordinate2D coord = [view.annotation coordinate];
            
            // zoom to the annoation we may have tapped on
            [self.map setCenterCoordinate:coord zoomLevel:16 animated:YES];
        }        
    }
}

- (void)favorite:(id)sender
{
    NSLog(@"favorite");
}

- (IBAction)closeDetail
{
    [self.map removeAnnotation:self.calloutAnnotation];
    
    [UIView animateWithDuration:0.3 animations:^{
        [self.detailView setFrame:CGRectMake(0, self.map.frame.size.height + 44, self.detailView.frame.size.width, self.map.frame.size.height - 100)];
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

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"Lines for this stop:";
}

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
    static NSString *CellIdentifier = @"GPCell";
    GroupedPredictionCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    MuniPinAnnotation *pin = self.selectedAnnotationView.annotation;
    Line *line = [self.linesCache objectAtIndex:[indexPath row]];
    
    if ([line.metro boolValue]) {
        [cell.lineIcon setHidden:NO];
        [cell.lineIcon setImage:[UIImage imageNamed:[NSString stringWithFormat:@"Subway_Icon_%@.png",line.shortname]]];
        
        [cell.primaryText setFrame:CGRectMake(50, cell.primaryText.frame.origin.y, cell.primaryText.frame.size.width, cell.primaryText.frame.size.height)];
        [cell.secondaryText setFrame:CGRectMake(50, cell.secondaryText.frame.origin.y, cell.secondaryText.frame.size.width, cell.secondaryText.frame.size.height)];
    } else {
        [cell.lineIcon setHidden:YES];
        
        [cell.primaryText setFrame:CGRectMake(10, cell.primaryText.frame.origin.y, cell.primaryText.frame.size.width, cell.primaryText.frame.size.height)];
        [cell.secondaryText setFrame:CGRectMake(10, cell.secondaryText.frame.origin.y, cell.secondaryText.frame.size.width, cell.secondaryText.frame.size.height)];
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

