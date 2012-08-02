//
//  Stop.h
//  muniverse2
//
//  Created by Nick O'Neill on 7/22/12.
//  Copyright (c) 2012 Nick O'Neill. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Line;

@interface Stop : NSManagedObject

@property (nonatomic, retain) NSNumber * inboundId;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * outboundId;
@property (nonatomic, retain) NSNumber * subway;
@property (nonatomic, retain) NSNumber * subwayOrder;
@property (nonatomic, retain) NSSet *lines;
@end

@interface Stop (CoreDataGeneratedAccessors)

- (void)addLinesObject:(Line *)value;
- (void)removeLinesObject:(Line *)value;
- (void)addLines:(NSSet *)values;
- (void)removeLines:(NSSet *)values;

@end
