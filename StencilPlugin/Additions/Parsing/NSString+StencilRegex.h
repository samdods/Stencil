//
//  NSString+StencilRegex.h
//  StencilPlugin
//
//  Created by Sam Dods on 20/04/2015.
//  Copyright (c) 2015 Sam Dods. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (StencilRegex)

- (NSString *)stringByMatching:(NSString *)pattern replaceWith:(NSString *)templ;

@end


@interface NSMutableString (StencilRegex)

- (NSUInteger)matchPattern:(NSString *)pattern replaceWith:(NSString *)templ;

@end
