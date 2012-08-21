//
//  FavoriteCell.h
//  muniverse2
//
//  Created by Nick O'Neill on 8/21/12.
//  Copyright (c) 2012 Nick O'Neill. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FavoriteCell : UITableViewCell

@property (strong) IBOutlet UILabel *stopName;
@property (strong) IBOutlet UILabel *lineName;
@property (strong) IBOutlet UILabel *destination;
@property (strong) IBOutlet UILabel *primaryPrediction;
@property (strong) IBOutlet UILabel *secondaryPrediction;

@end
