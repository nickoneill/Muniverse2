//
//  NextBusClient.m
//  muniverse2
//
//  Created by Nick O'Neill on 8/11/12.
//  Copyright (c) 2012 Nick O'Neill. All rights reserved.
//

#import "NextBusClient.h"
#import "TouchXML.h"

@implementation NextBusClient

- (id)init{
    if (self = [super initWithBaseURL:[NSURL URLWithString:@"http://webservices.nextbus.com"]]) {
        // ok
    }
    
    return self;
}

- (void)predictionForStopId:(int)stopId inDirection:(int)direction withSuccess:(void(^)(NSArray *els))success andFailure:(void(^)(NSError *err))failure
{
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:@"predictions",@"command",@"sf-muni",@"a",[NSNumber numberWithInt:stopId],@"stopId", nil];
    
    [self getPath:@"/service/publicXMLFeed" parameters:params success:^(AFHTTPRequestOperation *operation, NSData *res){
        NSError *err;
        CXMLDocument *doc = [[CXMLDocument alloc] initWithData:res options:0 error:&err];
        
        if (doc != nil) {
            NSArray *predictionElements = [doc nodesForXPath:@"//body/predictions/direction/prediction" error:&err];
            
            NSMutableArray *predictions = [NSMutableArray array];
            for (int i = 0; i < [predictionElements count]; i++) {
                CXMLElement *element = [predictionElements objectAtIndex:i];
                NSString *minutesString = [[element attributeForName:@"minutes"] stringValue];
                
                NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
                [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
                
                [predictions addObject:[formatter numberFromString:minutesString]];
            }
            
            success(predictions);
        } else {
            failure(err);
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"failed req with %@",error);
    }];
}

- (void)predictionForStopTag:(int)stopTag
{
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:@"predictions",@"command",@"sf-muni",@"a",@"N",@"r",[NSNumber numberWithInt:stopTag],@"s", nil];

    [self getPath:@"/service/publicXMLFeed" parameters:params success:^(AFHTTPRequestOperation *operation, NSData *res){
        
        NSError *err;
        CXMLDocument *doc = [[CXMLDocument alloc] initWithData:res options:0 error:&err];
        if (doc != nil) {
            NSArray *els = [doc nodesForXPath:@"//body/predictions/direction" error:&err];
            
            NSLog(@"els: %@",els);
        } else {
            NSLog(@"Error parsing xml: %@",[err description]);
        }
        
//        NSLog(@"got res: %@",[res class]);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"failed req with %@",error);
    }];
}

@end
