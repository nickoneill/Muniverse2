//
//  CalloutAnnotationView.h
//  muniverse2
//
//  Created by Nick O'Neill on 10/4/12.
//
//  based on the fantastic work from asyncrony solutions
//  http://blog.asolutions.com/2010/09/building-custom-map-annotation-callouts-part-1/

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface CalloutAnnotationView : MKAnnotationView

@property (strong) MKAnnotationView *parentAnnotationView;
@property (strong) MKMapView *mapView;
@property CGPoint offsetFromParent;
@property (strong) UIView *contentView;

@property CGRect endFrame;
@property CGFloat yShadowOffset;
@property BOOL animateOnNextDrawRect;

@end
