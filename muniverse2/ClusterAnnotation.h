//
//  ClusterAnnotation.h
//  muniverse2
//
//  Created by Nick O'Neill on 11/7/12.
//  Copyright (c) 2012 Nick O'Neill. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface ClusterAnnotation : NSObject <MKAnnotation>

@property CLLocationCoordinate2D coordinate;
@property NSNumber *clusterCount;

@end
