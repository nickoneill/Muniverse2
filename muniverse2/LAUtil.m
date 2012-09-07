//
//  LAUtil.m
//  Launch Apps Utilities Package
//
//  Created by Nick O'Neill on 5/8/12.
//  Copyright (c) 2012 Launch Apps. All rights reserved.
//

#import "LAUtil.h"

@implementation LAUtil

+ (id)recursiveMutable:(id)object
{
	if ([object isKindOfClass:[NSDictionary class]]) {
		NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithDictionary:object];
		for (NSString* key in [dict allKeys]) {
			[dict setObject:[LAUtil recursiveMutable:[dict objectForKey:key]] forKey:key];
		}
		return dict;
	}
	else if ([object isKindOfClass:[NSArray class]]) {
		NSMutableArray* array = [NSMutableArray arrayWithArray:object];
		for (int i=0;i<[array count];i++) {
			[array replaceObjectAtIndex:i withObject:[LAUtil recursiveMutable:[array objectAtIndex:i]]];
		}
		return array;
	}
	else if ([object isKindOfClass:[NSString class]]) {
		return [NSMutableString stringWithString:object];
    }
    
	return object;
}

+ (NSString *)docsPath
{
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
}

+ (void)alignTop:(UILabel *)label
{
    CGSize fontSize = [label.text sizeWithFont:label.font];
    double finalHeight = fontSize.height * label.numberOfLines;
    double finalWidth = label.frame.size.width;
    CGSize theStringSize = [label.text sizeWithFont:label.font constrainedToSize:CGSizeMake(finalWidth, finalHeight) lineBreakMode:label.lineBreakMode];
    int newLinesToPad = (finalHeight  - theStringSize.height) / fontSize.height;
    for(int i=0; i<newLinesToPad; i++)
        label.text = [label.text stringByAppendingString:@"\n "];
}

@end
