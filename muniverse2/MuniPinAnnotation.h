//
//  MuniPinAnnotation.h
//  muniverse2
//
//  Created by Nick O'Neill on 10/15/12.
//  Copyright (c) 2012 Nick O'Neill. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface MuniPinAnnotation : NSObject <MKAnnotation>

@property CLLocationCoordinate2D coordinate;
@property (strong) NSString *title;
@property (strong) NSString *subtitle;

@end
