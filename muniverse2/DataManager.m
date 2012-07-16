//
//  DataManager.m
//  muniverse2
//
//  Created by Nick O'Neill on 7/16/12.
//  Copyright (c) 2012 Nick O'Neill. All rights reserved.
//

#import "DataManager.h"

@implementation DataManager

+ (DataManager *)shared
{
    static DataManager *shared;
    
    @synchronized(self)
    {
        if (!shared) {
            shared = [[DataManager alloc] init];
        }
        
        return shared;
    }
}

- (void)demoSetup
{
    
}

@end
