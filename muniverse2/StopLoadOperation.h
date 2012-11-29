//
//  StopLoadOperation.h
//  muniverse2
//
//  Created by Nick O'Neill on 11/29/12.
//  Copyright (c) 2012 Nick O'Neill. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NearbyMapViewController;

@interface StopLoadOperation : NSOperation

@property (weak) NearbyMapViewController *nearby;

- (id)initWithNearby:(NearbyMapViewController *)parent;

@end
