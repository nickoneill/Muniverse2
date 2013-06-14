//
//  NewLineDetailViewController.h
//  muniverse2
//
//  Created by Nick O'Neill on 6/14/13.
//  Copyright (c) 2013 Nick O'Neill. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Line;

@interface NewLineDetailViewController : UIViewController <UITableViewDataSource,UITableViewDelegate>

@property (strong) Line *line;

@end
