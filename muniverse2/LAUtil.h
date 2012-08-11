//
//  LAUtil.h
//  Launch Apps Utilities Package
//
//  Created by Nick O'Neill on 5/8/12.
//  Copyright (c) 2012 Launch Apps. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LAUtil : NSObject

// returns a deeply copied mutable version of dictionaries or arrays
+ (id)recursiveMutable:(id)object;
// returns documents path
+ (NSString *)docsPath;
@end
