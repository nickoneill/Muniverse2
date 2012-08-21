//
//  FavoriteCell.m
//  muniverse2
//
//  Created by Nick O'Neill on 8/21/12.
//  Copyright (c) 2012 Nick O'Neill. All rights reserved.
//

#import "FavoriteCell.h"

@implementation FavoriteCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
