//
//  Stop.h
//  muniverse2
//
//  Created by Nick O'Neill on 8/18/12.
//  Copyright (c) 2012 Nick O'Neill. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Line, Subway;

@interface Stop : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * stopId;
@property (nonatomic, retain) NSNumber * tag;
@property (nonatomic, retain) NSNumber * lat;
@property (nonatomic, retain) NSNumber * lon;
@property (nonatomic, retain) NSSet *lines;
@property (nonatomic, retain) Subway *ibSubway;
@property (nonatomic, retain) Subway *obSubway;
@end

@interface Stop (CoreDataGeneratedAccessors)

- (void)addLinesObject:(Line *)value;
- (void)removeLinesObject:(Line *)value;
- (void)addLines:(NSSet *)values;
- (void)removeLines:(NSSet *)values;

@end
