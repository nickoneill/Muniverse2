//
//  LineDisplayCell.h
//  muniverse2
//
//  Created by Nick O'Neill on 8/3/12.
//  Copyright (c) 2012 Nick O'Neill. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LineDisplayCell : UITableViewCell

@property (nonatomic,strong) IBOutlet UILabel *name;
@property (nonatomic,strong) IBOutlet UILabel *description;
@property (nonatomic,strong) IBOutlet UIImageView *icon;

@end
