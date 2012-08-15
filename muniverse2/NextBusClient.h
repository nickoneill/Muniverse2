//
//  NextBusClient.h
//  muniverse2
//
//  Created by Nick O'Neill on 8/11/12.
//  Copyright (c) 2012 Nick O'Neill. All rights reserved.
//

#import "AFHTTPClient.h"

@interface NextBusClient : AFHTTPClient

typedef enum {
    kDirectionInbound,
    kDirectionOutbound
} DirectionTypes;

- (void)predictionForStopId:(int)stopId inDirection:(int)direction withSuccess:(void(^)(NSArray *els))success andFailure:(void(^)(NSError *err))failure;
- (void)predictionForStopTag:(int)stopTag;

@end
