//
//  CluserAnnotationView.m
//  muniverse2
//
//  Created by Nick O'Neill on 11/7/12.
//  Copyright (c) 2012 Nick O'Neill. All rights reserved.
//

#import "CluserAnnotationView.h"

@implementation CluserAnnotationView

- (id)initWithAnnotation:(id <MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier {

	if (self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier]) {
        self.image = [UIImage imageNamed:@"StopCluster.png"];
        
        // maybe we'll add the count back in at some point in the future
	}
	return self;
}

@end
