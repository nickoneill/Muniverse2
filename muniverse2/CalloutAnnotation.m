//
//  CalloutAnnotation.m
//  muniverse2
//
//  Created by Nick O'Neill on 9/17/12.
//  Copyright (c) 2012 Nick O'Neill. All rights reserved.
//

#import "CalloutAnnotation.h"

@implementation CalloutAnnotation

- (id)initWithLatitude:(CLLocationDegrees)latitude andLongitude:(CLLocationDegrees)longitude
{
	if (self = [super init]) {
        self.coordinate = CLLocationCoordinate2DMake(latitude, longitude);
	}
	return self;
}

@end
