//
//  Stop.h
//  muniverse2
//
//  Created by Nick O'Neill on 7/16/12.
//  Copyright (c) 2012 Nick O'Neill. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Stop : NSManagedObject

@property (nonatomic, retain) NSNumber * id;
@property (nonatomic, retain) NSSet *lines;
@end

@interface Stop (CoreDataGeneratedAccessors)

- (void)addLinesObject:(NSManagedObject *)value;
- (void)removeLinesObject:(NSManagedObject *)value;
- (void)addLines:(NSSet *)values;
- (void)removeLines:(NSSet *)values;

@end
