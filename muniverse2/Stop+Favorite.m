//
//  Stop+Favorite.m
//  muniverse2
//
//  Created by Nick O'Neill on 11/14/12.
//  Copyright (c) 2012 Nick O'Neill. All rights reserved.
//

#import "Stop+Favorite.h"

// we maintain a category for this favorite method so we can regenerate the managed objects without loss of code
@implementation Stop (Favorite)

- (BOOL)isFavorite
{
    return YES;
}

@end