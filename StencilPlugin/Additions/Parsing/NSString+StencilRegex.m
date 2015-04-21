//
//  NSString+StencilRegex.m
//  StencilPlugin
//
//  Created by Sam Dods on 20/04/2015.
//  Copyright (c) 2015 Sam Dods. All rights reserved.
//

#import "NSString+StencilRegex.h"

@implementation NSMutableString (StencilRegex)

- (void)matchPattern:(NSString *)pattern replaceWith:(NSString *)template
{
  NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
  [regex replaceMatchesInString:self options:0 range:NSMakeRange(0, self.length) withTemplate:template];
}

@end
