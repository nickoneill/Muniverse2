//
//  MuniUtilities.m
//  muniverse2
//
//  Created by Nick O'Neill on 11/14/12.
//  Copyright (c) 2012 Nick O'Neill. All rights reserved.
//

#import "MuniUtilities.h"
#import "AppDelegate.h"
#import "Stop.h"
#import "Favorite.h"

@implementation MuniUtilities

+ (int)maxFavoriteOrder
{
    AppDelegate *app = [[UIApplication sharedApplication] delegate];
    
    NSFetchRequest *fetch = [NSFetchRequest fetchRequestWithEntityName:@"Favorite"];
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"order" ascending:NO];
    
    [fetch setSortDescriptors:[NSArray arrayWithObject:sort]];
    
    [fetch setFetchLimit:1];
    
    NSError *err;
    NSArray *maxfav = [app.managedObjectContext executeFetchRequest:fetch error:&err];
    
    int maxorder = 0;
    if ([maxfav count] == 1) {
        maxorder = [[(Favorite *)[maxfav objectAtIndex:0] order] integerValue];
    }
    
    return maxorder;
}

+ (BOOL)isStop:(Stop *)stop inboundForLine:(Line *)line
{
    return YES;
}

@end

