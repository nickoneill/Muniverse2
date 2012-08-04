//
//  Stop.h
//  muniverse2
//
//  Created by Nick O'Neill on 8/3/12.
//  Copyright (c) 2012 Nick O'Neill. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Line;

@interface Stop : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * isSubway;
@property (nonatomic, retain) NSNumber * subwayOrder;
@property (nonatomic, retain) NSNumber * tag;
@property (nonatomic, retain) NSSet *lines;
@end

@interface Stop (CoreDataGeneratedAccessors)

- (void)addLinesObject:(Line *)value;
- (void)removeLinesObject:(Line *)value;
- (void)addLines:(NSSet *)values;
- (void)removeLines:(NSSet *)values;

@end
