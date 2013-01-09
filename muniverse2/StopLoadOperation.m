//
//  StopLoadOperation.m
//  muniverse2
//
//  Created by Nick O'Neill on 11/29/12.
//  Copyright (c) 2012 Nick O'Neill. All rights reserved.
//

#import "StopLoadOperation.h"
#import "NearbyMapViewController.h"
#import "MuniPinAnnotation.h"
#import "SmallClusterAnnotation.h"
#import "ClusterAnnotation.h"

@implementation StopLoadOperation

// as you can imagine, this started as entirely contained within the map controller before I broke out the loading bit to this async operation subclass.
// there are a million references to the map controller here, many of which could be shifted to this class

- (id)initWithNearby:(NearbyMapViewController *)parent
{
    self = [super init];
    if (self) {
        self.nearby = parent;
    }
    
    return self;
}

- (void)main
{
    self.nearby.loadedAnnotations = [NSMutableArray array];
        
    if (self.nearby.map.region.span.latitudeDelta <= 0.005) {
        // display all stops if we're real close
        
        if (self.nearby.lastDisplayCluster) {
            // remove cluster annotations if that was the last thing we annotated
            // this is used to persist the stop annotations between drags, it could potentially slow down if someone dragged a lot but small use case, I think
            [self.nearby clearCustomAnnoations];
            self.nearby.lastDisplayCluster = NO;
        }
        
        // pick stops from the cache for the current region
        for (Stop *stop in self.nearby.loadedStops) {
            if (self.isCancelled) { // we can cancel this action if we're already moving the map again
                return;
            }
            MKMapPoint point = MKMapPointForCoordinate(CLLocationCoordinate2DMake([stop.lat floatValue], [stop.lon floatValue]));
            
            if (MKMapRectContainsPoint(self.nearby.map.visibleMapRect, point)) {
                MuniPinAnnotation *point = [[MuniPinAnnotation alloc] init];
                [point setStop:stop];
                [point setCoordinate:CLLocationCoordinate2DMake([stop.lat floatValue], [stop.lon floatValue])];
                
                [self.nearby.loadedAnnotations addObject:point];
            }
        }
    } else if (self.nearby.map.region.span.latitudeDelta <= 0.02) {
        // display stops with some clusters if we're somewhat close
        
        [self.nearby clearCustomAnnoations];
        
        // pick stops from the cache for the current region
        NSMutableArray *visibleStops = [NSMutableArray array];
        for (Stop *stop in self.nearby.loadedStops) {
            MKMapPoint point = MKMapPointForCoordinate(CLLocationCoordinate2DMake([stop.lat floatValue], [stop.lon floatValue]));
            
            if (MKMapRectContainsPoint(self.nearby.map.visibleMapRect, point)) {
                [visibleStops addObject:stop];
            }
        }
        
        // stop clusters stores the current clusters as they're built
        // ignore stops is the stops we've used, we want to treat them as clusters (but can't mutate the array we're enumerating
        NSMutableArray *stopClusters = [NSMutableArray array];
        NSMutableArray *ignoreStops = [NSMutableArray array];
        for (Stop *stop in visibleStops) {
            if (self.isCancelled) { // we can cancel this action if we're already moving the map again
                return;
            }
            
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
                    
                    // the center of the cluster matching region changes with an additional stop, but less impact with each additional stop added
                    CLLocation *avgLoc = [[CLLocation alloc] initWithLatitude:avgLat/clusterCount longitude:avgLon/clusterCount];
                    
                    if ([self.nearby checkRoughDistanceOf:stopLoc from:avgLoc]) {
                        if ([stopLoc distanceFromLocation:avgLoc] <= SMALL_CLUSTER_DISTANCE) {
                            [ignoreStops addObject:stop];
                            cluster = [cluster arrayByAddingObject:stop];
                            addedToCluster = YES;
                        }
                    }
                }
                
                // if we're not added to a cluster, we check if we're close to any other stops for forming new clusters
                if (!addedToCluster) {
                    for (Stop *otherStop in visibleStops) {
                        if (![ignoreStops containsObject:otherStop] && ![ignoreStops containsObject:stop]) {
                            CLLocation *otherStopLoc = [[CLLocation alloc] initWithLatitude:[otherStop.lat floatValue] longitude:[otherStop.lon floatValue]];
                            
                            if ([self.nearby checkRoughDistanceOf:stopLoc from:otherStopLoc]) {
                                if ([stopLoc distanceFromLocation:otherStopLoc] <= SMALL_CLUSTER_DISTANCE && [stopLoc distanceFromLocation:otherStopLoc] != 0.0) {
                                    [ignoreStops addObjectsFromArray:@[stop,otherStop]];
                                    [stopClusters addObject:@[stop, otherStop]];
                                }
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
                
                [self.nearby.loadedAnnotations addObject:point];
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
            
            [self.nearby.loadedAnnotations addObject:clusterNote];
        }
        
        self.nearby.lastDisplayCluster = YES;
    } else if (self.nearby.map.region.span.latitudeDelta <= 0.16) {
        // VERY crude implementation of clustering for zoomed out views
        // much faster than the more detailed model, but with significantly less accuracy
        [self.nearby clearCustomAnnoations];
        
        int divisions = 4;
        
        // our primary optimization here weeds out stops that we've already used
        // we make a copy of all the stops for this purpose
        NSMutableArray *stopBackup = [self.nearby.loadedStops mutableCopy];
        
        // at smaller distances, it makes sense to weed out all stops that aren't in the map area first
        if (self.nearby.map.region.span.latitudeDelta <= 0.06) {
            NSMutableArray *earlierRemoval = [NSMutableArray array];
            for (Stop *stop in stopBackup) {
                MKMapPoint point = MKMapPointForCoordinate(CLLocationCoordinate2DMake([stop.lat floatValue], [stop.lon floatValue]));
                
                if (!MKMapRectContainsPoint(self.nearby.map.visibleMapRect, point)) {
                    [earlierRemoval addObject:stop];
                }
            }
            [stopBackup removeObjectsInArray:earlierRemoval];
        }
        
        MKMapRect visRect = self.nearby.map.visibleMapRect;
        float subWidth = visRect.size.width/divisions;
        float subHeight = visRect.size.height/divisions;
        // divide the current region into smaller squares (tune more/less by changing the divisions)
        // this isn't great since we traverse many of the stops divisions^2 times, but the optimizations make it bearable
        for (int i = 0; i < divisions; i++) {
            for (int j = 0; j < divisions; j++) {
                if (self.isCancelled) { // we can cancel this action if we're already moving the map again
                    return;
                }
                NSMutableArray *forRemoval = [NSMutableArray array];
                
                MKMapRect submap = MKMapRectMake(visRect.origin.x+(subWidth*i), visRect.origin.y+(subHeight*j), subWidth, subHeight);
                
                int stopCount = 0;
                CLLocationCoordinate2D avg = CLLocationCoordinate2DMake(0, 0);
                // then sum up stops in that region, and weighted-average the stop coordinates (for simplicity)
                for (Stop *stop in stopBackup) {
                    MKMapPoint point = MKMapPointForCoordinate(CLLocationCoordinate2DMake([stop.lat floatValue], [stop.lon floatValue]));
                    
                    if (MKMapRectContainsPoint(submap, point)) {
                        if (avg.latitude == 0) {
                            avg = CLLocationCoordinate2DMake([stop.lat floatValue], [stop.lon floatValue]);
                        } else {
                            avg = CLLocationCoordinate2DMake((avg.latitude + [stop.lat floatValue])/2, (avg.longitude + [stop.lon floatValue])/2);
                        }
                        
                        [forRemoval addObject:stop];
                        stopCount++;
                    }
                }
                
                // we gather and remove stops that have already been used, reducing our overall iteration count
                [stopBackup removeObjectsInArray:forRemoval];
                
                ClusterAnnotation *point = [[ClusterAnnotation alloc] init];
                [point setCoordinate:avg];
                
                [self.nearby.loadedAnnotations addObject:point];
            }
        }
        
        self.nearby.lastDisplayCluster = YES;
    } else {
        [self.nearby clearCustomAnnoations];
    }

    // our last check for a cancelled message before we clear the existing annotations and add the new ones
    if (self.isCancelled) {
        return;
    }
        
    // do the ui stuff on the ui thread
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self.nearby clearCustomAnnoations];
        [self.nearby.map addAnnotations:self.nearby.loadedAnnotations];
    });

    if (self.isCancelled) {
        return;
    }

    if ([self.nearby isAtStopZoomLevel]) {
        CLLocationDistance minDist = 1000;
        MuniPinAnnotation *closestPin = nil;
        
        CLLocationCoordinate2D coord = self.nearby.map.centerCoordinate;
        CLLocation *center = [[CLLocation alloc] initWithLatitude:coord.latitude longitude:coord.longitude];

        for (MuniPinAnnotation *pin in self.nearby.loadedAnnotations) {
            CLLocation *pinloc = [[CLLocation alloc] initWithLatitude:pin.coordinate.latitude longitude:pin.coordinate.longitude];
            
            CLLocationDistance meterdist = [center distanceFromLocation:pinloc];
            if (meterdist < minDist) {
                minDist = meterdist;
                closestPin = pin;
            }
        }
        
        if (closestPin) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self.nearby loadDetailForPin:closestPin];
            });
        }
    }
}

@end
