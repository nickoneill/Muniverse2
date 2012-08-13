//
//  StopDetailViewController.m
//  muniverse2
//
//  Created by Nick O'Neill on 8/8/12.
//  Copyright (c) 2012 Nick O'Neill. All rights reserved.
//

#import "StopDetailViewController.h"
#import "NextBusClient.h"
#import "Stop.h"
#import "TouchXML.h"

@interface StopDetailViewController ()

@end

@implementation StopDetailViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NextBusClient *client = [[NextBusClient alloc] init];
    [client predictionForStopId:[self.stop.stopId intValue] withSuccess:^(NSArray *els) {
        
        if ([els count]) {
            CXMLElement *firstDirection = [els objectAtIndex:0];
            
            NSError *err;
            // we should distinguish the prediction based on IB/OB
            CXMLNode *firstPrediction = [firstDirection nodeForXPath:@"prediction[1]" error:&err];
            if ([firstPrediction isKindOfClass:[CXMLElement class]]) {
                CXMLNode *secondsNode = [(CXMLElement *)firstPrediction attributeForName:@"seconds"];
                
                NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
                [formatter setNumberStyle:NSNumberFormatterDecimalStyle];

                int minutes = [[formatter numberFromString:[secondsNode stringValue]] intValue] / 60;
                self.primaryArrival.text = [NSString stringWithFormat:@"%d Minutes",minutes];
            }
            
        }
    } andFailure:^(NSError * err) {
        NSLog(@"some failure: %@",err);
    }];
        
    UIImage *bgimage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Background" ofType:@"png"]];
    [self.view setBackgroundColor:[UIColor colorWithPatternImage:bgimage]];
    
    self.stopName.text = self.stop.name;
    self.stopID.text = [NSString stringWithFormat:@"%@",self.stop.tag];
    
    self.primaryArrival.text = @"Fetching...";
    self.secondaryArrival.text = @"";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
