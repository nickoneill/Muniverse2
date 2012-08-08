//
//  Line.h
//  muniverse2
//
//  Created by Nick O'Neill on 8/5/12.
//  Copyright (c) 2012 Nick O'Neill. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Stop;

@interface Line : NSManagedObject

@property (nonatomic, retain) NSNumber * historic;
@property (nonatomic, retain) NSNumber * metro;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * shortname;
@property (nonatomic, retain) NSString * inboundDesc;
@property (nonatomic, retain) NSString * outboundDesc;
@property (nonatomic, retain) NSSet *inboundStops;
@property (nonatomic, retain) NSSet *outboundStops;
@end

@interface Line (CoreDataGeneratedAccessors)

- (void)addInboundStopsObject:(Stop *)value;
- (void)removeInboundStopsObject:(Stop *)value;
- (void)addInboundStops:(NSSet *)values;
- (void)removeInboundStops:(NSSet *)values;

- (void)addOutboundStopsObject:(Stop *)value;
- (void)removeOutboundStopsObject:(Stop *)value;
- (void)addOutboundStops:(NSSet *)values;
- (void)removeOutboundStops:(NSSet *)values;

@end