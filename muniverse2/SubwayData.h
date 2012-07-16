//
//  SubwayData.h
//  muniverse2
//
//  Created by Nick O'Neill on 7/16/12.
//  Copyright (c) 2012 Nick O'Neill. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SubwayData : NSObject <NSFetchedResultsControllerDelegate,UITableViewDataSource,UITableViewDelegate>

@property (nonatomic) NSArray *stops;
@property (nonatomic) NSManagedObjectContext *managedobjectcontext;

@end
