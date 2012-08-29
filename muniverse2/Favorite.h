//
//  Favorite.h
//  muniverse2
//
//  Created by Nick O'Neill on 8/29/12.
//  Copyright (c) 2012 Nick O'Neill. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Line, Stop;

@interface Favorite : NSManagedObject

@property (nonatomic, retain) NSNumber * isInbound;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * order;
@property (nonatomic, retain) Line *line;
@property (nonatomic, retain) Stop *stop;

@end
