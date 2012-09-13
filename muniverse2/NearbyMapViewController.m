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
    
    self.loadedStops = [NSMutableArray array];
    self.shouldZoomToUser = YES;
    
    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(37.766644, -122.414474);
	
    [self.map setCenterCoordinate:coord zoomLevel:11 animated:NO];
}

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated
{
    NSLog(@"region change");
    // don't zoom to user if the region has been changed alredy
    self.shouldZoomToUser = NO;
    
    [self loadAndDisplayStopsAroundCoordinate:[mapView region].center];
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
    float adjustment = 0.004;
    
    NSFetchRequest *fetch = [NSFetchRequest fetchRequestWithEntityName:@"Stop"];
    
    NSPredicate *nearbyPredicate = [NSPredicate predicateWithFormat:@"%K > %f && %K < %f && %K > %f && %K < %f",@"lat",coord.latitude-adjustment,@"lat",coord.latitude+adjustment,@"lon",coord.longitude-adjustment,@"lon",coord.longitude+adjustment];
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
            
            MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
            point.coordinate = CLLocationCoordinate2DMake([stop.lat floatValue], [stop.lon floatValue]);
            [self.map addAnnotation:point];
        }
    }
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
