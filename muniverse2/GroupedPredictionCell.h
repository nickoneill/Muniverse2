//
//  GroupedPredictionCell.h
//  muniverse2
//
//  Created by Nick O'Neill on 8/19/12.
//  Copyright (c) 2012 Nick O'Neill. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GroupedPredictionCell : UITableViewCell

@property (strong) IBOutlet UIImageView *lineIcon; // optional
@property (strong) IBOutlet UILabel *primaryText;
@property (strong) IBOutlet UILabel *secondaryText;
@property (strong) IBOutlet UILabel *primaryPrediction;
@property (strong) IBOutlet UILabel *secondaryPrediction;

@end
