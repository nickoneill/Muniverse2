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

@interface NearbyMapViewController ()

@end

@implementation NearbyMapViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.autoRegionChange = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.detailView setFrame:CGRectMake(0, self.map.frame.size.height + 44, self.detailView.frame.size.width, self.map.frame.size.height - 100)];
    
    UIImage *bgimage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"BackgroundTextured" ofType:@"png"]];
    [self.detailTable setBackgroundView:[[UIImageView alloc] initWithImage:bgimage]];
    
    self.loadedStops = [NSMutableArray array];
    
    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(37.766644, -122.414474);
	
    [self.map setCenterCoordinate:coord zoomLevel:11 animated:NO];
    
    self.shouldZoomToUser = YES;
}

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated
{
    // don't zoom to user if the region has been changed alredy
//    self.shouldZoomToUser = NO;
    
//    if (!self.shouldZoomToUser) {
//        [self loadAndDisplayStopsAroundCoordinate:[mapView region].center];
//    }
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    [self isAtStopZoomLevel];
    
    if (self.autoRegionChange) {
        [self.map addAnnotation:self.calloutAnnotation];
        self.autoRegionChange = NO;
    }
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    NSLog(@"updated user location");
    
    if (self.shouldZoomToUser) {
        CLLocationCoordinate2D loc = [userLocation.location coordinate];
        
        [self.map setCenterCoordinate:loc zoomLevel:14 animated:NO];
        
        [self loadAndDisplayStopsAroundCoordinate:loc];
        
        self.shouldZoomToUser = NO;
    }
}

- (void)loadAndDisplayStopsAroundCoordinate:(CLLocationCoordinate2D)coord
{
    float adjustment = 0.001;
    
    MKCoordinateRegion region = [self.map region];
    CLLocationCoordinate2D mincoord;
    mincoord.latitude = region.center.latitude - (region.span.latitudeDelta/2) + adjustment;
    mincoord.longitude = region.center.longitude - (region.span.longitudeDelta/2) + adjustment;
    CLLocationCoordinate2D maxcoord;
    maxcoord.latitude = region.center.latitude + (region.span.latitudeDelta/2) - adjustment;
    maxcoord.longitude = region.center.longitude + (region.span.longitudeDelta/2) - adjustment;
    
    NSFetchRequest *fetch = [NSFetchRequest fetchRequestWithEntityName:@"Stop"];
    
    NSPredicate *nearbyPredicate = [NSPredicate predicateWithFormat:@"%K > %f && %K < %f && %K > %f && %K < %f",@"lat",mincoord.latitude,@"lat",maxcoord.latitude,@"lon",mincoord.longitude,@"lon",maxcoord.longitude];
    [fetch setPredicate:nearbyPredicate];
    
    AppDelegate *app = [[UIApplication sharedApplication] delegate];
    
    NSError *err;
    NSArray *stops = [app.managedObjectContext executeFetchRequest:fetch error:&err];
    if (err != nil) {
        NSLog(@"There was an issue fetching nearby stops");
    }
    
    for (Stop *stop in stops) {
        if (![self.loadedStops containsObject:stop]) {
            [self.loadedStops addObject:stop];
            
            MuniPinAnnotation *point = [[MuniPinAnnotation alloc] init];
            [point setTitle:stop.name];
            [point setSubtitle:@"none"];
            [point setStop:stop];
            [point setCoordinate:CLLocationCoordinate2DMake([stop.lat floatValue], [stop.lon floatValue])];
            [self.map addAnnotation:point];
        }
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[CalloutAnnotation class]]) {
        CalloutAnnotationView *callout = (CalloutAnnotationView *)[self.map dequeueReusableAnnotationViewWithIdentifier:@"callout"];
        if (!callout) {
            callout = [[CalloutAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"callout"];
            callout.mapView = self.map;
                        
            UILabel *calloutLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 280, 50)];
            [calloutLabel setTag:1];
            [calloutLabel setFont:[UIFont systemFontOfSize:22]];
            [callout.contentView addSubview:calloutLabel];
        }
        MuniPinAnnotation *pin = self.selectedAnnotationView.annotation;
        [(UILabel *)[callout.contentView viewWithTag:1] setText:pin.title];
        
        callout.parentAnnotationView = self.selectedAnnotationView;
        
        return callout;
    } else if ([annotation isKindOfClass:[MuniPinAnnotation class]]) {
        MKAnnotationView *pin = (MKAnnotationView *)[self.map dequeueReusableAnnotationViewWithIdentifier:@"pin"];
        
        if (!pin) {
            pin = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"MuniPin"];
            [pin setCanShowCallout:NO];
            [pin setImage:[UIImage imageNamed:@"Pin_Circle.png"]];
            [pin setDraggable:NO];
        }
        
        return pin;
    }
    
    
//    UIButton *calloutButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
//    [calloutButton addTarget:self action:@selector(detail) forControlEvents:UIControlEventTouchUpInside];
//    [pin setRightCalloutAccessoryView:calloutButton];
    
