//
//  Subway.h
//  muniverse2
//
//  Created by Nick O'Neill on 8/18/12.
//  Copyright (c) 2012 Nick O'Neill. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Stop;

@interface Subway : NSManagedObject

@property (nonatomic, retain) NSNumber * isAboveGround;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * order;
@property (nonatomic, retain) Stop *inboundStop;
@property (nonatomic, retain) Stop *outboundStop;

@end
