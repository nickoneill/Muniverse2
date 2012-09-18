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
#import "MuniAnnotation.h"

@interface NearbyMapViewController ()

@end

@implementation NearbyMapViewController

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
    
    [self.detailView setFrame:CGRectMake(0, 411, self.detailView.frame.size.width, self.detailView.frame.size.height)];
    
    UIImage *bgimage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"BackgroundTextured" ofType:@"png"]];
    [self.detailTable setBackgroundColor:[UIColor colorWithPatternImage:bgimage]];
    
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
    NSLog(@"region change %d",self.shouldZoomToUser);
    [self isAtStopZoomLevel];
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
            
            MuniAnnotation *point = [[MuniAnnotation alloc] init];
            [point setTitle:stop.name];
            [point setSubtitle:@"none"];
            [point setCoordinate:CLLocationCoordinate2DMake([stop.lat floatValue], [stop.lon floatValue])];
            [self.map addAnnotation:point];
        }
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id < MKAnnotation >)annotation
{
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }
    
    MKPinAnnotationView *pin = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"MuniPin"];
    [pin setCanShowCallout:YES];
    [pin setImage:[UIImage imageNamed:@"Pin_Circle.png"]];
    [pin setDraggable:NO];
    [pin setCalloutOffset:CGPointMake(0, 5)];
    
    UIButton *calloutButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    [calloutButton addTarget:self action:@selector(detail) forControlEvents:UIControlEventTouchUpInside];
    [pin setRightCalloutAccessoryView:calloutButton];
    
//    UIButton *favoriteButton = [UIButton buttonWithType:UIButtonTypeCustom];
//    UIImageView *favoriteImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Stop_Fav_On.png"]];
//    [favoriteButton addSubview:favoriteImage];
//    [favoriteButton addTarget:self action:@selector(detail) forControlEvents:UIControlEventTouchUpInside];
//    [pin setLeftCalloutAccessoryView:favoriteButton];
    
    return pin;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    CLLocationCoordinate2D coord = [(MuniAnnotation *)view.annotation coordinate];
    coord.latitude += 0.00035;
    
    if ([self isAtStopZoomLevel]) {
        [self.map setCenterCoordinate:coord animated:NO];
    } else {
        [self.map setCenterCoordinate:coord zoomLevel:16 animated:NO];
    }
    
    [UIView animateWithDuration:0.2 animations:^{
        [self.map setFrame:CGRectMake(0, 44, 320, 100)];
        [self.detailView setFrame:CGRectMake(0, 144, self.detailView.frame.size.width, self.detailView.frame.size.height)];
    }];
}

- (void)detail
{
    NSLog(@"details");
}

- (BOOL)isAtStopZoomLevel
{
    float regionsize = [self.map region].span.latitudeDelta;

    NSLog(@"region: %f",regionsize);
    
    if (regionsize <= 0.0032) {
        return YES;
    }
    
    return NO;
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
