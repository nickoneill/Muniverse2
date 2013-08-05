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

// request a set of predictions from a single stop id
- (void)predictionForLineTag:(NSString *)lineTag atStopId:(int)stopId withSuccess:(void(^)(NSArray *els))success andFailure:(void(^)(NSError *err))failure
{
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:@"predictions",@"command",@"sf-muni",@"a",[NSNumber numberWithInt:stopId],@"stopId", nil];
    
    [self getPath:@"/service/publicXMLFeed" parameters:params success:^(AFHTTPRequestOperation *operation, NSData *res){
        NSError *err;
        CXMLDocument *doc = [[CXMLDocument alloc] initWithData:res options:0 error:&err];
        
        if (doc != nil) {
            NSArray *predictionElements = [doc nodesForXPath:[NSString stringWithFormat:@"//body/predictions/direction/prediction[@dirTag='%@']",lineTag] error:&err];
            
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

// I don't think this really goes here... maybe a whole muniverse utilities class?
+ (NSString *)truncatedDescription:(NSString *)desc
{
    // remove the "Inbound" and "Outbound" parts of the description on some pages when we already indicate direction
    NSError *err;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@".+ to (.+)" options:NSRegularExpressionCaseInsensitive error:&err];
    if (err) {
        NSLog(@"Error with regex: %@",[err localizedDescription]);
    }
    
    return [regex stringByReplacingMatchesInString:desc options:0 range:NSMakeRange(0, [desc length]) withTemplate:@"To $1"];
}

+ (NSString *)nameStripShort:(NSString *)name
{
    // remove the shortname from the beginning part of the line name
    NSError *err;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@".+-(.+)" options:NSRegularExpressionCaseInsensitive error:&err];
    if (err) {
        NSLog(@"Error with regex: %@",[err localizedDescription]);
    }
    
    return [regex stringByReplacingMatchesInString:name options:0 range:NSMakeRange(0, [name length]) withTemplate:@"$1"];
}

+ (NSString *)formattedTimeFromNumer:(NSNumber *)number
{
    if ([number isEqualToNumber:[NSNumber numberWithInt:0]]) {
        return @"Now";
    }
    
    return [NSString stringWithFormat:@"%@",number];
}
+ (NSString *)formattedSubtitleFromNumer:(NSNumber *)number
{
    if ([number isEqualToNumber:[NSNumber numberWithInt:0]]) {
        return @"Arriving";
    }
    
    return [NSString stringWithFormat:@"Minutes"];
}

@end
