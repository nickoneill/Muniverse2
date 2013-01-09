//
//  CurrentStopAnnotation.h
//  muniverse2
//
//  Created by Nick O'Neill on 1/8/13.
//  Copyright (c) 2013 Nick O'Neill. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface CurrentStopAnnotation : NSObject <MKAnnotation>

@property CLLocationCoordinate2D coordinate;

@end
