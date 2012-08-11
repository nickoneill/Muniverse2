//
//  NextBusClient.h
//  muniverse2
//
//  Created by Nick O'Neill on 8/11/12.
//  Copyright (c) 2012 Nick O'Neill. All rights reserved.
//

#import "AFHTTPClient.h"

@interface NextBusClient : AFHTTPClient

+ (id)sharedClient;

@end
