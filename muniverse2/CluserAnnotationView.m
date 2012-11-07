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
        
        self.image = [UIImage imageNamed:@"cluster.png"];
        self.clusterCount = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 26, 26)];
        self.clusterCount.text = @"C";
        self.clusterCount.textColor = [UIColor whiteColor];
        self.clusterCount.backgroundColor = [UIColor clearColor];
       
        self.clusterCount.font = [UIFont boldSystemFontOfSize:12];
        self.clusterCount.textAlignment = UITextAlignmentCenter;
        
        self.clusterCount.shadowColor = [UIColor blackColor];
        self.clusterCount.shadowOffset = CGSizeMake(0,-1);

        [self addSubview:self.clusterCount];
	}
	return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
