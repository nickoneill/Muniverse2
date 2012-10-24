//
//  CalloutAnnotation.h
//  muniverse2
//
//  Created by Nick O'Neill on 9/17/12.
//  Copyright (c) 2012 Nick O'Neill. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface CalloutAnnotation : NSObject <MKAnnotation>

@property CLLocationCoordinate2D coordinate;
@property (strong) NSString *title;
@property (strong) NSString *subtitle;

- (id)initWithLatitude:(CLLocationDegrees)latitude andLongitude:(CLLocationDegrees)longitude;

@end