//    UIButton *favoriteButton = [UIButton buttonWithType:UIButtonTypeCustom];
//    UIImageView *favoriteImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Stop_Fav_On.png"]];
//    [favoriteButton addSubview:favoriteImage];
//    [favoriteButton addTarget:self action:@selector(detail) forControlEvents:UIControlEventTouchUpInside];
//    [pin setLeftCalloutAccessoryView:favoriteButton];
    
    return nil;
}

- (void)adjustMapRegionForAnnotation:(MKAnnotationView *)annotationView {
	CGFloat xPixelShift = 0;
	CGFloat yPixelShift = 0;
	
	CGPoint mapViewOriginRelativeToParent = [self.map convertPoint:self.map.frame.origin toView:annotationView];
    
    xPixelShift = mapViewOriginRelativeToParent.x + 150;
    yPixelShift = mapViewOriginRelativeToParent.y + 40;
	
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

            MuniPinAnnotation *pin = view.annotation;
            NSLog(@"selected stop: %@ %@",pin.title,pin.stop);
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

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view {
//    [self.map removeAnnotation:self.calloutAnnotation];
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
    float regionsize = [self.map region].span.latitudeDelta;
    
    if (regionsize <= 0.0032) {
        return YES;
    }
    
    return NO;
}

- (void)loadLinesForSelectedStop
{
    NSManagedObjectContext *moc = [(AppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
    
    MuniPinAnnotation *pin = self.selectedAnnotationView.annotation;
    
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
    NSLog(@"count called");
    // Return the number of rows in the section.
    return [self.linesCache count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"GPCell";
    GroupedPredictionCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    MuniPinAnnotation *pin = self.selectedAnnotationView.annotation;
    Line *line = [self.linesCache objectAtIndex:[indexPath row]];
    
    cell.primaryText.text = line.shortname;
    cell.secondaryText.text = line.inboundDesc;
    
    if ([line.shortname isEqualToString:@"J"]) {
        cell.primaryText.text = @"Church";
        cell.lineIcon.image = [UIImage imageNamed:[NSString stringWithFormat:@"Subway_Icon_J.png"]];
        if ([line.inboundStops containsObject:pin.stop]) {
            cell.secondaryText.text = @"To Balboa Park Station";
        } else {
            cell.secondaryText.text = @"To Embarcadero Station";
        }
    } else if ([line.shortname isEqualToString:@"L"]) {
        cell.primaryText.text = @"Taraval";
        cell.lineIcon.image = [UIImage imageNamed:[NSString stringWithFormat:@"Subway_Icon_L.png"]];
        if ([line.inboundStops containsObject:pin.stop]) {
            cell.secondaryText.text = @"To SF Zoo";
        } else {
            cell.secondaryText.text = @"To Embarcadero Station";
        }
    } else if ([line.shortname isEqualToString:@"M"]) {
        cell.primaryText.text = @"Ocean View";
        cell.lineIcon.image = [UIImage imageNamed:[NSString stringWithFormat:@"Subway_Icon_M.png"]];
        if ([line.inboundStops containsObject:pin.stop]) {
            cell.secondaryText.text = @"To Balboa Park Station";
        } else {
            cell.secondaryText.text = @"To Embarcadero Station";
        }
    } else if ([line.shortname isEqualToString:@"N"]) {
        cell.primaryText.text = @"Judah";
        cell.lineIcon.image = [UIImage imageNamed:[NSString stringWithFormat:@"Subway_Icon_N.png"]];
        if ([line.inboundStops containsObject:pin.stop]) {
            cell.secondaryText.text = @"To Ocean Beach";
        } else {
            cell.secondaryText.text = @"To Ballpark/Caltrain";
        }
    } else if ([line.shortname isEqualToString:@"KT"]) {
        
        // special case to handle it being T outbound on the surface and K outbound in the tunnel
        
        if ([line.inboundStops containsObject:pin.stop]) {
            if (0) {
                cell.primaryText.text = @"Ingleside";
                cell.secondaryText.text = @"To Balboa Park Station";
                cell.lineIcon.image = [UIImage imageNamed:[NSString stringWithFormat:@"Subway_Icon_K.png"]];
            } else {
                cell.primaryText.text = @"Third Street";
                cell.secondaryText.text = @"To Embarcadero Station";
                cell.lineIcon.image = [UIImage imageNamed:[NSString stringWithFormat:@"Subway_Icon_T.png"]];
            }
        } else {
            cell.primaryText.text = @"Third Street";
            cell.secondaryText.text = @"To Sunnydale";
            cell.lineIcon.image = [UIImage imageNamed:[NSString stringWithFormat:@"Subway_Icon_T.png"]];
        }
    }
    
    cell.primaryPrediction.text = @"";
    cell.secondaryPrediction.text = @"";
    
    return cell;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end

