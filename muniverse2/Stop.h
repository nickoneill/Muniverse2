//
//  Stop.h
//  muniverse2
//
//  Created by Nick O'Neill on 8/29/12.
//  Copyright (c) 2012 Nick O'Neill. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Line, Subway;

@interface Stop : NSManagedObject

@property (nonatomic, retain) NSNumber * lat;
@property (nonatomic, retain) NSNumber * lon;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * stopId;
@property (nonatomic, retain) NSNumber * tag;
@property (nonatomic, retain) Subway *ibSubway;
@property (nonatomic, retain) NSSet *inboundLines;
@property (nonatomic, retain) Subway *obSubway;
@property (nonatomic, retain) NSSet *outboundLines;
@end

@interface Stop (CoreDataGeneratedAccessors)

- (void)addInboundLinesObject:(Line *)value;
- (void)removeInboundLinesObject:(Line *)value;
- (void)addInboundLines:(NSSet *)values;
- (void)removeInboundLines:(NSSet *)values;

- (void)addOutboundLinesObject:(Line *)value;
- (void)removeOutboundLinesObject:(Line *)value;
- (void)addOutboundLines:(NSSet *)values;
- (void)removeOutboundLines:(NSSet *)values;

@end
