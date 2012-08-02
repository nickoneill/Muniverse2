//
//  Line.h
//  muniverse2
//
//  Created by Nick O'Neill on 7/22/12.
//  Copyright (c) 2012 Nick O'Neill. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Stop;

@interface Line : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *inboundStops;
@end

@interface Line (CoreDataGeneratedAccessors)

- (void)addInboundStopsObject:(Stop *)value;
- (void)removeInboundStopsObject:(Stop *)value;
- (void)addInboundStops:(NSSet *)values;
- (void)removeInboundStops:(NSSet *)values;

@end
