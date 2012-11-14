//
//  Stop+Favorite.m
//  muniverse2
//
//  Created by Nick O'Neill on 11/14/12.
//  Copyright (c) 2012 Nick O'Neill. All rights reserved.
//

#import "Stop+Favorite.h"
#import "AppDelegate.h"

// we maintain a category for this favorite method so we can regenerate the managed objects without loss of code
@implementation Stop (Favorite)

- (BOOL)isFavorite
{
    AppDelegate *app = [[UIApplication sharedApplication] delegate];
    
    NSFetchRequest *fetch = [NSFetchRequest fetchRequestWithEntityName:@"Favorite"];
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"%@ == %K",self,@"stop"];
    
    [fetch setPredicate:pred];
    
    NSError *err;
    int favorites = [app.managedObjectContext countForFetchRequest:fetch error:&err];
    
    if (favorites > 0) {
        return YES;
    }
    
    return NO;
}

@end