//
//  SubwayData.m
//  muniverse2
//
//  Created by Nick O'Neill on 7/16/12.
//  Copyright (c) 2012 Nick O'Neill. All rights reserved.
//

#import "SubwayData.h"
#import "AppDelegate.h"

@implementation SubwayData

@synthesize stops,managedobjectcontext;

- (id)init
{
    if (self = [super init]) {
        NSManagedObjectContext *moc = [(AppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
        
        NSFetchRequest *req = [NSFetchRequest fetchRequestWithEntityName:@"Stop"];
        
        NSError *err;
        self.stops = [moc executeFetchRequest:req error:&err];
        if (err != nil) {
            NSLog(@"issue with subway stops: %@",[err localizedDescription]);
        }
    }
    
    return self;
}



- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.stops count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"hey"];
    cell.textLabel.text = [[self.stops objectAtIndex:[indexPath row]] valueForKey:@"name"];
    
    return cell;
}

@end
